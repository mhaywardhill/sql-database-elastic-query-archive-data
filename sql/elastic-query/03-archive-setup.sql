/*
Run this script against appdb-archive.
It creates the local archive table.
*/

IF OBJECT_ID('dbo.OrderArchive', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrderArchive
  (
    OrderId bigint NOT NULL,
    CustomerId bigint NOT NULL,
    OrderDateUtc datetime2(0) NOT NULL,
    TotalAmount decimal(18,2) NOT NULL,
    CONSTRAINT PK_OrderArchive PRIMARY KEY (OrderId)
  );
END;
GO
