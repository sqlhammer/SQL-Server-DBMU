CREATE TABLE [Configuration].[RegisteredDatabases]
(
	[DatabaseID] INT IDENTITY(1,1) NOT NULL,
	[DatabaseName] VARCHAR(128) NOT NULL,
	[VerifyBackup] BIT NOT NULL,
	[VerifyDiskCleanup] BIT NOT NULL,
	[VerifyIndexMaint] BIT NOT NULL
)
GO
ALTER TABLE [Configuration].[RegisteredDatabases] ADD CONSTRAINT PK_Configuration_RegisteredDatabases_DatabaseID PRIMARY KEY CLUSTERED
(
	[DatabaseID] ASC
)
GO
ALTER TABLE [Configuration].[RegisteredDatabases] ADD CONSTRAINT DF_Configuration_RegisteredDatabases_VerifyBackup DEFAULT 1 FOR [VerifyBackup];
GO
ALTER TABLE [Configuration].[RegisteredDatabases] ADD CONSTRAINT DF_Configuration_RegisteredDatabases_VerifyDiskCleanup DEFAULT 1 FOR [VerifyDiskCleanup];
GO
ALTER TABLE [Configuration].[RegisteredDatabases] ADD CONSTRAINT DF_Configuration_RegisteredDatabases_VerifyIndexMaint DEFAULT 1 FOR [VerifyIndexMaint];
GO
CREATE NONCLUSTERED INDEX [IX_Configuration_RegisteredDatabases_DatabaseName] ON [Configuration].[RegisteredDatabases] ([DatabaseName]);
GO
