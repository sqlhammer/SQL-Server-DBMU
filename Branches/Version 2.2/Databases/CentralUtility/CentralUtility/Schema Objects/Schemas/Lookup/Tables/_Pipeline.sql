CREATE TABLE [Lookup].[_Pipeline]
(
	[PipelineID] bigint IDENTITY(1,1) NOT NULL, 
    [ManagedPipelineMode] VARCHAR(10) NOT NULL
)
GO
ALTER TABLE [Lookup].[_Pipeline] ADD CONSTRAINT PK_Lookup__Pipeline_PipelineID PRIMARY KEY CLUSTERED ([PipelineID] ASC)
GO
