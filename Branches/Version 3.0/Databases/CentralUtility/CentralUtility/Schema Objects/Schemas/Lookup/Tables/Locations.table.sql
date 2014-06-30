CREATE TABLE [Lookup].[Locations]
(
	[LocationID] bigint IDENTITY(1,1) NOT NULL,
	[Location] varchar(25) NOT NULL
)
GO
ALTER TABLE [Lookup].[Locations] ADD CONSTRAINT PK_Lookup_Locations_LocationID PRIMARY KEY CLUSTERED ([LocationID] ASC)
GO