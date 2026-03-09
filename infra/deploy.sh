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
RESOURCE_GROUP_LOCATION="${RESOURCE_GROUP_LOCATION:-uksouth}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"

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

if ! az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
  RG_LOCATION="$RESOURCE_GROUP_LOCATION"
  if [[ -n "$LOCATION" ]]; then
    RG_LOCATION="$LOCATION"
  fi

  echo "Resource group '$RESOURCE_GROUP' not found. Creating in '$RG_LOCATION'..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$RG_LOCATION" \
    --output none
fi

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "${PARAMS[@]}"

echo "Deployment completed."
