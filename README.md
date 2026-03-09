# sql-database-elastic-query-archive-data

## Codespaces Azure CLI Setup

This repo includes automatic Azure CLI setup for Codespaces.

- Startup script: `.devcontainer/post-start.sh`
- Dev container config: `.devcontainer/devcontainer.json`

### Current codespace (run now)

```bash
bash .devcontainer/post-start.sh
az version --query '"azure-cli"' -o tsv
```

### Automatic on future starts

1. Rebuild the Codespace once so the new devcontainer config is applied.
2. On each start, postStartCommand runs `.devcontainer/post-start.sh` automatically.

### Optional automatic Azure login

If these env vars are present, startup will run service principal login automatically:

```bash
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_TENANT_ID
```

If they are not set, startup skips login and you can still sign in manually:

```bash
az login --tenant <tenant-id> --use-device-code
```

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

## Elastic Query Scripts

Scripts are provided to archive data from appdb-primary to appdb-archive using external tables.

### Files

- sql/elastic-query/01-archive-setup.sql
- sql/elastic-query/02-primary-external-table-setup.sql
- sql/elastic-query/03-primary-archive-insert.sql

### Run order

1. Run sql/elastic-query/01-archive-setup.sql on appdb-archive.
2. Edit placeholders in sql/elastic-query/02-primary-external-table-setup.sql.
3. Run sql/elastic-query/02-primary-external-table-setup.sql on appdb-primary.
4. Run sql/elastic-query/03-primary-archive-insert.sql on appdb-primary.

### Placeholder values to update

- 01-archive-setup.sql: <REPLACE_WITH_STRONG_PASSWORD>
- 02-primary-external-table-setup.sql: <REPLACE_WITH_MASTER_KEY_PASSWORD>
- 02-primary-external-table-setup.sql: <REPLACE_WITH_ARCHIVE_WRITER_PASSWORD>
- 02-primary-external-table-setup.sql: <your-sql-server-name>.database.windows.net