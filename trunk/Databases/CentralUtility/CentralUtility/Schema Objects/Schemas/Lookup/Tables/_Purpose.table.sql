CREATE TABLE [Lookup].[_Purpose]
(
	[PurposeID] bigint IDENTITY(1,1) NOT NULL, 
	[Purpose] varchar(255) NULL
)
GO
ALTER TABLE [Lookup].[_Purpose] ADD CONSTRAINT PK_Lookup__Purpose_PurposeID PRIMARY KEY CLUSTERED ([PurposeID] ASC)
GO