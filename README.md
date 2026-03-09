# SQL Database Elastic Query Archive Data

Reference implementation for deploying Azure SQL resources and configuring Elastic Query to archive data from a primary database into an archive database.

## Overview

This repository provides:

- Infrastructure as Code using Bicep
- Automated deployment via shell script and environment variables
- SQL scripts to configure external tables and move data from primary to archive
- Codespaces startup automation for Azure CLI availability
- SQL Server configured for Microsoft Entra ID-only authentication
- SQL server creation without SQL admin credentials

## Repository Structure

- infra/main.bicep: Deploys two SQL databases on an existing SQL logical server
- infra/main.parameters.json: Example deployment parameters
- infra/deploy.sh: Creates Entra-only SQL server (if missing) and deploys databases
- sql/elastic-query/01-primary-orderscurrent-setup.sql: Creates source table in appdb-primary
- sql/elastic-query/02-primary-elastic-reader-setup.sql: Creates contained SQL user in appdb-primary for Elastic Query read access
- sql/elastic-query/03-archive-setup.sql: Creates archive table in appdb-archive
- sql/elastic-query/04-primary-external-table-setup.sql: Creates SQL credential and external table in appdb-archive that references dbo.OrdersCurrent in appdb-primary
- sql/elastic-query/05-primary-archive-insert.sql: Inserts archive data in appdb-archive from external table
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
export ENTRA_ADMIN_OBJECT_ID="<entra-admin-object-id>"
```

Optional override:

```bash
# If omitted, deploy.sh resolves this automatically from ENTRA_ADMIN_OBJECT_ID
export ENTRA_ADMIN_LOGIN="<entra-admin-upn-or-display-name>"

# Optional only for cross-tenant scenarios
export ENTRA_TENANT_ID="<entra-tenant-id>"
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
- Entra tenant ID defaults automatically to the current deployment tenant.
- ENTRA_ADMIN_LOGIN is optional; the script resolves it from ENTRA_ADMIN_OBJECT_ID when possible.
- Use a User, Group, or Application object ID for ENTRA_ADMIN_OBJECT_ID.
- SQL server is created using az sql server create with --enable-ad-only-auth.
- SQL authentication is disabled on the logical server (Entra ID-only).

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

## Security Guidance

- Do not commit production secrets to source control.
- Use secure password generation and rotation practices.
- Prefer managed identities and secret stores where possible for production environments.