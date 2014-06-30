CREATE TABLE [Documentation].[_ApplicationPool]
(
	[ApplicationPoolID] bigint IDENTITY(1,1) NOT NULL,
	[ApplicationPool] VARCHAR(100) NOT NULL,
	[PipelineID] bigint NOT NULL,
	[FrameworkID] bigint NOT NULL,
	[Identity] VARCHAR(50) NOT NULL
)
GO
ALTER TABLE [Documentation].[_ApplicationPool] ADD CONSTRAINT PK_Documentation__ApplicationPool__ApplicationPoolID PRIMARY KEY CLUSTERED ([ApplicationPoolID] ASC)
GO
ALTER TABLE [Documentation].[_ApplicationPool] ADD CONSTRAINT FK_Documentation__ApplicationPool_PipelineID FOREIGN KEY ([PipelineID]) REFERENCES [Lookup].[_Pipeline]([PipelineID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_ApplicationPool] ADD CONSTRAINT FK_Documentation__ApplicationPool_FrameworkID FOREIGN KEY ([FrameworkID]) REFERENCES [Lookup].[_Framework]([FrameworkID]) ON DELETE CASCADE
GO