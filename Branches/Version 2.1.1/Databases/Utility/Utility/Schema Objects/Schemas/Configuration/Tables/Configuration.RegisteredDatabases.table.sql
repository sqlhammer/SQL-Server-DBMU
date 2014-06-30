CREATE TABLE [Configuration].[RegisteredDatabases]
(
	[DatabaseID] INT IDENTITY(1,1) NOT NULL,
	[DatabaseName] VARCHAR(128) NOT NULL
)
GO
ALTER TABLE [Configuration].[RegisteredDatabases] ADD CONSTRAINT PK_Configuration_RegisteredDatabases_DatabaseID PRIMARY KEY CLUSTERED
(
	[DatabaseID] ASC
)
GO