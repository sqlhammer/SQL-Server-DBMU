CREATE TABLE [Lookup].[_Framework]
(
	[FrameworkID] bigint IDENTITY(1,1) NOT NULL, 
    [ManagedRuntimeVersion] VARCHAR(10) NOT NULL
)
GO
ALTER TABLE [Lookup].[_Framework] ADD CONSTRAINT PK_Lookup__Framework_FrameworkID PRIMARY KEY CLUSTERED ([FrameworkID] ASC)
GO
