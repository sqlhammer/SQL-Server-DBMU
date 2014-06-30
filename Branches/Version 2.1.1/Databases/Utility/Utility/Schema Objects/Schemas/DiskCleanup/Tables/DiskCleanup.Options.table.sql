CREATE TABLE [DiskCleanup].[Options]
(
	[OptionID] INT IDENTITY(1,1) NOT NULL,
	[DiskLocationID] INT NOT NULL,
	[PurgeValue] INT NOT NULL,
	[PurgeTypeID] INT NOT NULL
)
GO
ALTER TABLE [DiskCleanup].[Options] ADD CONSTRAINT PK_DiskCleanup_Options_OptionsID PRIMARY KEY CLUSTERED
(
	[OptionID] ASC
)
GO
ALTER TABLE [DiskCleanup].[Options] ADD CONSTRAINT FK_DiskCleanup_Options_DiskLocationID FOREIGN KEY ([DiskLocationID]) REFERENCES [Configuration].DiskLocations([DiskLocationID])
GO
ALTER TABLE [DiskCleanup].[Options] ADD CONSTRAINT FK_DiskCleanup_Options_PurgeTypeID FOREIGN KEY ([PurgeTypeID]) REFERENCES [Lookup].[PurgeTypes]([PurgeTypeID])
GO