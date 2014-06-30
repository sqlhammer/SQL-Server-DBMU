CREATE TABLE [Documentation].[_Site]
(
	[SiteID] bigint IDENTITY(1,1) NOT NULL,
	[Site] varchar(100) NOT NULL
)
GO
ALTER TABLE [Documentation].[_Site] ADD CONSTRAINT PK_Documentation__Site_SiteID PRIMARY KEY CLUSTERED ([SiteID] ASC)
GO