CREATE TABLE [Documentation].[_WebApplicationServer]
(
	[WebApplicationServerID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplicationID] bigint NOT NULL, 
    [ServerID] bigint NOT NULL,
	[ApplicationPoolID] bigint NOT NULL,
	[PhysicalPath] varchar(MAX) NOT NULL
)
GO
ALTER TABLE [Documentation].[_WebApplicationServer] ADD CONSTRAINT PK_Documentation__WebApplicationServer_WebApplicationServerID PRIMARY KEY CLUSTERED ([WebApplicationServerID] ASC)
GO
ALTER TABLE [Documentation].[_WebApplicationServer] ADD CONSTRAINT FK_Documentation__WebApplicationServer_WebApplicationID FOREIGN KEY ([WebApplicationID]) REFERENCES [Documentation].[_WebApplication]([WebApplicationID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_WebApplicationServer] ADD CONSTRAINT FK_Documentation__WebApplicationServer_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Lookup].[_Server]([ServerID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_WebApplicationServer] ADD CONSTRAINT FK_Documentation__WebApplicationServer_ApplicationPoolID FOREIGN KEY ([ApplicationPoolID]) REFERENCES [Documentation].[_ApplicationPool]([ApplicationPoolID]) ON DELETE CASCADE
GO