CREATE VIEW [IndexMaint].[vwGetIndexMaintPlan]
AS 
	SELECT  opts.OptionID AS [OptionID]
			, ISNULL(Configs.ConfigName,'None') AS [ConfigName]
			, CASE 
				WHEN ISNULL(indexConfig.IsEnabled,0) = 1 AND ISNULL(Configs.IsEnabled,0) = 1 THEN 'True'
				WHEN ISNULL(indexConfig.IsEnabled,0) = 0 OR ISNULL(Configs.IsEnabled,0) = 0 THEN 'False'
			END AS [Enabled]
			, regDBs.DatabaseName AS [DatabaseName]
			, (SELECT ISNULL(stuff(stuff(Right('00' + cast(Skeds.active_start_time as varchar(6)),6),3,0,':'),6,0,':'),'00:00:00') 
				FROM msdb..sysjobs Jobs
				INNER JOIN msdb..sysjobschedules Jskeds ON Jobs.job_id = Jskeds.job_id
				INNER JOIN msdb..sysschedules Skeds ON Jskeds.schedule_id = Skeds.schedule_id
				WHERE Jobs.name = 'Utility - Selective Reindex All Databases')
			AS [StartTime]
			, CASE (ISNULL(CAST(opts.ExecuteWindowEnd AS VARCHAR(2)),'') + ':00:00')
				WHEN ':00:00' THEN 'None'
				ELSE CAST(opts.ExecuteWindowEnd AS VARCHAR(2))
			END AS [ExecutionWindowEndTime]
			, opts.FragLimit AS [FragLimit]
			, opts.PageSpaceLimit AS [PageSpaceLimit]
			, opts.MaxDefrag AS [MaxFragToDefrag]
			, ('Every ' + ISNULL(CAST(opts.CheckPeriodicity AS VARCHAR(10)),'1') + ' day(s)') AS [CheckPeriodicity]
	FROM [IndexMaint].[Options] opts
	INNER JOIN [IndexMaint].[Databases] dbs ON opts.OptionID = dbs.OptionID
	INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON dbs.DatabaseID = regDBs.DatabaseID
	LEFT JOIN [IndexMaint].[Configs] indexConfig ON indexConfig.OptionID = opts.OptionID
	LEFT JOIN [Configuration].[Configs] Configs ON Configs.ConfigID = indexConfig.ConfigID


