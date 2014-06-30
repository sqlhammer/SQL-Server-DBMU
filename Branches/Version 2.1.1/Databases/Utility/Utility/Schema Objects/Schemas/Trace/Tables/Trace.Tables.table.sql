CREATE TABLE [Trace].[Tables]
(
	[TableID] INT IDENTITY(1,1) NOT NULL, 
	[OptionID] INT NOT NULL,
	[TableName] VARCHAR(60) NOT NULL,
	[IsMostRecent] BIT NOT NULL
)
GO
ALTER TABLE [Trace].[Tables] ADD CONSTRAINT PK_Trace_Tables_TablesID PRIMARY KEY CLUSTERED
(
	[TableID] ASC
)
GO
ALTER TABLE [Trace].[Tables] ADD CONSTRAINT DF_Trace_Tables_IsMostRecent DEFAULT 0 FOR [IsMostRecent]
GO
ALTER TABLE [Trace].[Tables] ADD CONSTRAINT UQ_Trace_Tables_TableName UNIQUE ([TableName])
GO