CREATE TABLE [Documentation].[Databases]
(
	[DatabaseID] bigint IDENTITY(1,1) NOT NULL,
	[LocationID] bigint NOT NULL,
	[EnvironmentID] bigint NOT NULL,
	[ServerID] bigint NOT NULL,
	[Name] sysname NOT NULL,
	[IsPublished] bit,
	[IsMergePublished] bit
)
GO
ALTER TABLE [Documentation].[Databases] ADD CONSTRAINT PK_Documentation_Databases_DatabaseID PRIMARY KEY CLUSTERED ([DatabaseID] ASC)
GO
ALTER TABLE [Documentation].[Databases] ADD CONSTRAINT FK_Documentation_Databases_LocationID FOREIGN KEY ([LocationID]) REFERENCES [Lookup].[Locations]([LocationID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[Databases] ADD CONSTRAINT FK_Documentation_Databases_EnvironmentID FOREIGN KEY ([EnvironmentID]) REFERENCES [Lookup].[Environments]([EnvironmentID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[Databases] ADD CONSTRAINT FK_Documentation_Databases_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Lookup].[Servers]([ServerID]) ON DELETE CASCADE
GO