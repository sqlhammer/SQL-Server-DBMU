CREATE TABLE [Hold].[_ServerSite]
(
	[ServerSiteID] bigint IDENTITY(1,1) NOT NULL, 
    [ServerID] bigint NOT NULL, 
    [SiteID] bigint NOT NULL, 
    [SiteStateID] bigint NOT NULL
)
GO
ALTER TABLE [Hold].[_ServerSite] ADD CONSTRAINT PK_Hold__ServerSite_ServerSiteID PRIMARY KEY CLUSTERED ([ServerSiteID] ASC)
GO
ALTER TABLE [Hold].[_ServerSite] ADD CONSTRAINT FK_Hold__ServerSite_ServerID FOREIGN KEY ([ServerID]) REFERENCES [Lookup].[_Server]([ServerID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_ServerSite] ADD CONSTRAINT FK_Hold__ServerSite_SiteID FOREIGN KEY ([SiteID]) REFERENCES [Hold].[_Site]([SiteID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_ServerSite] ADD CONSTRAINT FK_Hold__ServerSite_State FOREIGN KEY ([SiteStateID]) REFERENCES [Lookup].[_SiteState]([SiteStateID]) ON DELETE CASCADE
GO