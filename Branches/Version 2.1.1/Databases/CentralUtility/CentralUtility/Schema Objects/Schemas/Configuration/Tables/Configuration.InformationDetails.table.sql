CREATE TABLE [Configuration].[InformationDetails]
(
	[InformationDetailID] INT IDENTITY(1,1) NOT NULL,
	[FeatureID] INT NOT NULL,
	[InformationTypeID] INT NOT NULL,
	[Detail] VARCHAR(8000) NOT NULL
)
GO
ALTER TABLE [Configuration].[InformationDetails] ADD CONSTRAINT PK_Configuration_InformationDetail_InformationDetailID PRIMARY KEY CLUSTERED
(
	[InformationDetailID] ASC
)
GO
ALTER TABLE [Configuration].[InformationDetails] ADD CONSTRAINT FK_Configuration_InformationDetails_BackupTypeID FOREIGN KEY ([FeatureID]) REFERENCES [Lookup].[Features]([FeatureID])
GO
ALTER TABLE [Configuration].[InformationDetails] ADD CONSTRAINT FK_Configuration_InformationDetails_DiskLocationID FOREIGN KEY ([InformationTypeID]) REFERENCES [Lookup].[InformationTypes]([InformationTypeID])
