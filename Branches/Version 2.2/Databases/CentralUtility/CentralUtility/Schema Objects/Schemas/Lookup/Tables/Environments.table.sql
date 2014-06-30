CREATE TABLE [Lookup].[Environments]
(
	[EnvironmentID] bigint IDENTITY(1,1) NOT NULL,
	[Environment] varchar(25) NOT NULL
)
GO
ALTER TABLE [Lookup].[Environments] ADD CONSTRAINT PK_Lookup_Environments_EnvironmentID PRIMARY KEY CLUSTERED ([EnvironmentID] ASC)
GO