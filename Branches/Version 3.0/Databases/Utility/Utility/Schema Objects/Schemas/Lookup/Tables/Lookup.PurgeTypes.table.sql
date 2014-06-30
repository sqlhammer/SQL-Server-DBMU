CREATE TABLE [Lookup].[PurgeTypes]
(
	[PurgeTypeID] INT IDENTITY(1,1) NOT NULL,
	[PurgeTypeDesc] VARCHAR(50) NOT NULL
)
GO
ALTER TABLE [Lookup].[PurgeTypes] ADD CONSTRAINT PK_PurgeTypes_PurgeTypesID PRIMARY KEY CLUSTERED
(
	[PurgeTypeID] ASC
)
GO