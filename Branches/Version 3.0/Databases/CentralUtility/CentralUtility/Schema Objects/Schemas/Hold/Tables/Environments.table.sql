CREATE TABLE [Hold].[Environments]
(
	[EnvironmentID] bigint IDENTITY(1,1) NOT NULL,
	[Environment] varchar(25) NOT NULL
)
GO
ALTER TABLE [Hold].[Environments] ADD CONSTRAINT PK_Hold_Environments_EnvironmentID PRIMARY KEY CLUSTERED ([EnvironmentID] ASC)
GO