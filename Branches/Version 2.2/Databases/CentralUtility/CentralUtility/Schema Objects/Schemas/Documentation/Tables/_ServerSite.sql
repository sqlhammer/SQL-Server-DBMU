CREATE TABLE [Documentation].[_ServerSite]
(
	[ServerSiteID] bigint IDENTITY(1,1) NOT NULL, 
    [ServerID] bigint NOT NULL, 
    [SiteID] bigint NOT NULL, 
    [SiteStateID] bigint NOT NULL
)
GO
ALTER TABLE [Documentation].[_ServerSite] ADD CONSTRAINT PK_Documentation__ServerSite_ServerSiteID PRIMARY KEY CLUSTERED ([ServerSiteID] ASC)
GO
ALTER TABLE [Documentation].[_ServerSite] ADD CONSTRAINT FK_Documentation__ServerSite_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Lookup].[_Server]([ServerID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_ServerSite] ADD CONSTRAINT FK_Documentation__ServerSite_SiteID FOREIGN KEY ([SiteID]) REFERENCES [Documentation].[_Site]([SiteID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_ServerSite] ADD CONSTRAINT FK_Documentation__ServerSite_State FOREIGN KEY ([SiteStateID]) REFERENCES [Lookup].[_SiteState]([SiteStateID]) ON DELETE CASCADE
GO