CREATE TABLE [Lookup].[_Authentication]
(
	[AuthenticationID] bigint IDENTITY(1,1) NOT NULL, 
    [Authentication] varchar(50) NOT NULL
)
GO
ALTER TABLE [Lookup].[_Authentication] ADD CONSTRAINT PK_Lookup__Authentication_AuthenticationID PRIMARY KEY CLUSTERED ([AuthenticationID] ASC)
GO