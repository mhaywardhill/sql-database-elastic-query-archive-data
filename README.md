# SQL Database Elastic Query Archive Data

Reference implementation for deploying Azure SQL resources and configuring Elastic Query to archive data from a primary database into an archive database.

## Overview

This repository provides:

- Infrastructure as Code using Bicep
- Automated deployment via shell script and environment variables
- SQL scripts to configure external tables and move data from primary to archive
- Codespaces startup automation for Azure CLI availability

## Repository Structure

- infra/main.bicep: Deploys one SQL logical server and two SQL databases
- infra/main.parameters.json: Example deployment parameters
- infra/deploy.sh: Deployment helper script (creates resource group if missing)
- sql/elastic-query/01-archive-setup.sql: Creates archive table and user in appdb-archive
- sql/elastic-query/02-primary-external-table-setup.sql: Creates external objects in appdb-primary
- sql/elastic-query/03-primary-archive-insert.sql: Inserts archive data through external table
- .devcontainer/devcontainer.json: Codespaces post-start configuration
- .devcontainer/post-start.sh: Ensures Azure CLI is installed at startup

## Prerequisites

- Azure subscription with permissions to create resource groups and SQL resources
- Azure CLI
- SQL access to both databases with sufficient permissions to create users, credentials, and external objects

## Codespaces Setup

Codespaces startup automation is configured to run .devcontainer/post-start.sh.

### Verify in current session

```bash
bash .devcontainer/post-start.sh
az version --query '"azure-cli"' -o tsv
```

### Optional automatic Azure login

If these environment variables are set, the post-start script attempts service principal login:

```bash
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_TENANT_ID
```

If not set, sign in manually:

```bash
az login --tenant <tenant-id> --use-device-code
```

## Infrastructure Deployment

Export required variables:

```bash
export RESOURCE_GROUP="<your-resource-group>"
export SQL_SERVER_NAME="sqlsrv-demo-001"
export SQL_ADMIN_LOGIN="sqladminuser"
export SQL_ADMIN_PASSWORD="<strong-password>"
```

Optional variables:

```bash
export DATABASE_ONE_NAME="appdb-primary"
export DATABASE_TWO_NAME="appdb-archive"
export DATABASE_SKU_NAME="S0"
export LOCATION="uksouth"
export RESOURCE_GROUP_LOCATION="uksouth"
```

Deploy:

```bash
./infra/deploy.sh
```

Notes:

- If the resource group does not exist, infra/deploy.sh creates it.
- LOCATION controls deployment location passed to Bicep.
- RESOURCE_GROUP_LOCATION is used when creating a missing resource group.

## Elastic Query Configuration and Archiving

Run the scripts in this order:

1. Execute sql/elastic-query/01-archive-setup.sql on appdb-archive.
2. Update placeholders in sql/elastic-query/02-primary-external-table-setup.sql.
3. Execute sql/elastic-query/02-primary-external-table-setup.sql on appdb-primary.
4. Execute sql/elastic-query/03-primary-archive-insert.sql on appdb-primary.

Placeholders you must replace:

- In 01-archive-setup.sql: <REPLACE_WITH_STRONG_PASSWORD>
- In 02-primary-external-table-setup.sql: <REPLACE_WITH_MASTER_KEY_PASSWORD>
- In 02-primary-external-table-setup.sql: <REPLACE_WITH_ARCHIVE_WRITER_PASSWORD>
- In 02-primary-external-table-setup.sql: <your-sql-server-name>.database.windows.net

## Security Guidance

- Do not commit production secrets to source control.
- Use secure password generation and rotation practices.
- Prefer managed identities and secret stores where possible for production environments.