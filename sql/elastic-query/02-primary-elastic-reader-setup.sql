/*
Run this script against appdb-primary.
It creates a contained SQL user for Elastic Query and grants read access
on dbo.OrdersCurrent.

Replace placeholder values before executing.
*/

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '<elastic-query-user>')
BEGIN
  CREATE USER [<elastic-query-user>] WITH PASSWORD = '<elastic-query-user-password>';
END;
GO

GRANT SELECT ON dbo.OrdersCurrent TO [<elastic-query-user>];
GO
