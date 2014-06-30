CREATE TABLE [Lookup].[LoggingModes]
(
	[LoggingModeID] TINYINT IDENTITY(1,1) NOT NULL,
	[LoggingModeDesc] VARCHAR(50) NOT NULL
)
GO
ALTER TABLE [Lookup].[LoggingModes] ADD CONSTRAINT PK_Lookup_LoggingModes_LoggingModeID PRIMARY KEY CLUSTERED ([LoggingModeID] ASC)
GO
