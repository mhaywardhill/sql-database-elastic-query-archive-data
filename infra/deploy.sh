#!/usr/bin/env bash
set -euo pipefail

# Required variables
: "${RESOURCE_GROUP:?Set RESOURCE_GROUP}"
: "${SQL_SERVER_NAME:?Set SQL_SERVER_NAME}"
: "${SQL_ADMIN_LOGIN:?Set SQL_ADMIN_LOGIN}"
: "${SQL_ADMIN_PASSWORD:?Set SQL_ADMIN_PASSWORD}"

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

# Ensure SQL authentication mode remains enabled for existing servers.
az sql server ad-only-auth disable \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SQL_SERVER_NAME" \
  --output none >/dev/null 2>&1 || true

PARAMS=(
  "sqlServerName=$SQL_SERVER_NAME"
  "sqlAdminLogin=$SQL_ADMIN_LOGIN"
  "sqlAdminPassword=$SQL_ADMIN_PASSWORD"
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
