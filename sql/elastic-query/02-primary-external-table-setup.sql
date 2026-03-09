/*
Run this script against appdb-primary.
It creates a local sample table, master key, credential, external data source,
and external table pointing to appdb-archive.

Replace the placeholder values before executing.
*/

IF OBJECT_ID('dbo.OrdersCurrent', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdersCurrent
  (
    OrderId bigint NOT NULL,
    CustomerId bigint NOT NULL,
    OrderDateUtc datetime2(0) NOT NULL,
    TotalAmount decimal(18,2) NOT NULL,
    ArchivedOnUtc datetime2(0) NULL,
    CONSTRAINT PK_OrdersCurrent PRIMARY KEY (OrderId)
  );
END;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.symmetric_keys
  WHERE name = '##MS_DatabaseMasterKey##'
)
BEGIN
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<REPLACE_WITH_MASTER_KEY_PASSWORD>';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'ArchiveDbCredential')
BEGIN
  CREATE DATABASE SCOPED CREDENTIAL ArchiveDbCredential
  WITH IDENTITY = 'archive_writer', SECRET = '<REPLACE_WITH_ARCHIVE_WRITER_PASSWORD>';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'ArchiveDataSource')
BEGIN
  CREATE EXTERNAL DATA SOURCE ArchiveDataSource
  WITH
  (
    TYPE = RDBMS,
    LOCATION = '<your-sql-server-name>.database.windows.net',
    DATABASE_NAME = 'appdb-archive',
    CREDENTIAL = ArchiveDbCredential
  );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE name = 'OrderArchiveExt' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE EXTERNAL TABLE dbo.OrderArchiveExt
  (
    OrderId bigint NOT NULL,
    CustomerId bigint NOT NULL,
    OrderDateUtc datetime2(0) NOT NULL,
    TotalAmount decimal(18,2) NOT NULL,
    ArchivedOnUtc datetime2(0) NOT NULL
  )
  WITH
  (
    DATA_SOURCE = ArchiveDataSource,
    SCHEMA_NAME = 'dbo',
    OBJECT_NAME = 'OrderArchive'
  );
END;
GO
