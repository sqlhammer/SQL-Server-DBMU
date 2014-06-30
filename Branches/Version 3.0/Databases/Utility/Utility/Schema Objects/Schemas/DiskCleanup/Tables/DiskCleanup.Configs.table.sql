CREATE TABLE [DiskCleanup].[Configs]
(
	[DiskCleanupConfigID] INT IDENTITY(1,1) NOT NULL,
	[OptionID] INT NOT NULL,
	[ConfigID] INT NOT NULL,
	[IsEnabled] BIT NOT NULL
)
GO
ALTER TABLE [DiskCleanup].[Configs] ADD CONSTRAINT PK_DiskCleanup_Configs_DiskCleanupConfigID PRIMARY KEY CLUSTERED
(
	[DiskCleanupConfigID] ASC
)
GO
ALTER TABLE [DiskCleanup].[Configs] ADD CONSTRAINT FK_DiskCleanup_Configs_ConfigID FOREIGN KEY ([ConfigID]) REFERENCES [Configuration].[Configs]([ConfigID])
GO
ALTER TABLE [DiskCleanup].[Configs] ADD CONSTRAINT FK_DiskCleanup_Configs_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [DiskCleanup].[Options]([OptionID])
GO