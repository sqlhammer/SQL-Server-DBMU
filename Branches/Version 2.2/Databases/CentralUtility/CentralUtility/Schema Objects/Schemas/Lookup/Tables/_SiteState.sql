CREATE TABLE [Lookup].[_SiteState]
(
	[SiteStateID] bigint IDENTITY(1,1) NOT NULL, 
    [State] VARCHAR(10) NOT NULL
)
GO
ALTER TABLE [Lookup].[_SiteState] ADD CONSTRAINT PK_Lookup__SiteState_SiteStateID PRIMARY KEY CLUSTERED ([SiteStateID] ASC)
GO
