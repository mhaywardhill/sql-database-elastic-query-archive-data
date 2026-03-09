/*
Run this script against appdb-archive.
It creates the archive table and a contained user used by elastic query.
Replace the password before executing.
*/

IF OBJECT_ID('dbo.OrderArchive', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrderArchive
  (
    OrderId bigint NOT NULL,
    CustomerId bigint NOT NULL,
    OrderDateUtc datetime2(0) NOT NULL,
    TotalAmount decimal(18,2) NOT NULL,
    ArchivedOnUtc datetime2(0) NOT NULL,
    CONSTRAINT PK_OrderArchive PRIMARY KEY (OrderId)
  );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'archive_writer')
BEGIN
  CREATE USER archive_writer WITH PASSWORD = '<REPLACE_WITH_STRONG_PASSWORD>';
END;
GO

GRANT SELECT, INSERT ON dbo.OrderArchive TO archive_writer;
GO
