CREATE TABLE [IndexMaint].[Configs]
(
	[IndexMaintConfigID] INT IDENTITY(1,1) NOT NULL,
	[OptionID] INT NOT NULL,
	[ConfigID] INT NOT NULL,
	[IsEnabled] BIT NOT NULL
)
GO
ALTER TABLE [IndexMaint].[Configs] ADD CONSTRAINT PK_IndexMaint_Configs_IndexMaintConfigID PRIMARY KEY CLUSTERED
(
	[IndexMaintConfigID] ASC
)
GO
ALTER TABLE [IndexMaint].[Configs] ADD CONSTRAINT FK_IndexMaint_Configs_Configuration_ConfigID FOREIGN KEY ([ConfigID]) REFERENCES [Configuration].[Configs]([ConfigID])
GO
ALTER TABLE [IndexMaint].[Configs] ADD CONSTRAINT FK_IndexMaint_Configs_IndexMaint_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [IndexMaint].[Options]([OptionID])