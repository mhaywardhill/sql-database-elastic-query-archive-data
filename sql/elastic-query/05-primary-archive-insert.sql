/*
Run this script against appdb-archive.
It inserts rows into the local archive table by reading from the external
table that points to appdb-primary.
*/

INSERT INTO dbo.OrderArchive
(
  OrderId,
  CustomerId,
  OrderDateUtc,
  TotalAmount
)
SELECT
  p.OrderId,
  p.CustomerId,
  p.OrderDateUtc,
  p.TotalAmount
FROM dbo.OrdersCurrentExt AS p
WHERE p.OrderDateUtc < DATEADD(day, -30, SYSUTCDATETIME())
AND NOT EXISTS
  (
    SELECT 1
    FROM dbo.OrderArchive AS a
    WHERE a.OrderId = p.OrderId
  );
GO
