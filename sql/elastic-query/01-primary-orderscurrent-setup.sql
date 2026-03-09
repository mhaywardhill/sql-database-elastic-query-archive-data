/*
Run this script against appdb-primary.
It creates the source table used by Elastic Query if it does not already exist.
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
