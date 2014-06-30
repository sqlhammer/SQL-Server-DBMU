CREATE TABLE [DiskCleanup].[Databases]
(
	[DiskCleanupDatabaseID] INT IDENTITY(1,1) NOT NULL,
	[DatabaseID] INT NOT NULL,
	[OptionID] INT NOT NULL
)
GO
ALTER TABLE [DiskCleanup].[Databases] ADD CONSTRAINT PK_DiskCleanup_Databases_DiskCleanupDatabasesID PRIMARY KEY CLUSTERED
(
	[DiskCleanupDatabaseID] ASC
)
GO
ALTER TABLE [DiskCleanup].[Databases] ADD CONSTRAINT FK_DiskCleanup_Databases_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [DiskCleanup].[Options]([OptionID])
GO
ALTER TABLE [DiskCleanup].[Databases] ADD CONSTRAINT FK_DiskCleanup_Databases_DatabaseID FOREIGN KEY ([DatabaseID]) REFERENCES [Configuration].RegisteredDatabases([DatabaseID])
GO