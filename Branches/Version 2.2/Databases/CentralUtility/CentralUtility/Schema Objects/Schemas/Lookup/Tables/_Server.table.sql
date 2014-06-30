CREATE TABLE [Lookup].[_Server]
(
	[ServerID] bigint IDENTITY(1,1) NOT NULL, 
	[Server] sysname NOT NULL,
	[DNS] varchar(255) NULL,
	[PurposeID] bigint NOT NULL, 
    [EnvironmentID] bigint NOT NULL,
	[LocationID] bigint NOT NULL
)
GO
ALTER TABLE [Lookup].[_Server] ADD CONSTRAINT PK_Lookup__Server_ServerID PRIMARY KEY CLUSTERED ([ServerID] ASC)
GO
ALTER TABLE [Lookup].[_Server] ADD CONSTRAINT FK_Lookup__Server_PurposeID FOREIGN KEY ([PurposeID]) REFERENCES [Lookup].[_Purpose]([PurposeID]) ON DELETE CASCADE
GO
ALTER TABLE [Lookup].[_Server] ADD CONSTRAINT FK_Lookup__Server_EnvironmentID FOREIGN KEY ([EnvironmentID]) REFERENCES [Lookup].[_Environment]([EnvironmentID]) ON DELETE CASCADE
GO
ALTER TABLE [Lookup].[_Server] ADD CONSTRAINT FK_Lookup__Server_LocationID FOREIGN KEY ([LocationID]) REFERENCES [Lookup].[_Location]([LocationID]) ON DELETE CASCADE
GO