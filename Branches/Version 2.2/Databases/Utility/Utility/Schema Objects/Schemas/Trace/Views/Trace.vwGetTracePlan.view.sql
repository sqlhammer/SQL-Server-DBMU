CREATE VIEW [Trace].[vwGetTracePlan]
AS
	SELECT	opts.OptionID AS [OptionID]
			, ISNULL(Configs.ConfigName,'None') AS [ConfigName]
			, CASE 
				WHEN ISNULL(TraceConfigs.IsEnabled,0) = 1 AND ISNULL(Configs.IsEnabled,0) = 1 THEN 'True'
				WHEN ISNULL(TraceConfigs.IsEnabled,0) = 0 OR ISNULL(Configs.IsEnabled,0) = 0 THEN 'False'
			END AS [Enabled]
			, regDBs.DatabaseName AS [DatabaseName]
			, opts.TraceName AS [TraceName]
			, opts.PurgeDays AS [PurgeDays]
			, ISNULL(CAST(opts.QueryRunTime AS VARCHAR(20)),'Not Filtered') AS [QueryRunTimeFilter]
			, ISNULL(CAST(opts.Reads AS VARCHAR(20)),'Not Filtered') AS [ReadsFilter]
			, ISNULL(CAST(opts.Writes AS VARCHAR(20)),'Not Filtered') AS [WritesFilter]
			, diskLoc.FilePath AS [BackupDirectory]
	FROM [Trace].[Options] opts
	INNER JOIN [Trace].[Databases] dbs ON opts.OptionID = dbs.OptionID
	INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON dbs.DatabaseID = regDBs.DatabaseID
	INNER JOIN [Trace].[Configs] TraceConfigs ON opts.OptionID = TraceConfigs.OptionID
	LEFT JOIN [Configuration].[Configs] Configs ON TraceConfigs.ConfigID = Configs.ConfigID
	LEFT JOIN [Configuration].[DiskLocations] diskLoc ON opts.DiskLocationID = diskLoc.DiskLocationID
