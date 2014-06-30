CREATE TABLE [Hold].[Locations]
(
	[LocationID] bigint IDENTITY(1,1) NOT NULL,
	[Location] varchar(25) NOT NULL
)
GO
ALTER TABLE [Hold].[Locations] ADD CONSTRAINT PK_Hold_Locations_LocationID PRIMARY KEY CLUSTERED ([LocationID] ASC)
GO