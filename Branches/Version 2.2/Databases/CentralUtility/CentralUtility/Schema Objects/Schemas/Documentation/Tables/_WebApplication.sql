CREATE TABLE [Documentation].[_WebApplication]
(
	[WebApplicationID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplication] varchar(100) NOT NULL
)
GO
ALTER TABLE [Documentation].[_WebApplication] ADD CONSTRAINT PK_Documentation__WebApplication_WebApplicationID PRIMARY KEY CLUSTERED ([WebApplicationID] ASC)
GO