# SQL Database Elastic Query Archive Data

Reference implementation for deploying Azure SQL resources and configuring Elastic Query to archive data from a primary database into an archive database.

## Overview

This repository provides:

- Infrastructure as Code using Bicep
- Automated deployment via shell script and environment variables
- SQL scripts to configure external tables and move data from primary to archive
- Codespaces startup automation for Azure CLI availability
- SQL Server configured for SQL authentication
- Modular Bicep templates for SQL server and databases

## Project Structure

```text
infra/
├── main.bicep                                 # Orchestration template
├── main.parameters.json                       # Example parameter values
├── deploy.sh                                  # Deployment script
└── modules/
	├── sqlServer.bicep                        # SQL logical server module
	└── sqlDatabase.bicep                      # SQL database module
sql/
└── elastic-query/
	├── 01-primary-orderscurrent-setup.sql     # Create source table + sample rows (appdb-primary)
	├── 02-primary-elastic-reader-setup.sql    # Create elastic query user + grant SELECT (appdb-primary)
	├── 03-archive-setup.sql                   # Create local archive table (appdb-archive)
	├── 04-primary-external-table-setup.sql    # Create credential, external data source, external table
	└── 05-primary-archive-insert.sql          # Insert archive data from external table
README.md                                      # Setup and usage guidance
LICENSE                                        # MIT license
```

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
export SQL_ADMIN_LOGIN="<sql-admin-login>"
export SQL_ADMIN_PASSWORD="<strong-sql-admin-password>"
```

Optional variables:

```bash
export DATABASE_ONE_NAME="appdb-primary"
export DATABASE_TWO_NAME="appdb-archive"
export DATABASE_SKU_NAME="S0"
export LOCATION="uksouth"
```

Deploy:

```bash
./infra/deploy.sh
```

Notes:

- If the resource group does not exist, infra/deploy.sh creates it.
- LOCATION controls SQL server and database deployment location.
- If LOCATION is not set, the script uses existing resource group location when available; otherwise it defaults to uksouth.
- SQL server is deployed via infra/main.bicep using module infra/modules/sqlServer.bicep.
- SQL authentication is enabled on the logical server.

## Elastic Query Configuration and Archiving

Run the scripts in this order:

1. Execute sql/elastic-query/01-primary-orderscurrent-setup.sql on appdb-primary.
2. Execute sql/elastic-query/02-primary-elastic-reader-setup.sql on appdb-primary.
3. Execute sql/elastic-query/03-archive-setup.sql on appdb-archive.
4. Update placeholders in sql/elastic-query/04-primary-external-table-setup.sql.
5. Execute sql/elastic-query/04-primary-external-table-setup.sql on appdb-archive.
6. Execute sql/elastic-query/05-primary-archive-insert.sql on appdb-archive.

Placeholders you must replace:

- In 02-primary-elastic-reader-setup.sql: <elastic-query-user>, <elastic-query-user-password>
- In 04-primary-external-table-setup.sql: <archive-master-key-password>, <elastic-query-user>, <elastic-query-user-password>, <your-sql-server-name>.database.windows.net

Elastic Query credential requirement:

- For TYPE = RDBMS external data sources, PrimaryDbCredential must include IDENTITY and SECRET.
- appdb-archive must have a database master key before creating a secret-based database scoped credential.
- The user in PrimaryDbCredential must have SELECT rights on dbo.OrdersCurrent in appdb-primary.

Connectivity requirements (Microsoft guidance):

- Reference article: https://techcommunity.microsoft.com/blog/azuredbsupport/resolve-elastic-query-issues-in-azure-sql-database/3583451
- SQL authentication is required for this elastic query pattern.
- Public endpoint must be enabled on the SQL logical server.
- Enable the option "Allow Azure services and resources to access this server" on the target SQL server.

## Security Guidance

- Do not commit production secrets to source control.
- Use secure password generation and rotation practices.
- Prefer managed identities and secret stores where possible for production environments.