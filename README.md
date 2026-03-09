# sql-database-elastic-query-archive-data

## Infrastructure (Bicep)

This repository includes Bicep templates in infra/ to deploy:

- 1 Azure SQL logical server
- 2 Azure SQL databases on that server

### Files

- infra/main.bicep
- infra/main.parameters.json
- infra/deploy.sh

### Deploy with export variables and script

1. Export required variables in your terminal:

```bash
export RESOURCE_GROUP="<your-resource-group>"
export SQL_SERVER_NAME="sqlsrv-demo-001"
export SQL_ADMIN_LOGIN="sqladminuser"
export SQL_ADMIN_PASSWORD="<strong-password>"
```

2. Optional variables (defaults shown):

```bash
export DATABASE_ONE_NAME="appdb-primary"
export DATABASE_TWO_NAME="appdb-archive"
export DATABASE_SKU_NAME="S0"
# Optional: override location (otherwise resource group location is used)
export LOCATION="uksouth"
```

3. Run the script:

```bash
./infra/deploy.sh
```

### Notes

- The template uses resourceGroup().location by default.
- If LOCATION is exported, the deployment uses that value.