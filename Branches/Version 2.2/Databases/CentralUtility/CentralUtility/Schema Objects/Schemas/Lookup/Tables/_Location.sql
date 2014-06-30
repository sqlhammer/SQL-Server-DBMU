CREATE TABLE [Lookup].[_Location]
(
	[LocationId] bigint IDENTITY(1,1) NOT NULL,
	[Location] varchar(25) NOT NULL
)
GO
ALTER TABLE [Lookup].[_Location] ADD CONSTRAINT PK_Lookup__Location_LocationID PRIMARY KEY CLUSTERED ([LocationID] ASC)
GO