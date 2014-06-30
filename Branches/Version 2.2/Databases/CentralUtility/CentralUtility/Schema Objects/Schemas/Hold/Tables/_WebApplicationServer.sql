CREATE TABLE [Hold].[_WebApplicationServer]
(
	[WebApplicationServerID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplicationID] bigint NOT NULL, 
    [ServerID] bigint NOT NULL,
	[ApplicationPoolID] bigint NOT NULL,
	[PhysicalPath] varchar(MAX) NOT NULL
)
GO
ALTER TABLE [Hold].[_WebApplicationServer] ADD CONSTRAINT PK_Hold__WebApplicationServer_WebApplicationServerID PRIMARY KEY CLUSTERED ([WebApplicationServerID] ASC)
GO
ALTER TABLE [Hold].[_WebApplicationServer] ADD CONSTRAINT FK_Hold__WebApplicationServer_WebApplicationID FOREIGN KEY ([WebApplicationID]) REFERENCES [Hold].[_WebApplication]([WebApplicationID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_WebApplicationServer] ADD CONSTRAINT FK_Hold__WebApplicationServer_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Lookup].[_Server]([ServerID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_WebApplicationServer] ADD CONSTRAINT FK_Hold__WebApplicationServer_ApplicationPoolID FOREIGN KEY ([ApplicationPoolID]) REFERENCES [Hold].[_ApplicationPool]([ApplicationPoolID]) ON DELETE CASCADE
GO