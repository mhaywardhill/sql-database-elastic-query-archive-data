#!/usr/bin/env bash
set -euo pipefail

# Required variables
: "${RESOURCE_GROUP:?Set RESOURCE_GROUP}"
: "${SQL_SERVER_NAME:?Set SQL_SERVER_NAME}"
: "${ENTRA_ADMIN_OBJECT_ID:?Set ENTRA_ADMIN_OBJECT_ID}"

# Optional override. If not set, script resolves from ENTRA_ADMIN_OBJECT_ID.
ENTRA_ADMIN_LOGIN="${ENTRA_ADMIN_LOGIN:-}"
ENTRA_TENANT_ID="${ENTRA_TENANT_ID:-}"

# Optional variables with defaults
DATABASE_ONE_NAME="${DATABASE_ONE_NAME:-appdb-primary}"
DATABASE_TWO_NAME="${DATABASE_TWO_NAME:-appdb-archive}"
DATABASE_SKU_NAME="${DATABASE_SKU_NAME:-S0}"
LOCATION="${LOCATION:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"

DEPLOY_LOCATION="$LOCATION"
if [[ -z "$DEPLOY_LOCATION" ]]; then
  DEPLOY_LOCATION="$(az group show --name "$RESOURCE_GROUP" --query location -o tsv 2>/dev/null || true)"
fi
if [[ -z "$DEPLOY_LOCATION" ]]; then
  DEPLOY_LOCATION="uksouth"
fi

if ! az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "Resource group '$RESOURCE_GROUP' not found. Creating in '$DEPLOY_LOCATION'..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$DEPLOY_LOCATION" \
    --output none
fi

CURRENT_TENANT_ID="$(az account show --query tenantId -o tsv)"
TARGET_TENANT_ID="$CURRENT_TENANT_ID"
if [[ -n "$ENTRA_TENANT_ID" ]]; then
  TARGET_TENANT_ID="$ENTRA_TENANT_ID"
fi

detect_principal_type() {
  local object_id="$1"
  if az ad user show --id "$object_id" --query id -o tsv >/dev/null 2>&1; then
    echo "User"
    return 0
  fi
  if az ad group show --group "$object_id" --query id -o tsv >/dev/null 2>&1; then
    echo "Group"
    return 0
  fi
  if az ad sp show --id "$object_id" --query id -o tsv >/dev/null 2>&1; then
    echo "Application"
    return 0
  fi
  echo ""
}

build_login_candidates() {
  local object_id="$1"
  local principal_type="$2"
  local login_override="$3"
  local candidates=()

  add_candidate() {
    local value="$1"
    if [[ -z "$value" || "$value" == "None" ]]; then
      return 0
    fi
    local item
    for item in "${candidates[@]:-}"; do
      if [[ "$item" == "$value" ]]; then
        return 0
      fi
    done
    candidates+=("$value")
  }

  if [[ -n "$login_override" ]]; then
    add_candidate "$login_override"
  fi

  if [[ "$principal_type" == "User" ]]; then
    add_candidate "$(az account show --query user.name -o tsv 2>/dev/null || true)"
    add_candidate "$(az ad signed-in-user show --query displayName -o tsv 2>/dev/null || true)"
    add_candidate "$(az ad user show --id "$object_id" --query displayName -o tsv 2>/dev/null || true)"
    add_candidate "$(az ad user show --id "$object_id" --query userPrincipalName -o tsv 2>/dev/null || true)"
  elif [[ "$principal_type" == "Group" ]]; then
    add_candidate "$(az ad group show --group "$object_id" --query displayName -o tsv 2>/dev/null || true)"
  elif [[ "$principal_type" == "Application" ]]; then
    add_candidate "$(az ad sp show --id "$object_id" --query appDisplayName -o tsv 2>/dev/null || true)"
  fi

  printf '%s\n' "${candidates[@]}"
}

PRINCIPAL_TYPE="$(detect_principal_type "$ENTRA_ADMIN_OBJECT_ID")"
if [[ -z "$PRINCIPAL_TYPE" ]]; then
  echo "Could not resolve ENTRA_ADMIN_OBJECT_ID in current tenant: $ENTRA_ADMIN_OBJECT_ID"
  exit 1
fi

mapfile -t LOGIN_CANDIDATES < <(build_login_candidates "$ENTRA_ADMIN_OBJECT_ID" "$PRINCIPAL_TYPE" "$ENTRA_ADMIN_LOGIN")
if [[ ${#LOGIN_CANDIDATES[@]} -eq 0 ]]; then
  echo "No valid Entra admin login candidates found. Set ENTRA_ADMIN_LOGIN explicitly."
  exit 1
fi

create_server_if_missing() {
  if az sql server show --resource-group "$RESOURCE_GROUP" --name "$SQL_SERVER_NAME" --output none 2>/dev/null; then
    echo "SQL server '$SQL_SERVER_NAME' already exists. Skipping server creation."
    return 0
  fi

  local candidate
  local last_error=""
  for candidate in "${LOGIN_CANDIDATES[@]}"; do
    echo "Trying server create with Entra admin login: $candidate"
    set +e
    output="$(az sql server create \
      --resource-group "$RESOURCE_GROUP" \
      --name "$SQL_SERVER_NAME" \
      --location "$DEPLOY_LOCATION" \
      --assign-identity \
      --identity-type SystemAssigned \
      --minimal-tls-version 1.2 \
      --enable-ad-only-auth \
      --external-admin-name "$candidate" \
      --external-admin-sid "$ENTRA_ADMIN_OBJECT_ID" \
      --external-admin-principal-type "$PRINCIPAL_TYPE" 2>&1)"
    code=$?
    set -e

    if [[ $code -eq 0 ]]; then
      echo "$output"
      return 0
    fi

    last_error="$output"
    if grep -q "Invalid value given for parameter Login" <<<"$output"; then
      echo "Candidate rejected by Azure SQL Login validation: $candidate"
      continue
    fi

    echo "$output"
    return $code
  done

  echo "All Entra admin login candidates failed for SQL server creation."
  echo "$last_error"
  return 1
}

create_server_if_missing

PARAMS=(
  "sqlServerName=$SQL_SERVER_NAME"
  "databaseOneName=$DATABASE_ONE_NAME"
  "databaseTwoName=$DATABASE_TWO_NAME"
  "databaseSkuName=$DATABASE_SKU_NAME"
)
if [[ -n "$LOCATION" ]]; then
  PARAMS+=("location=$LOCATION")
fi

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "${PARAMS[@]}"

echo "Deployment completed."
