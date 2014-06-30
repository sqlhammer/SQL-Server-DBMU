CREATE TABLE [IndexMaint].[Databases]
(
	[IndexDatabaseID] INT IDENTITY(1,1) NOT NULL,
	[DatabaseID] INT NOT NULL,
	[OptionID] INT NOT NULL
)
GO
ALTER TABLE [IndexMaint].[Databases] ADD CONSTRAINT PK_IndexMaint_Databases_IndexDatabasesID PRIMARY KEY CLUSTERED
(
	[IndexDatabaseID] ASC
)
GO
ALTER TABLE [IndexMaint].[Databases] ADD CONSTRAINT FK_IndexMaint_Databases_IndexMaint_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [IndexMaint].[Options] ([OptionID])
GO
ALTER TABLE [IndexMaint].[Databases] ADD CONSTRAINT FK_IndexMaint_Databases_Configurations_RegisteredDatabases FOREIGN KEY ([DatabaseID]) REFERENCES [Configuration].RegisteredDatabases ([DatabaseID])
GO