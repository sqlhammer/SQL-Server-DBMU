CREATE TABLE [Lookup].[_Servers]
(
	[ServerID] bigint IDENTITY(1,1) NOT NULL, 
	[Server] sysname NOT NULL,
	[DNS] varchar(255) NULL,
	[PurposeID] bigint NOT NULL
)
GO
ALTER TABLE [Lookup].[_Servers] ADD CONSTRAINT PK_Lookup__Servers_ServerID PRIMARY KEY CLUSTERED ([ServerID] ASC)
GO
ALTER TABLE [Lookup].[_Servers] ADD CONSTRAINT FK_Lookup__Servers_PurposeID FOREIGN KEY ([PurposeID]) REFERENCES [Lookup].[_Purpose]([PurposeID]) ON DELETE CASCADE
GO