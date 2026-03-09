/*
Run this script against appdb-primary.
It inserts rows into the archive database through the external table.
*/

INSERT INTO dbo.OrderArchiveExt
(
  OrderId,
  CustomerId,
  OrderDateUtc,
  TotalAmount,
  ArchivedOnUtc
)
SELECT
  c.OrderId,
  c.CustomerId,
  c.OrderDateUtc,
  c.TotalAmount,
  SYSUTCDATETIME()
FROM dbo.OrdersCurrent AS c
WHERE c.OrderDateUtc < DATEADD(day, -30, SYSUTCDATETIME())
  AND c.ArchivedOnUtc IS NULL;
GO

UPDATE c
SET ArchivedOnUtc = SYSUTCDATETIME()
FROM dbo.OrdersCurrent AS c
WHERE c.OrderDateUtc < DATEADD(day, -30, SYSUTCDATETIME())
  AND c.ArchivedOnUtc IS NULL;
GO
