CREATE VIEW [DiskCleanup].[vwGetDiskCleanupPlan]
AS 
	SELECT	opts.OptionID AS [OptionID]
			, ISNULL(Configs.ConfigName,'None') AS [ConfigName]
			, CASE 
				WHEN ISNULL(diskConfigs.IsEnabled,0) = 1 AND ISNULL(Configs.IsEnabled,0) = 1 THEN 'True'
				WHEN ISNULL(diskConfigs.IsEnabled,0) = 0 OR ISNULL(Configs.IsEnabled,0) = 0 THEN 'False'
			END AS [Enabled]
			, regDBs.DatabaseName AS [DatabaseName]
			, diskLoc.FileExtension AS [FileExtension]
			, pType.PurgeTypeDesc AS [PurgeTypeDesc]
			, opts.PurgeValue AS [PurgeValue]
			, CASE RIGHT(diskLoc.FILEPATH,1)
				WHEN '\' THEN (diskLoc.FilePath + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(regDBs.DatabaseName,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','') + '\')
				ELSE (diskLoc.FilePath + '\' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(regDBs.DatabaseName,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','') + '\')
			END AS [DirectoryToPurge]
	FROM [DiskCleanup].[Options] opts
	INNER JOIN [Lookup].[PurgeTypes] pType ON opts.PurgeTypeID = pType.PurgeTypeID
	INNER JOIN [DiskCleanup].[Databases] dbs ON opts.OptionID = dbs.OptionID
	INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON dbs.DatabaseID = regDBs.DatabaseID
	INNER JOIN [Configuration].[DiskLocations] diskLoc ON opts.DiskLocationID = diskLoc.DiskLocationID
	LEFT JOIN [DiskCleanup].[Configs] diskConfigs ON diskConfigs.OptionID = opts.OptionID
	LEFT JOIN [Configuration].[Configs] Configs ON Configs.ConfigID = diskConfigs.ConfigID

