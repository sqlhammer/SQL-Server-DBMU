-- =============================================
-- This script is to pull old settings out of the
-- previous version of the Utility database when
-- the rename and rebuild method is used.
-- =============================================

--Version checking
-- -- Every version from 2.0 and on will have the version number stored within it.
-- -- Configuration porting is not supported for versions (1.00.00, 1.00.01, and 1.10.00)
-- -- Version 1.11.00 porting is supported but can only be identified by the table schema since
-- -- no information of versioning is stored within it.

--Reset database context just in case we put code in the post deploy that changes it.
USE [$(DatabaseName)];
GO

--Set version variables
DECLARE @PriorVersion VARCHAR(8)
DECLARE @PriorDatabaseName SYSNAME
DECLARE @CurrentDatabaseName SYSNAME
DECLARE @msg VARCHAR(8000)
--Temp table used to cross into and out of dynamic sql sessions
IF OBJECT_ID('tempdb..##Utility_PriorVersion') IS NOT NULL
	DROP TABLE ##Utility_PriorVersion
CREATE TABLE ##Utility_PriorVersion (PriorVersion VARCHAR(8))

SET @CurrentDatabaseName = '$(DatabaseName)'
SELECT TOP 1 @PriorDatabaseName = NAME FROM sys.databases WHERE NAME LIKE '$(DatabaseName)_auto_bk_%' ORDER BY create_date DESC

--Version 1.11.00
-- -- Check for the lack of the EncryptionKeyID column in the [Backup].[Options] table since there is no information
-- -- stored for version number in this version. In addition, we want to make sure that the Configuration.InformationDetails
-- -- table that shouldn't exist isn't there. In version 1.10.00 and lower the Backup schema did not exist so we also check 
-- -- for the existence of the Backup.Options table to validate that we are in a supported version.
EXEC 
(
	'IF NOT EXISTS
			(SELECT schs.name, objs.name, cols.name
			FROM [' + @PriorDatabaseName + '].sys.columns cols
			INNER JOIN [' + @PriorDatabaseName + '].sys.objects objs ON cols.object_id = objs.object_id
			INNER JOIN [' + @PriorDatabaseName + '].sys.schemas schs ON objs.schema_id = schs.schema_id
			WHERE cols.name = ''EncryptionKeyID''
				AND objs.name = ''Options''
				AND schs.name = ''Backup'') --EncryptionKeyID Column check
		AND NOT EXISTS
			(SELECT schs.name, objs.name
			FROM [' + @PriorDatabaseName + '].sys.objects objs
			INNER JOIN [' + @PriorDatabaseName + '].sys.schemas schs ON objs.schema_id = schs.schema_id
			WHERE objs.name = ''InformationDetails''
				AND schs.name = ''Configuration'') --InformationDetails Table check
		AND EXISTS
			(SELECT schs.name, objs.name
			FROM [' + @PriorDatabaseName + '].sys.objects objs
			INNER JOIN [' + @PriorDatabaseName + '].sys.schemas schs ON objs.schema_id = schs.schema_id
			WHERE objs.name = ''Options''
				AND schs.name = ''Backup'') --Backup.Options Table check
	BEGIN
		INSERT INTO ##Utility_PriorVersion (PriorVersion) VALUES (''1.11.00'')
	END'
);

--Versions 2.00.00 and greater
-- -- This check relies upon the Configuration.InformationDetails table. If this table ever is changed then this
-- -- if will have to be split out into additional conditions for the newer versions that have changed.
EXEC
(
	'IF EXISTS
			(SELECT schs.name, objs.name
			FROM [' + @PriorDatabaseName + '].sys.objects objs
			INNER JOIN [' + @PriorDatabaseName + '].sys.schemas schs ON objs.schema_id = schs.schema_id
			WHERE objs.name = ''InformationDetails''
				AND schs.name = ''Configuration'') --Check for the Configuration.InformationDetails table
	BEGIN
		INSERT INTO ##Utility_PriorVersion (PriorVersion)
			SELECT Detail
			FROM [' + @PriorDatabaseName + '].Configuration.vwInformationDetails
			WHERE Feature = ''$(DatabaseName)''
				AND InfoType = ''Version''
	END'
);

/************************************************************************************************/
--Set PriorVersion variable
SELECT @PriorVersion = (SELECT PriorVersion FROM ##Utility_PriorVersion)

--Garbage collection for Prior Version temp table
IF OBJECT_ID('tempdb..##Utility_PriorVersion') IS NOT NULL
	DROP TABLE ##Utility_PriorVersion

--Report that the version was not properly detected.
IF @PriorVersion IS NULL
BEGIN
	SET @msg = 'After version evaluation tree was traversed @PriorVersion was still NULL. This version of the ' + 
		'Utility database might not be supported for automated configuration setting. Population of prior ' + 
		'version settings has been skipped. Please inform the change requester of this.'
	RAISERROR(@msg,16,1)
	GOTO SkipConfigurationPullFromPriorVersion
END
/************************************************************************************************/



/************************************************************************************************/
/************************************************************************************************/
--Begin IF tree for version selection
/************************************************************************************************/
/************************************************************************************************/



IF @PriorVersion = '1.11.00'
BEGIN
	BEGIN TRANSACTION
	
	/************************************************************************************************/
	--Begin setting Configuration feature data
	/************************************************************************************************/
	
	-- -- Verify RegisteredDatabases has been updated
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_RegisteredDatabases') IS NOT NULL
		DROP TABLE ##PriorDatabase_RegisteredDatabases
	EXEC ('SELECT * INTO ##PriorDatabase_RegisteredDatabases FROM [' + @PriorDatabaseName + '].[Configuration].[RegisteredDatabases];')

	-- -- This part of the script assumes that the [Configuration].[RegisteredDatabases] table is empty
	IF EXISTS (SELECT TOP 1 DatabaseID FROM [Configuration].[RegisteredDatabases])
		RAISERROR('Data was detected in [Configuration].[RegisteredDatabases]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	--Ensure that this table is dumped incase the usp_RefreshRegisteredDatabases has run since the initial deploy.
	--DELETE FROM [Configuration].[RegisteredDatabases]

	SET IDENTITY_INSERT [Configuration].[RegisteredDatabases] ON
  
	INSERT INTO [Configuration].[RegisteredDatabases] (DatabaseID, DatabaseName)
		SELECT DatabaseID, DatabaseName
		FROM ##PriorDatabase_RegisteredDatabases
  
	SET IDENTITY_INSERT [Configuration].[RegisteredDatabases] OFF  

	-- -- Backup.Databases garbage collection
	DROP TABLE ##PriorDatabase_RegisteredDatabases

	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Configuration_DiskLocations') IS NOT NULL
		DROP TABLE ##PriorDatabase_Configuration_DiskLocations
	EXEC ('SELECT * INTO ##PriorDatabase_Configuration_DiskLocations FROM [' + @PriorDatabaseName + '].[Configuration].[DiskLocations];')

	-- -- INSERT Disk Locations
	INSERT INTO [Configuration].[DiskLocations]	( [FileExtension], [FilePath] )
		SELECT pCD.[FileExtension], pCD.[FilePath]
		FROM ##PriorDatabase_Configuration_DiskLocations pCD
		LEFT JOIN [Configuration].[DiskLocations] cCD ON cCD.FileExtension = pCD.FileExtension AND cCD.FilePath = pCD.FILEPATH
		WHERE cCD.DiskLocationID IS NULL   

	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Configuration_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_Configuration_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_Configuration_Configs FROM [' + @PriorDatabaseName + '].[Configuration].[Configs];')

	-- -- INSERT Configs
	-- -- This part of the script assumes that the [Backup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 ConfigID FROM [Configuration].[Configs])
		RAISERROR('Data was detected in [Configuration].[Configs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Configuration].[Configs] ON
  
	INSERT INTO [Configuration].[Configs] (ConfigID, ConfigName, ConfigDesc, IsEnabled)
		SELECT ConfigID, ConfigName, ConfigDesc, IsEnabled
		FROM ##PriorDatabase_Configuration_Configs

	SET IDENTITY_INSERT [Configuration].[Configs] OFF  

	/************************************************************************************************/
	--Begin setting Backup feature configurations
	/************************************************************************************************/
	
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Backup_Options') IS NOT NULL
		DROP TABLE ##PriorDatabase_Backup_Options  
	IF OBJECT_ID('tempdb..##PriorDatabase_Lookup_BackupTypes') IS NOT NULL
		DROP TABLE ##PriorDatabase_Lookup_BackupTypes
	EXEC ('SELECT * INTO ##PriorDatabase_Backup_Options FROM [' + @PriorDatabaseName + '].[Backup].[Options];')
	EXEC ('SELECT * INTO ##PriorDatabase_Lookup_BackupTypes FROM [' + @PriorDatabaseName + '].[Lookup].[BackupTypes];')
	
	-- -- Match up BackupTypes
	UPDATE ##PriorDatabase_Backup_Options
	SET BackupTypeID = (SELECT cBT.backuptypeid
						FROM ##PriorDatabase_Lookup_BackupTypes pBT
						INNER JOIN ##PriorDatabase_Backup_Options pBO ON pBT.backuptypeid = pBO.backuptypeid
						INNER JOIN [Lookup].[BackupTypes] cBT ON cBT.BackupTypeDesc = pBT.BackupTypeDesc
						WHERE pBO.OptionID = ##PriorDatabase_Backup_Options.OptionID)

	-- -- Lookup.BackupTypes garbage collection
	DROP TABLE ##PriorDatabase_Lookup_BackupTypes

	-- -- Match up Disk Locations
	UPDATE ##PriorDatabase_Backup_Options
	SET DiskLocationID = (SELECT cCD.DiskLocationID
						FROM ##PriorDatabase_Configuration_DiskLocations pCD
						INNER JOIN ##PriorDatabase_Backup_Options pBO ON pCD.DiskLocationID = pBO.DiskLocationID
						INNER JOIN [Configuration].[DiskLocations] cCD ON cCD.FileExtension = pCD.FileExtension AND cCD.FilePath = pCD.FilePath
						WHERE pBO.OptionID = ##PriorDatabase_Backup_Options.OptionID)
	
	-- -- INSERT Backup.Options
	-- -- This part of the script assumes that the [Backup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 OptionID FROM [Backup].[Options])
		RAISERROR('Data was detected in [Backup].[Options]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Backup].[Options] ON
	
	INSERT INTO [Backup].[Options] (
									[OptionID] ,[BackupTypeID] ,[DiskLocationID] ,[EncryptionKeyID] ,[Verify]
								   ,[CHECKSUM] ,[UseCompression] ,[FileCount] ,[BufferCount] ,[MaxTransSize]
								   ,[FrequencyType] ,[FrequencyInterval],[FrequencySubDayType] ,[FrequencySubDayInterval]
								   ,[FrequencyRelativeInterval] ,[FrequencyRecurranceFactor] ,[StartTime] ,[EndTime]
								   )
			SELECT [OptionID] ,[BackupTypeID] ,[DiskLocationID] ,NULL ,[Verify] ,0 ,[UseCompression] ,NULL ,NULL
				,NULL ,[FrequencyType] ,
				CASE	WHEN temp_bopts.[FrequencyType] = 4 AND temp_bopts.[FrequencyInterval] = 0 THEN 1 
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 1 THEN 1
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 2 THEN 2
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 3 THEN 4
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 4 THEN 8
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 5 THEN 16
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 6 THEN 32
						WHEN (temp_bopts.[FrequencyType] = 8 OR temp_bopts.[FrequencyType] = 32) AND temp_bopts.[FrequencyInterval] = 7 THEN 64
						ELSE temp_bopts.[FrequencyInterval]
				END AS [FrequencyInterval] 
				,[FrequencySubDayType] ,[FrequencySubDayInterval]
				,[FrequencyRelativeInterval] ,[FrequencyRecurranceFactor] ,[StartTime] ,[EndTime]
			FROM ##PriorDatabase_Backup_Options temp_bopts

	SET IDENTITY_INSERT [Backup].[Options] OFF
  
	-- -- Backup.Options garbage collection
	DROP TABLE ##PriorDatabase_Backup_Options  

	-- -- INSERT [Backup].[Databases]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Backup_Databases') IS NOT NULL
		DROP TABLE ##PriorDatabase_Backup_Databases
	EXEC ('SELECT * INTO ##PriorDatabase_Backup_Databases FROM [' + @PriorDatabaseName + '].[Backup].[Databases];')

	-- -- This part of the script assumes that the [Backup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 BackupDatabaseID FROM [Backup].[Databases])
		RAISERROR('Data was detected in [Backup].[Databases]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Backup].[Databases] ON
  
	INSERT INTO [Backup].[Databases] (BackupDatabaseID, DatabaseID, OptionID)
		SELECT BackupDatabaseID, DatabaseID, OptionID
		FROM ##PriorDatabase_Backup_Databases
  
	SET IDENTITY_INSERT [Backup].[Databases] OFF  

	-- -- Backup.Databases garbage collection
	DROP TABLE ##PriorDatabase_Backup_Databases

	-- -- INSERT [Backup].[Configs]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Backup_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_Backup_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_Backup_Configs FROM [' + @PriorDatabaseName + '].[Backup].[Configs];')

	-- -- This part of the script assumes that the [Backup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 BackupConfigID FROM [Backup].[Configs])
		RAISERROR('Data was detected in [Backup].[Configs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Backup].[Configs] ON
  
	INSERT INTO [Backup].[Configs] (BackupConfigID, ConfigID, OptionID, IsEnabled)
		SELECT BackupConfigID, ConfigID, OptionID, IsEnabled
		FROM ##PriorDatabase_Backup_Configs
  
	SET IDENTITY_INSERT [Backup].[Configs] OFF  

	-- -- Backup.Configs garbage collection
	DROP TABLE ##PriorDatabase_Backup_Configs

	-- -- INSERT [Backup].[SpawnedJobs]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Backup_SpawnedJobs') IS NOT NULL
		DROP TABLE ##PriorDatabase_Backup_SpawnedJobs
	EXEC ('SELECT * INTO ##PriorDatabase_Backup_SpawnedJobs FROM [' + @PriorDatabaseName + '].[Backup].[SpawnedJobs];')

	-- -- This part of the script assumes that the [Backup].[SpawnedJobs] table is empty
	IF EXISTS (SELECT TOP 1 TrackingID FROM [Backup].[SpawnedJobs])
		RAISERROR('Data was detected in [Backup].[SpawnedJobs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Backup].[SpawnedJobs] ON
  
	INSERT INTO [Backup].[SpawnedJobs] (TrackingID, JobID, JobName, BackupDatabaseID)
		SELECT TrackingID, JobID, JobName, BackupDatabaseID
		FROM ##PriorDatabase_Backup_SpawnedJobs
  
	SET IDENTITY_INSERT [Backup].[SpawnedJobs] OFF  

	-- -- Backup.SpawnedJobs garbage collection
	DROP TABLE ##PriorDatabase_Backup_SpawnedJobs

	/************************************************************************************************/
	--Begin setting Disk Cleanup feature configurations
	/************************************************************************************************/
	
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_DiskCleanup_Options') IS NOT NULL
		DROP TABLE ##PriorDatabase_DiskCleanup_Options  
	IF OBJECT_ID('tempdb..##PriorDatabase_Lookup_PurgeTypes') IS NOT NULL
		DROP TABLE ##PriorDatabase_Lookup_PurgeTypes
	EXEC ('SELECT * INTO ##PriorDatabase_DiskCleanup_Options FROM [' + @PriorDatabaseName + '].[DiskCleanup].[Options];')
	EXEC ('SELECT * INTO ##PriorDatabase_Lookup_PurgeTypes FROM [' + @PriorDatabaseName + '].[Lookup].[PurgeTypes];')
	
	-- -- Match up PurgeTypes
	UPDATE ##PriorDatabase_DiskCleanup_Options
	SET PurgeTypeID = (SELECT cPT.PurgeTypeID
						FROM ##PriorDatabase_Lookup_PurgeTypes pPT
						INNER JOIN ##PriorDatabase_DiskCleanup_Options pDCO ON pPT.PurgeTypeID = pDCO.PurgeTypeID
						INNER JOIN [Lookup].[PurgeTypes] cPT ON cPT.PurgeTypeDesc = pPT.PurgeTypeDesc
						WHERE pDCO.OptionID = ##PriorDatabase_DiskCleanup_Options.OptionID)

	-- -- Lookup.PurgeTypes garbage collection
	DROP TABLE ##PriorDatabase_Lookup_PurgeTypes

	-- -- Match up Disk Locations
	UPDATE ##PriorDatabase_DiskCleanup_Options
	SET DiskLocationID = (SELECT cCD.DiskLocationID
						FROM ##PriorDatabase_Configuration_DiskLocations pCD
						INNER JOIN ##PriorDatabase_DiskCleanup_Options pDCO ON pCD.DiskLocationID = pDCO.DiskLocationID
						INNER JOIN [Configuration].[DiskLocations] cCD ON cCD.FileExtension = pCD.FileExtension AND cCD.FilePath = pCD.FilePath
						WHERE pDCO.OptionID = ##PriorDatabase_DiskCleanup_Options.OptionID)

	-- -- INSERT DiskCleanup.Options
	-- -- This part of the script assumes that the [DiskCleanup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 OptionID FROM [DiskCleanup].[Options])
		RAISERROR('Data was detected in [DiskCleanup].[Options]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [DiskCleanup].[Options] ON
	
	INSERT INTO [DiskCleanup].[Options] ( [OptionID] ,[DiskLocationID] ,[PurgeValue] ,[PurgeTypeID] )
			SELECT [OptionID] ,[DiskLocationID] ,[PurgeValue] ,[PurgeTypeID]
			FROM ##PriorDatabase_DiskCleanup_Options

	SET IDENTITY_INSERT [DiskCleanup].[Options] OFF
  
	-- -- DiskCleanup.Options garbage collection
	DROP TABLE ##PriorDatabase_DiskCleanup_Options  

	-- -- INSERT [DiskCleanup].[Databases]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_DiskCleanup_Databases') IS NOT NULL
		DROP TABLE ##PriorDatabase_DiskCleanup_Databases
	EXEC ('SELECT * INTO ##PriorDatabase_DiskCleanup_Databases FROM [' + @PriorDatabaseName + '].[DiskCleanup].[Databases];')

	-- -- This part of the script assumes that the [DiskCleanup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 DiskCleanupDatabaseID FROM [DiskCleanup].[Databases])
		RAISERROR('Data was detected in [DiskCleanup].[Databases]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [DiskCleanup].[Databases] ON
  
	INSERT INTO [DiskCleanup].[Databases] (DiskCleanupDatabaseID, DatabaseID, OptionID)
		SELECT DiskCleanupDatabaseID, DatabaseID, OptionID
		FROM ##PriorDatabase_DiskCleanup_Databases
  
	SET IDENTITY_INSERT [DiskCleanup].[Databases] OFF  

	-- -- DiskCleanup.Databases garbage collection
	DROP TABLE ##PriorDatabase_DiskCleanup_Databases

	-- -- INSERT [DiskCleanup].[Configs]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_DiskCleanup_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_DiskCleanup_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_DiskCleanup_Configs FROM [' + @PriorDatabaseName + '].[DiskCleanup].[Configs];')

	-- -- This part of the script assumes that the [DiskCleanup].[Options] table is empty
	IF EXISTS (SELECT TOP 1 DiskCleanupConfigID FROM [DiskCleanup].[Configs])
		RAISERROR('Data was detected in [DiskCleanup].[Configs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [DiskCleanup].[Configs] ON
  
	INSERT INTO [DiskCleanup].[Configs] (DiskCleanupConfigID, ConfigID, OptionID, IsEnabled)
		SELECT DiskCleanupConfigID, ConfigID, OptionID, IsEnabled
		FROM ##PriorDatabase_DiskCleanup_Configs
  
	SET IDENTITY_INSERT [DiskCleanup].[Configs] OFF  

	-- -- DiskCleanup.Configs garbage collection
	DROP TABLE ##PriorDatabase_DiskCleanup_Configs
	
	/************************************************************************************************/
	--Begin setting Index Maintenance feature configurations
	/************************************************************************************************/
	
	-- -- INSERT IndexMaint.Options
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_IndexMaint_Options') IS NOT NULL
		DROP TABLE ##PriorDatabase_IndexMaint_Options 
	EXEC ('SELECT * INTO ##PriorDatabase_IndexMaint_Options FROM [' + @PriorDatabaseName + '].[IndexMaint].[Options];')
		
	-- -- This part of the script assumes that the [IndexMaint].[Options] table is empty
	IF EXISTS (SELECT TOP 1 OptionID FROM [IndexMaint].[Options])
		RAISERROR('Data was detected in [IndexMaint].[Options]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [IndexMaint].[Options] ON
	
	INSERT INTO [IndexMaint].[Options] ( [OptionID] ,[FragLimit] ,[PageSpaceLimit] ,[StatisticsExpiration] ,[ExecuteWindowEnd] ,[MaxDefrag] ,[CheckPeriodicity] )
			SELECT [OptionID] , [LogicalFrag] ,[ScanDensity] ,14 --14 days selected as the default statistics expiration setting.
				,[ExecuteWindowEnd] ,[MaxDefrag] ,[CheckPeriodicity]
			FROM ##PriorDatabase_IndexMaint_Options

	SET IDENTITY_INSERT [IndexMaint].[Options] OFF
  
	-- -- IndexMaint.Options garbage collection
	DROP TABLE ##PriorDatabase_IndexMaint_Options  

	-- -- INSERT [IndexMaint].[Databases]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_IndexMaint_Databases') IS NOT NULL
		DROP TABLE ##PriorDatabase_IndexMaint_Databases
	EXEC ('SELECT * INTO ##PriorDatabase_IndexMaint_Databases FROM [' + @PriorDatabaseName + '].[IndexMaint].[Databases];')

	-- -- This part of the script assumes that the [IndexMaint].[Options] table is empty
	IF EXISTS (SELECT TOP 1 IndexDatabaseID FROM [IndexMaint].[Databases])
		RAISERROR('Data was detected in [IndexMaint].[Databases]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [IndexMaint].[Databases] ON
  
	INSERT INTO [IndexMaint].[Databases] (IndexDatabaseID, DatabaseID, OptionID)
		SELECT IndexDatabaseID, DatabaseID, OptionID
		FROM ##PriorDatabase_IndexMaint_Databases
  
	SET IDENTITY_INSERT [IndexMaint].[Databases] OFF  

	-- -- IndexMaint.Databases garbage collection
	DROP TABLE ##PriorDatabase_IndexMaint_Databases

	-- -- INSERT [IndexMaint].[Configs]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_IndexMaint_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_IndexMaint_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_IndexMaint_Configs FROM [' + @PriorDatabaseName + '].[IndexMaint].[Configs];')

	-- -- This part of the script assumes that the [IndexMaint].[Options] table is empty
	IF EXISTS (SELECT TOP 1 IndexMaintConfigID FROM [IndexMaint].[Configs])
		RAISERROR('Data was detected in [IndexMaint].[Configs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [IndexMaint].[Configs] ON
  
	INSERT INTO [IndexMaint].[Configs] (IndexMaintConfigID, ConfigID, OptionID, IsEnabled)
		SELECT IndexMaintConfigID, ConfigID, OptionID, IsEnabled
		FROM ##PriorDatabase_IndexMaint_Configs
  
	SET IDENTITY_INSERT [IndexMaint].[Configs] OFF  

	-- -- IndexMaint.Configs garbage collection
	DROP TABLE ##PriorDatabase_IndexMaint_Configs
	
	/************************************************************************************************/
	--Begin setting Query Trace feature configurations
	/************************************************************************************************/
	
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Trace_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_Trace_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_Trace_Configs FROM [' + @PriorDatabaseName + '].[Trace].[Configs];')

	-- Set all traces to disabled now that we've pre-recorded their status
	EXEC ('UPDATE [' + @PriorDatabaseName + '].[Trace].[Configs] SET [IsEnabled] = 0;')
	-- Stop all traces
	EXEC ('EXEC [' + @PriorDatabaseName + '].[Trace].[usp_PopulateCurrentTraceTables];')

	-- -- INSERT Trace.Options
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Trace_Options') IS NOT NULL
		DROP TABLE ##PriorDatabase_Trace_Configs 
	EXEC ('SELECT * INTO ##PriorDatabase_Trace_Options FROM [' + @PriorDatabaseName + '].[Trace].[Options];')
		
	-- -- This part of the script assumes that the [Trace].[Options] table is empty
	IF EXISTS (SELECT TOP 1 OptionID FROM [Trace].[Options])
		RAISERROR('Data was detected in [Trace].[Options]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Trace].[Options] ON
	
	INSERT INTO [Trace].[Options] ( [OptionID] ,[DiskLocationID] ,[TraceName] 
									,[PurgeDays] ,[MaxFileSize]
									,[QueryRunTime] ,[Reads] ,[Writes] )
			SELECT [OptionID] ,[DiskLocationID] ,[TraceName] 
				,[PurgeDays] ,[MaxFileSize]
				,[QueryRunTime] ,[Reads] ,[Writes]
			FROM ##PriorDatabase_Trace_Options

	SET IDENTITY_INSERT [Trace].[Options] OFF
  
	-- -- Match up Disk Locations
	UPDATE ##PriorDatabase_Trace_Options
	SET DiskLocationID = (SELECT cCD.DiskLocationID
						FROM ##PriorDatabase_Configuration_DiskLocations pCD
						INNER JOIN ##PriorDatabase_Trace_Options pTO ON pCD.DiskLocationID = pTO.DiskLocationID
						INNER JOIN [Configuration].[DiskLocations] cCD ON cCD.FileExtension = pCD.FileExtension AND cCD.FilePath = pCD.FilePath
						WHERE pTO.OptionID = ##PriorDatabase_Trace_Options.OptionID)

	-- -- Trace.Options garbage collection
	DROP TABLE ##PriorDatabase_Trace_Options  

	-- -- INSERT [Trace].[Databases]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Trace_Databases') IS NOT NULL
		DROP TABLE ##PriorDatabase_Trace_Databases
	EXEC ('SELECT * INTO ##PriorDatabase_Trace_Databases FROM [' + @PriorDatabaseName + '].[Trace].[Databases];')

	-- -- This part of the script assumes that the [Trace].[Options] table is empty
	IF EXISTS (SELECT TOP 1 TraceDatabaseID FROM [Trace].[Databases])
		RAISERROR('Data was detected in [Trace].[Databases]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Trace].[Databases] ON
  
	INSERT INTO [Trace].[Databases] (TraceDatabaseID, DatabaseID, OptionID)
		SELECT TraceDatabaseID, DatabaseID, OptionID
		FROM ##PriorDatabase_Trace_Databases
  
	SET IDENTITY_INSERT [Trace].[Databases] OFF  

	-- -- Trace.Databases garbage collection
	DROP TABLE ##PriorDatabase_Trace_Databases

	-- -- INSERT [Trace].[Configs]
	-- Pull tables into global temp tables to avoid using dynamic SQL for everything
	IF OBJECT_ID('tempdb..##PriorDatabase_Trace_Configs') IS NOT NULL
		DROP TABLE ##PriorDatabase_Trace_Configs
	EXEC ('SELECT * INTO ##PriorDatabase_Trace_Configs FROM [' + @PriorDatabaseName + '].[Trace].[Configs];')

	-- -- This part of the script assumes that the [Trace].[Options] table is empty
	IF EXISTS (SELECT TOP 1 TraceConfigID FROM [Trace].[Configs])
		RAISERROR('Data was detected in [Trace].[Configs]. If a primary key violation error follows this, then the existence of data were the table is assumed to be empty could be the problem.',10,1) WITH NOWAIT

	SET IDENTITY_INSERT [Trace].[Configs] ON
  
	INSERT INTO [Trace].[Configs] (TraceConfigID, ConfigID, OptionID, IsEnabled)
		SELECT TraceConfigID, ConfigID, OptionID, IsEnabled
		FROM ##PriorDatabase_Trace_Configs
  
	SET IDENTITY_INSERT [Trace].[Configs] OFF  

	-- -- Trace.Configs garbage collection
	DROP TABLE ##PriorDatabase_Trace_Configs
	-- -- Configuration.DiskLocations garbage collection
	DROP TABLE ##PriorDatabase_Configuration_DiskLocations
	
	--Setup Registered Databases
	--EXEC Utility.Configuration.usp_RefreshRegisteredDatabases @Purge = 1
	--EXEC Utility.Configuration.usp_RefreshRegisteredDatabases @Purge = 0
	
	IF @@TRANCOUNT > 0
		COMMIT
	
END --Version 1.11.00 - END IF

/************************************************************************************************/
/************************************************************************************************/
--End IF tree for version selection
/************************************************************************************************/
/************************************************************************************************/

--Anchor for skipping the config pull from prior version
SkipConfigurationPullFromPriorVersion:
