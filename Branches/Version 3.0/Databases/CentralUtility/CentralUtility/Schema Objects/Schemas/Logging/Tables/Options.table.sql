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
ALTER TABLE [Logging].[Options] ADD CONSTRAINT FK_Logging_Options_LoggingModeID FOREIGN KEY ([LoggingModeID]) REFERENCES [Lookup].[LoggingModes]([LoggingModeID])
GO
