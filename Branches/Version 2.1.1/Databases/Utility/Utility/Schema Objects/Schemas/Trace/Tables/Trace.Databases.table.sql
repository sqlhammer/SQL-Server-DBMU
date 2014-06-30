CREATE TABLE [Trace].[Databases]
(
	[TraceDatabaseID] INT IDENTITY(1,1) NOT NULL,
	[DatabaseID] INT NOT NULL,
	[OptionID] INT NOT NULL
)
GO
ALTER TABLE [Trace].[Databases] ADD CONSTRAINT PK_Trace_Databases_TraceDatabasesID PRIMARY KEY CLUSTERED
(
	[TraceDatabaseID] ASC
)
GO
ALTER TABLE [Trace].[Databases] ADD CONSTRAINT FK_Trace_Databases_Trace_OptionsID FOREIGN KEY ([OptionID]) REFERENCES [Trace].[Options]([OptionID])
GO
ALTER TABLE [Trace].[Databases] ADD CONSTRAINT FK_Trace_Databases_Lookup_RegisteredDatabases FOREIGN KEY ([DatabaseID]) REFERENCES [Configuration].RegisteredDatabases([DatabaseID])
GO