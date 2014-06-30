CREATE TABLE [IndexMaint].[Options]
(
	[OptionID] INT IDENTITY(1,1) NOT NULL,
	[FragLimit] TINYINT NOT NULL,
	[PageSpaceLimit] TINYINT NOT NULL,
	[StatisticsExpiration] TINYINT NOT NULL,
	[ExecuteWindowEnd] TINYINT NULL,
	[MaxDefrag] TINYINT NOT NULL,
	[CheckPeriodicity] TINYINT NULL
)
GO
ALTER TABLE [IndexMaint].[Options] ADD CONSTRAINT PK_IndexMaint_Options_OptionsID PRIMARY KEY CLUSTERED
(
	[OptionID] ASC
)
