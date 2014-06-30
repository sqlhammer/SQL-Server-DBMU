CREATE TABLE [Lookup].[_Environment]
(
	[EnvironmentId] bigint IDENTITY(1,1) NOT NULL,
	[Environment] varchar(25) NOT NULL
)
GO
ALTER TABLE [Lookup].[_Environment] ADD CONSTRAINT PK_Lookup__Environment_EnvironmentID PRIMARY KEY CLUSTERED ([EnvironmentID] ASC)
GO