CREATE TABLE [dbo].[MarkedTransactions]
(
	[Mark_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Marker_Name] VARCHAR(255) NOT NULL,
	[DatabaseName] [varchar](500) NOT NULL,
	[COMMIT_TIME] [datetime2](7) NOT NULL,
)
GO
ALTER TABLE [dbo].[MarkedTransactions] ADD CONSTRAINT [PK_MarkedTransactions_Mark_ID] PRIMARY KEY CLUSTERED ( [Mark_ID] ASC )
GO
ALTER TABLE [dbo].[MarkedTransactions] ADD CONSTRAINT [DF_MarkedTransactions_COMMIT_TIME]  DEFAULT (sysdatetime()) FOR [COMMIT_TIME]
GO
