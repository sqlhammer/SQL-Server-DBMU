CREATE TABLE [Configuration].[DataSources]
(
	[DataSourceID] INT IDENTITY(1,1) NOT NULL,
	[ConnectionName] SYSNAME NOT NULL,
	[ConnectionString] NVARCHAR(4000) NOT NULL
)
GO
ALTER TABLE [Configuration].[DataSources] ADD CONSTRAINT [PK_Configuration_DataSources_CentralDDLID] PRIMARY KEY CLUSTERED ([DataSourceID])
GO
ALTER TABLE [Configuration].[DataSources] ADD CONSTRAINT [UQ_Configuration_DataSources_ConnectionName] UNIQUE NONCLUSTERED ([ConnectionName])
GO
