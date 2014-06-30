CREATE VIEW [Configuration].[vwOrphanedDatabases]
AS
SELECT   [Rdb].[DatabaseName] AS [Orphaned_Databases]
FROM     [sys].[databases] Sdb
RIGHT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
WHERE    Sdb.name IS NULL 
	AND Rdb.DatabaseName <> 'ALL_SSAS_DATABASES'
