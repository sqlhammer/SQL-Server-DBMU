CREATE TABLE [Hold].[_WebApplicationSite]
(
	[WebApplicationSiteID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplicationID] bigint NOT NULL, 
    [SiteID] bigint NOT NULL
)
GO
ALTER TABLE [Hold].[_WebApplicationSite] ADD CONSTRAINT PK_Hold__WebApplicationSite_WebApplicationSiteID PRIMARY KEY CLUSTERED ([WebApplicationSiteID] ASC)
GO
ALTER TABLE [Hold].[_WebApplicationSite] ADD CONSTRAINT FK_Hold__WebApplicationSite_WebApplicationID FOREIGN KEY ([WebApplicationID]) REFERENCES [Hold].[_WebApplication]([WebApplicationID]) ON DELETE CASCADE
GO
ALTER TABLE [Hold].[_WebApplicationSite] ADD CONSTRAINT FK_Hold__WebApplicationSite_SiteID FOREIGN KEY ([SiteID]) REFERENCES [Hold].[_Site]([SiteID]) ON DELETE CASCADE
GO