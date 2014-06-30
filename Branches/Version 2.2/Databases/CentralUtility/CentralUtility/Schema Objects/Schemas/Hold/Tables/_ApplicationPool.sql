CREATE TABLE [Hold].[_ApplicationPool]
(
	[ApplicationPoolID] bigint IDENTITY(1,1) NOT NULL,
	[ApplicationPool] VARCHAR(100) NOT NULL,
	[PipelineID] bigint NOT NULL,
	[FrameworkID] bigint NOT NULL,
	[Identity] VARCHAR(50) NOT NULL
)
GO
ALTER TABLE [Hold].[_ApplicationPool] ADD CONSTRAINT PK_Hold__ApplicationPool__ApplicationPoolID PRIMARY KEY CLUSTERED ([ApplicationPoolID] ASC)
GO
ALTER TABLE [Hold].[_ApplicationPool] ADD CONSTRAINT FK_Hold__ApplicationPool_PipelineID FOREIGN KEY ([PipelineID]) REFERENCES [Lookup].[_Pipeline]([PipelineID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_ApplicationPool] ADD CONSTRAINT FK_Hold__ApplicationPool_FrameworkID FOREIGN KEY ([FrameworkID]) REFERENCES [Lookup].[_Framework]([FrameworkID]) ON DELETE CASCADE
GO