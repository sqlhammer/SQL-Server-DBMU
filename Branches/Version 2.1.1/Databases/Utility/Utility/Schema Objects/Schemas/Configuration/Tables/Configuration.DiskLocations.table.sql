CREATE TABLE [Configuration].[DiskLocations]
(
	[DiskLocationID] INT IDENTITY(1,1) NOT NULL,
	[FileExtension] CHAR(3) NOT NULL,
	[FilePath] VARCHAR(max) NOT NULL
)
GO
ALTER TABLE [Configuration].DiskLocations ADD CONSTRAINT PK_Configuration_DiskLocations_DiskLocationID PRIMARY KEY CLUSTERED
(
	[DiskLocationID] ASC
)
GO