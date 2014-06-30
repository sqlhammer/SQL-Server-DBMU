CREATE TABLE [Logging].[Configs]
(
	[LoggingConfigID] INT IDENTITY(1,1) NOT NULL,
	[OptionID] INT NOT NULL,
	[ConfigID] INT NOT NULL,
	[IsEnabled] BIT NOT NULL
)
GO
ALTER TABLE [Logging].[Configs] ADD CONSTRAINT PK_Logging_Configs_LoggingConfigID PRIMARY KEY CLUSTERED ([LoggingConfigID] ASC) ON [Logging]
GO
ALTER TABLE [Logging].[Configs] ADD CONSTRAINT FK_Logging_Configs_ConfigID FOREIGN KEY ([ConfigID]) REFERENCES [Configuration].[Configs]([ConfigID])
GO
ALTER TABLE [Logging].[Configs] ADD CONSTRAINT FK_Logging_Configs_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [Logging].[Options]([OptionID])
GO