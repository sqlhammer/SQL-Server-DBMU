CREATE TABLE [Trace].[Configs]
(
	[TraceConfigID] INT IDENTITY(1,1) NOT NULL,
	[OptionID] INT NOT NULL,
	[ConfigID] INT NOT NULL,
	[IsEnabled] BIT NOT NULL
)
GO
ALTER TABLE [Trace].[Configs] ADD CONSTRAINT PK_Trace_Configs_TraceConfigID PRIMARY KEY CLUSTERED
(
	[TraceConfigID] ASC
)
GO
ALTER TABLE [Trace].[Configs] ADD CONSTRAINT FK_Trace_Configs_Configuration_ConfigID FOREIGN KEY ([ConfigID]) REFERENCES [Configuration].[Configs]([ConfigID])
GO
ALTER TABLE [Trace].[Configs] ADD CONSTRAINT FK_Trace_Configs_Trace_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [Trace].[Options]([OptionID])
GO