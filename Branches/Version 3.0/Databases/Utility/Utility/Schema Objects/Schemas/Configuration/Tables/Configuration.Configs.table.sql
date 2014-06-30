CREATE TABLE [Configuration].[Configs]
(
	[ConfigID] INT IDENTITY(1,1) NOT NULL,
	[ConfigName] VARCHAR(250) NOT NULL,
	[ConfigDesc] VARCHAR(max) NULL,
	[IsEnabled] BIT NOT NULL
)
GO
ALTER TABLE [Configuration].[Configs] ADD CONSTRAINT PK_Configuration_Configs_ConfigID PRIMARY KEY CLUSTERED
(
	[ConfigID] ASC
)
GO
ALTER TABLE [Configuration].[Configs] ADD CONSTRAINT UQ_Configuration_Configs_ConfigName UNIQUE ([ConfigName])
GO