CREATE TABLE [Logging].[Options]
(
	[OptionID] INT IDENTITY(1,1) NOT NULL,
	[LoggingModeID] TINYINT NOT NULL,
	[PurgeTypeID] INT NULL,
	[PurgeValue] INT NULL
)
GO
ALTER TABLE [Logging].[Options] ADD CONSTRAINT PK_Logging_Options_OptionsID PRIMARY KEY CLUSTERED ([OptionID] ASC) ON [Logging]
GO
ALTER TABLE [Logging].[Options] ADD CONSTRAINT FK_Logging_Options_LoggingModeID FOREIGN KEY ([LoggingModeID]) 
	REFERENCES [Lookup].[LoggingModes]([LoggingModeID])
GO
ALTER TABLE [Logging].[Options] ADD CONSTRAINT FK_Logging_Options_PurgeTypeID FOREIGN KEY ([PurgeTypeID]) 
	REFERENCES [Lookup].[PurgeTypes] ([PurgeTypeID]);
GO
ALTER TABLE [Logging].[Options] ADD CONSTRAINT [CK_Logging_Options_PurgeTypeID] CHECK (
	CASE 
		WHEN [Lookup].[IsPurgeByDays]([PurgeTypeID]) = 1 THEN 1
		WHEN [Lookup].[IsPurgeByRows]([PurgeTypeID]) = 1 THEN 1
		WHEN [PurgeTypeID] IS NULL THEN 1
		ELSE 0
	END = 1
	)
GO
ALTER TABLE [Logging].[Options] ADD CONSTRAINT [CK_Logging_Options_PurgeTypeID_PurgeValue] CHECK (
	CASE
		WHEN [PurgeValue] IS NOT NULL AND [PurgeTypeID] IS NOT NULL THEN 1
		WHEN [PurgeValue] IS NULL AND [PurgeTypeID] IS NULL THEN 1
		ELSE 0
	END = 1
	)
GO
