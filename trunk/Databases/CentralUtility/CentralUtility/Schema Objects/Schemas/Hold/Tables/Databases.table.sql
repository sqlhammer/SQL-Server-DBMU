CREATE TABLE [Hold].[Databases]
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
ALTER TABLE [Hold].[Databases] ADD CONSTRAINT PK_Hold_Databases_DatabaseID PRIMARY KEY CLUSTERED ([DatabaseID] ASC)
GO
--ALTER TABLE [Hold].[Databases] ADD CONSTRAINT FK_Hold_Databases_LocationID FOREIGN KEY ([LocationID]) REFERENCES [Hold].[Locations]([LocationID]) ON DELETE CASCADE
--GO
--ALTER TABLE [Hold].[Databases] ADD CONSTRAINT FK_Hold_Databases_EnvironmentID FOREIGN KEY ([EnvironmentID]) REFERENCES [Hold].[Environments]([EnvironmentID]) ON DELETE CASCADE
--GO
--ALTER TABLE [Hold].[Databases] ADD CONSTRAINT FK_Hold_Databases_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Hold].[Servers]([ServerID]) ON DELETE CASCADE
--GO