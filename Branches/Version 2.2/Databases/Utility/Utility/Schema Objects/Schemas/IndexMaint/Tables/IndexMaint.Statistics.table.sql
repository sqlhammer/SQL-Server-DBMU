CREATE TABLE [IndexMaint].[Statistics]
(
	[IndexStatisticID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [sysname] NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[IndexName] [sysname] NOT NULL,
	[IndexID] [int] NOT NULL,
	[IndexDepth] [tinyint] NULL,
	[IndexLevel] [tinyint] NULL,
	[PartitionNumber] [int] NULL,
	[IndexTypeDesc] [nvarchar](60) NULL,
	[AllocUnitTypeDesc] [nvarchar](60) NULL,
	[AvgFragmentationPercent] [float] NULL,
	[AvgPageSpaceUsedPercent] [float] NULL,
	[FillFactor] [tinyint] NOT NULL,
	[IsDisabled] [bit] NULL,
	[PageCount] [bigint] NULL,
	[RecordCount] [bigint] NULL,
	[IndexStatus] [varchar](50) NOT NULL,
	[InsertDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
GO
ALTER TABLE [IndexMaint].[Statistics] ADD CONSTRAINT PK_IndexMaint_Statistics_IndexStatisticID PRIMARY KEY CLUSTERED
(
	[IndexStatisticID] ASC
)
GO
ALTER TABLE [IndexMaint].[Statistics] ADD  CONSTRAINT [DF_IndexMaint_Statistics_IndexStatus]  DEFAULT ('Index Maintenance Required') FOR [IndexStatus]
GO
ALTER TABLE [IndexMaint].[Statistics] ADD  CONSTRAINT [DF_IndexMaint_Statistics_InsertDate]  DEFAULT (GETDATE()) FOR [InsertDate]
GO
