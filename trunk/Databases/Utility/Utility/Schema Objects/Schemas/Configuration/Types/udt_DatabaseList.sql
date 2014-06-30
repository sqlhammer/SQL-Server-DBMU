CREATE TYPE [dbo].[udt_DatabaseList] AS TABLE
(
	RegisteredDatabaseID INT NULL UNIQUE,
	DatabaseName SYSNAME NULL UNIQUE
)
