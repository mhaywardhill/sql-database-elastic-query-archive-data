/*
Run this script against appdb-archive.
It creates a managed identity credential, external data source,
and external table pointing to appdb-primary.

Replace the placeholder values before executing.

Prerequisite in appdb-primary:
- Ensure dbo.OrdersCurrent exists.
- Grant SELECT on dbo.OrdersCurrent to the principal represented by
  this credential (recommended: SQL server managed identity).
*/

IF NOT EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'PrimaryDbCredential')
BEGIN
  CREATE DATABASE SCOPED CREDENTIAL PrimaryDbCredential
  WITH IDENTITY = 'Managed Identity';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'PrimaryDataSource')
BEGIN
  CREATE EXTERNAL DATA SOURCE PrimaryDataSource
  WITH
  (
    TYPE = RDBMS,
    LOCATION = '<your-sql-server-name>.database.windows.net',
    DATABASE_NAME = 'appdb-primary',
    CREDENTIAL = PrimaryDbCredential
  );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE name = 'OrdersCurrentExt' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE EXTERNAL TABLE dbo.OrdersCurrentExt
  (
    OrderId bigint NOT NULL,
    CustomerId bigint NOT NULL,
    OrderDateUtc datetime2(0) NOT NULL,
    TotalAmount decimal(18,2) NOT NULL,
    ArchivedOnUtc datetime2(0) NULL
  )
  WITH
  (
    DATA_SOURCE = PrimaryDataSource,
    SCHEMA_NAME = 'dbo',
    OBJECT_NAME = 'OrdersCurrent'
  );
END;
GO
