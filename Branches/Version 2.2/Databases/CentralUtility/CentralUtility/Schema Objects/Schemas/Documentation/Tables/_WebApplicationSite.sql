CREATE TABLE [Documentation].[_WebApplicationSite]
(
	[WebApplicationSiteID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplicationID] bigint NOT NULL, 
    [SiteID] bigint NOT NULL
)
GO
ALTER TABLE [Documentation].[_WebApplicationSite] ADD CONSTRAINT PK_Documentation__WebApplicationSite_WebApplicationSiteID PRIMARY KEY CLUSTERED ([WebApplicationSiteID] ASC)
GO
ALTER TABLE [Documentation].[_WebApplicationSite] ADD CONSTRAINT FK_Documentation__WebApplicationSite_WebApplicationID FOREIGN KEY ([WebApplicationID]) REFERENCES [Documentation].[_WebApplication]([WebApplicationID]) ON DELETE CASCADE
GO
ALTER TABLE [Documentation].[_WebApplicationSite] ADD CONSTRAINT FK_Documentation__WebApplicationSite_SiteID FOREIGN KEY ([SiteID]) REFERENCES [Documentation].[_Site]([SiteID]) ON DELETE CASCADE
GO