CREATE TABLE [Hold].[_WebApplication]
(
	[WebApplicationID] bigint IDENTITY(1,1) NOT NULL, 
    [WebApplication] varchar(100) NOT NULL
)
GO
ALTER TABLE [Hold].[_WebApplication] ADD CONSTRAINT PK_Hold__WebApplication_WebApplicationID PRIMARY KEY CLUSTERED ([WebApplicationID] ASC)
GO