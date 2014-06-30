CREATE TABLE [Lookup].[InformationTypes]
(
	[InformationTypeID] INT IDENTITY(1,1) NOT NULL,
	[InfoTypeDesc] VARCHAR(128) NOT NULL
)
GO
ALTER TABLE [Lookup].[InformationTypes] ADD CONSTRAINT PK_Lookup_InformationTypes_InformationTypeID PRIMARY KEY CLUSTERED
(
	[InformationTypeID] ASC
)
