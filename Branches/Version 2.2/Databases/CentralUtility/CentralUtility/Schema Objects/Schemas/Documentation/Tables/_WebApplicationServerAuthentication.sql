CREATE TABLE [Documentation].[_WebApplicationServerAuthentication]
(
	[WebApplicationServerAuthenticationID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplicationServerID] bigint NOT NULL, 
    [AuthenticationID] bigint NOT NULL
)
GO
ALTER TABLE [Documentation].[_WebApplicationServerAuthentication] ADD CONSTRAINT PK_Documentation__WebApplicationServerAuthentication_WebApplicationServerAuthenticationID PRIMARY KEY CLUSTERED ([WebApplicationServerAuthenticationID] ASC)
GO
ALTER TABLE [Documentation].[_WebApplicationServerAuthentication] ADD CONSTRAINT FK_Documentation__WebApplicationServerAuthentication_WebApplicationServerID FOREIGN KEY ([WebApplicationServerID]) REFERENCES [Documentation].[_WebApplicationServer]([WebApplicationServerID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_WebApplicationServerAuthentication] ADD CONSTRAINT FK_Documentation__WebApplicationServerAuthentication_AuthenticationID FOREIGN KEY ([AuthenticationID]) REFERENCES [Lookup].[_Authentication]([AuthenticationID]) ON DELETE CASCADE
GO