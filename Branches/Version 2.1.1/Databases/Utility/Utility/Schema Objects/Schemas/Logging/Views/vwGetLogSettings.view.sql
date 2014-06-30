CREATE VIEW [Logging].[vwGetLogSettings]
AS
	SELECT	opts.OptionID AS [OptionID]
			, ISNULL(Configs.ConfigName,'None') AS [ConfigName]
			, CASE 
				WHEN ISNULL(LogConfig.IsEnabled,0) = 1 AND ISNULL(Configs.IsEnabled,0) = 1 THEN 'True'
				WHEN ISNULL(LogConfig.IsEnabled,0) = 0 OR ISNULL(Configs.IsEnabled,0) = 0 THEN 'False'
			END AS [Enabled]
			, Feats.FeatureName AS [Feature]
			, Mode.LoggingModeDesc AS [LoggingMode]
			, ISNULL(pType.PurgeTypeDesc, 'Disabled') AS [PurgeType]
			, ISNULL(CAST(opts.PurgeValue AS VARCHAR(10)),'Disabled') AS [PurgeValue]
	FROM [Logging].[Options] opts
	INNER JOIN [Logging].[Features] LogFeats ON opts.OptionID = LogFeats.OptionID
	INNER JOIN [Lookup].[Features] Feats ON Feats.FeatureID = LogFeats.FeatureID
	INNER JOIN [Lookup].[LoggingModes] Mode ON Mode.LoggingModeID = opts.LoggingModeID
	LEFT JOIN [Lookup].[PurgeTypes] pType ON pType.PurgeTypeID = opts.PurgeTypeID
	LEFT JOIN [Logging].[Configs] LogConfig ON LogConfig.OptionID = opts.OptionID
	LEFT JOIN [Configuration].[Configs] Configs ON Configs.ConfigID = LogConfig.ConfigID
