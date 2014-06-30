CREATE TABLE [Trace].[Options]
(
	[OptionID] INT IDENTITY(1,1) NOT NULL,
	[DiskLocationID] INT NOT NULL,
	[TraceName] varchar(50) NOT NULL,
	[PurgeDays] INT NOT NULL,
	[MaxFileSize] BIGINT NOT NULL,
	[QueryRunTime] BIGINT NULL,
	[Reads] BIGINT NULL,
	[Writes] BIGINT NULL
)
GO
ALTER TABLE [Trace].[Options] ADD CONSTRAINT PK_Trace_Options_OptionsID PRIMARY KEY CLUSTERED
(
	[OptionID] ASC
)
GO
ALTER TABLE [Trace].[Options] ADD CONSTRAINT CK_Trace_Options_PurgeDays CHECK (PurgeDays >= 0 AND PurgeDays <= 365)
GO
ALTER TABLE [Trace].[Options] ADD CONSTRAINT FK_Trace_Options_DiskLocationID FOREIGN KEY ([DiskLocationID]) REFERENCES [Configuration].DiskLocations([DiskLocationID])
GO
ALTER TABLE [Trace].[Options] ADD CONSTRAINT UQ_Trace_Options_TraceName UNIQUE ([TraceName])
GO