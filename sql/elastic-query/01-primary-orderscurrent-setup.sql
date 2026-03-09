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
    CONSTRAINT PK_OrdersCurrent PRIMARY KEY (OrderId)
  );
END;
GO

INSERT INTO dbo.OrdersCurrent
(
  OrderId,
  CustomerId,
  OrderDateUtc,
  TotalAmount
)
SELECT
  s.OrderId,
  s.CustomerId,
  s.OrderDateUtc,
  s.TotalAmount
FROM
(
  VALUES
    (1001, 501, DATEADD(day, -45, SYSUTCDATETIME()), CAST(129.99 AS decimal(18,2))),
    (1002, 502, DATEADD(day, -31, SYSUTCDATETIME()), CAST(89.50  AS decimal(18,2))),
    (1003, 503, DATEADD(day, -15, SYSUTCDATETIME()), CAST(42.00  AS decimal(18,2))),
    (1004, 504, DATEADD(day, -7,  SYSUTCDATETIME()), CAST(19.99  AS decimal(18,2))),
    (1005, 505, DATEADD(day, -60, SYSUTCDATETIME()), CAST(250.00 AS decimal(18,2)))
) AS s(OrderId, CustomerId, OrderDateUtc, TotalAmount)
WHERE NOT EXISTS
(
  SELECT 1
  FROM dbo.OrdersCurrent AS o
  WHERE o.OrderId = s.OrderId
);
GO
