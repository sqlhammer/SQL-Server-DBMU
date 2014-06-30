CREATE VIEW [Configuration].[vwInformationDetails]
AS
	SELECT F.FeatureName AS [Feature]
		, InfoT.InfoTypeDesc AS [InfoType]
		, InfoD.Detail AS [Detail]
	FROM [Configuration].[InformationDetails] InfoD
	INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
	INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoD.InformationTypeID = InfoT.InformationTypeID
