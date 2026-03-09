/*
Run this script against appdb-archive.
It creates a SQL credential, external data source,
and external table pointing to appdb-primary.

This script recreates these objects each run so stale credential state
does not block connectivity.

Replace the placeholder values before executing.

Prerequisite in appdb-primary:
- Run sql/elastic-query/01-primary-orderscurrent-setup.sql to ensure
  dbo.OrdersCurrent exists.
- Run sql/elastic-query/02-primary-elastic-reader-setup.sql to create
  a contained SQL user that can read dbo.OrdersCurrent.

Replace these placeholders before executing:
- <archive-master-key-password>
- <elastic-query-user>
- <elastic-query-user-password>
- <your-sql-server-name>.database.windows.net
*/

IF DB_NAME() = 'appdb-primary'
BEGIN
  THROW 50001, 'Do not run this script in appdb-primary. Run it in appdb-archive.', 1;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<archive-master-key-password>';
END;
GO

IF OBJECT_ID('dbo.OrdersCurrentExt', 'ET') IS NOT NULL
BEGIN
  DROP EXTERNAL TABLE dbo.OrdersCurrentExt;
END;
GO

IF EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'PrimaryDataSource')
BEGIN
  DROP EXTERNAL DATA SOURCE PrimaryDataSource;
END;
GO

IF EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'PrimaryDbCredential')
BEGIN
  DROP DATABASE SCOPED CREDENTIAL PrimaryDbCredential;
END;
GO

CREATE DATABASE SCOPED CREDENTIAL PrimaryDbCredential
WITH
  IDENTITY = '<elastic-query-user>',
  SECRET = '<elastic-query-user-password>';
GO

CREATE EXTERNAL DATA SOURCE PrimaryDataSource
WITH
(
  TYPE = RDBMS,
  LOCATION = '<your-sql-server-name>.database.windows.net',
  DATABASE_NAME = 'appdb-primary',
  CREDENTIAL = PrimaryDbCredential
);
GO

CREATE EXTERNAL TABLE dbo.OrdersCurrentExt
(
  OrderId bigint NOT NULL,
  CustomerId bigint NOT NULL,
  OrderDateUtc datetime2(0) NOT NULL,
  TotalAmount decimal(18,2) NOT NULL,
)
WITH
(
  DATA_SOURCE = PrimaryDataSource,
  SCHEMA_NAME = 'dbo',
  OBJECT_NAME = 'OrdersCurrent'
);
GO
