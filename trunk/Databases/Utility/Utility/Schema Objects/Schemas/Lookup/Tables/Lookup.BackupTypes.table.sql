CREATE TABLE [Lookup].[BackupTypes]
(
	[BackupTypeID] INT IDENTITY(1,1) NOT NULL,
	[BackupTypeDesc] VARCHAR(50) NOT NULL,
	[FileExtension] CHAR(3) NOT NULL
)
GO
ALTER TABLE [Lookup].BackupTypes ADD CONSTRAINT PK_Lookup_BackupTypes_BackupTypeID PRIMARY KEY CLUSTERED
(
	[BackupTypeID] ASC
)