CREATE TABLE [Logging].[Entries]
(
	[EntryID] BIGINT IDENTITY(1,1) NOT NULL,
	[LoginName] SYSNAME NOT NULL,
	[FeatureID] INT NOT NULL,
	[TextEntry] VARCHAR(8000) NOT NULL,
	[InsertDate] DATETIME2(3) NOT NULL
)
GO
ALTER TABLE [Logging].[Entries] ADD CONSTRAINT DF_Logging_Entries_InsertDate DEFAULT GETDATE() FOR [InsertDate]
GO
ALTER TABLE [Logging].[Entries] ADD CONSTRAINT PK_Logging_Entries_EntryID PRIMARY KEY NONCLUSTERED ([EntryID] ASC) WITH (FILLFACTOR = 80) ON [Logging]
GO
CREATE CLUSTERED INDEX [IX_Logging_Entries_InsertDate] ON [Logging].[Entries] ([InsertDate] DESC) WITH (FILLFACTOR = 80) ON [Logging]
GO
CREATE NONCLUSTERED INDEX [IX_Logging_Entries_FeatureID] ON [Logging].[Entries] ([FeatureID] DESC) WITH (FILLFACTOR = 80) ON [Logging]
GO
