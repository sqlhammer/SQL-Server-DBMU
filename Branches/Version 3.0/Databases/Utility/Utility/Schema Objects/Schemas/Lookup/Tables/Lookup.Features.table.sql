CREATE TABLE [Lookup].[Features]
(
	[FeatureID] INT IDENTITY(1,1) NOT NULL,
	[FeatureName] VARCHAR(128) NOT NULL
)
GO
ALTER TABLE [Lookup].[Features] ADD CONSTRAINT PK_Lookup_Features_FeatureID PRIMARY KEY CLUSTERED
(
	[FeatureID] ASC
)
GO
ALTER TABLE [Lookup].[Features] ADD CONSTRAINT UQ_Lookup_Features_FeatureName UNIQUE ([FeatureName])
