/*
**********************************************************
		DATABASE MAINTENANCE UTILITY RELEASE 1.11
						TEST CASE(S)
**********************************************************
AUTHOR:				Derik Hammer
DATE OF CREATION:	5/4/2012
DESCRIPTION:		The follow scripts will create a testing
	configuration for the Backup, Trace, DiskCleanup, and 
	Index Maintenance features.
	
STEPS:	
1. (Optional) Set query window to text results.			
2. Run this script to populate all feature options.
3. Verify debug print statements and validation selects.
4. Run usp_Alter***Option for each feature with multiple parameters.
5. Run usp_Drop***Option for each feature.
6. Run usp_DropConfig for each configuration created.
*/
/********************************/
/*			Pre-setup			*/
/********************************/
SET XACT_ABORT ON;

USE [Utility];
GO

DECLARE @OptionID INT
DECLARE @FileDirectory VARCHAR(MAX)
DECLARE @FileExtension CHAR(3)
DECLARE @Type VARCHAR(50)
DECLARE @Databases VARCHAR(MAX)
DECLARE @freq_type INT
DECLARE @freq_interval INT
DECLARE @freq_subday_type INT
DECLARE @freq_subday_interval INT
DECLARE @freq_relative_interval INT
DECLARE @freq_recurrence_factor INT
DECLARE @active_start_time INT
DECLARE @active_end_time INT
DECLARE @ConfigID INT
DECLARE @PurgeValue INT
DECLARE @ScanDensity INT
DECLARE @LogicalFrag INT
DECLARE @ExtentFrag INT
DECLARE @ExecuteWindowEnd INT
DECLARE @MaxDefrag INT
DECLARE @CheckPeriodicity INT

PRINT '/*****************************************/'
PRINT '/*			Backup Test Case			 */'
PRINT '/*****************************************/'
PRINT ''
PRINT ''
BEGIN TRANSACTION
--create option
SET @FileDirectory = N'\\sit-qa-dbbackups.libtax.com\SIT-QA-Databases\V-DEV-DB-008'
SET @Type = 'full'
SET @Databases = N'Utility'

EXEC [Backup].[usp_CreateBackupOption] 
	@debug = 1,
	@BackupFileDirectory = @FileDirectory,
	@BackupType = @Type,
	@Verify = 1,
	@UseCompression = 1,
	@ScheduleType = 'daily',
	@ScheduleDay = NULL,
	@ScheduleStartTime = 10000,
	@ScheduleEndTime = NULL,
	@BackupDatabases = @Databases
	
--create umbrella config
EXEC [Configuration].[usp_CreateConfig]
	@debug = 1,
	@Name = 'Backups',
	@Desc = 'This is an umbrella configuration setup to only test the backup feature.',
	@IsEnabled = 1

--associate option to config
SELECT  @freq_type=[f_Type]
	  , @freq_interval=[f_Interval]
	  , @freq_subday_type=[f_SubDay_Type]
	  , @freq_subday_interval=[f_SubDay_Interval]
	  , @freq_relative_interval=[f_Relative_Interval]
	  , @freq_recurrence_factor=[f_Recurrence_Factor]
	  , @active_start_time=[StartTime]
	  , @active_end_time=[EndTime]
FROM [dbo].[udf_TranslateJobSchedule]('daily',NULL,10000,NULL)

SELECT @OptionID = Opt.[OptionID]
FROM [Backup].[Options] Opt
INNER JOIN [Configuration].[DiskLocations] DL ON Opt.[DiskLocationID] = DL.[DiskLocationID]
INNER JOIN [Lookup].[BackupTypes] BT ON [BT].[BackupTypeID] = [Opt].[BackupTypeID]
WHERE DL.[FilePath] = @FileDirectory
	AND [BT].[BackupTypeDesc] = @Type	
	AND [Opt].[Verify] = 1
	AND [Opt].[UseCompression] = 1
	AND @freq_type = [Opt].[FrequencyType]
	AND @freq_interval = [Opt].[FrequencyInterval]
	AND @freq_subday_type = [Opt].[FrequencySubDayType]
	AND @freq_subday_interval = [Opt].[FrequencySubDayInterval]
	AND @freq_relative_interval = [Opt].[FrequencyRelativeInterval]
	AND @freq_recurrence_factor = [Opt].[FrequencyRecurranceFactor]
	AND @active_start_time = [Opt].[StartTime]
	AND @active_end_time = [Opt].[EndTime]
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'Backups'

EXEC [Backup].[usp_BackupOptionAssociation]
	@debug = 1,
	@BackupOptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0

--Validate changes
SELECT * FROM [Utility].[Backup].[Options]
SELECT * FROM [Utility].[Backup].[Databases]
SELECT * FROM [Utility].[Backup].[Configs]
SELECT * FROM [Utility].[Configuration].[DiskLocations]
SELECT * FROM [Utility].[Configuration].[Configs]
	
COMMIT

PRINT ''
PRINT ''
PRINT '/*************************************/'
PRINT '/*			Trace Test Case			 */'
PRINT '/*************************************/'
PRINT ''
PRINT ''
USE [Utility];

BEGIN TRANSACTION

SET @FileDirectory = N'C:\Utility_Trace'
SET @Databases = N'Utility'

--create option [query]
EXEC [Trace].[usp_CreateTraceOption]
	@debug = 1,
	@FileDirectory = @FileDirectory,
	@TraceName = 'SmokeTestQuery',
	@PurgeDays = 2,
	@MaxFileSize = 250,
	@QueryRunTime  = 1000000,
	@Reads  = NULL,
	@Writes  = NULL,
	@Databases = @Databases
	
--create option [reads]
EXEC [Trace].[usp_CreateTraceOption]
	@debug = 1,
	@FileDirectory = @FileDirectory,
	@TraceName = 'SmokeTestReads',
	@PurgeDays = 2,
	@MaxFileSize = 250,
	@QueryRunTime  = NULL,
	@Reads  = 2000,
	@Writes  = NULL,
	@Databases = @Databases
	
--create option [writes]
EXEC [Trace].[usp_CreateTraceOption]
	@debug = 1,
	@FileDirectory = @FileDirectory,
	@TraceName = 'SmokeTestWrites',
	@PurgeDays = 2,
	@MaxFileSize = 250,
	@QueryRunTime  = NULL,
	@Reads  = NULL,
	@Writes  = 2000,
	@Databases = @Databases
	
--create umbrella config
EXEC [Configuration].[usp_CreateConfig]
	@debug = 1,
	@Name = 'Traces',
	@Desc = 'This is an umbrella configuration setup to only test the trace feature.',
	@IsEnabled = 1
	
--associate option to config
SELECT @OptionID = Opt.[OptionID]
FROM [Trace].[Options] Opt
WHERE [Opt].[TraceName] = 'SmokeTestWrites'
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'Traces'

EXEC [Trace].[usp_TraceOptionAssociation]
	@debug = 1,
	@OptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0

--associate option to config
SELECT @OptionID = Opt.[OptionID]
FROM [Trace].[Options] Opt
WHERE [Opt].[TraceName] = 'SmokeTestReads'
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'Traces'

EXEC [Trace].[usp_TraceOptionAssociation]
	@debug = 1,
	@OptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0
	
--associate option to config
SELECT @OptionID = Opt.[OptionID]
FROM [Trace].[Options] Opt
WHERE [Opt].[TraceName] = 'SmokeTestQuery'
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'Traces'

EXEC [Trace].[usp_TraceOptionAssociation]
	@debug = 1,
	@OptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0
	
--Populate trace tables
EXEC [Trace].[usp_PopulateCurrentTraceTables] @debug = 1

--Validate changes
SELECT * FROM [Utility].[Trace].[Options]
SELECT * FROM [Utility].[Trace].[Databases]
SELECT * FROM [Utility].[Trace].[Configs]
SELECT * FROM [Utility].[Configuration].[DiskLocations]
SELECT * FROM [Utility].[Trace].[Tables]
SELECT * FROM [Utility].[Configuration].[Configs]
SELECT * FROM [sys].[fn_trace_getinfo](0)

COMMIT

PRINT ''
PRINT ''
PRINT '/*********************************************/'
PRINT '/*			Disk Cleanup Test Case			 */'
PRINT '/*********************************************/'
PRINT ''
PRINT ''

USE [Utility];

BEGIN TRANSACTION

SET @FileDirectory = N'\\sit-qa-dbbackups.libtax.com\SIT-QA-Databases\V-DEV-DB-008\Utility'
SET @FileExtension = 'bak'
SET @Databases = N'Utility'
SET @Type = 'PURGE by number of files'
SET @PurgeValue = 2

--create option
EXEC [DiskCleanup].[usp_CreateDiskCleanupOption]
	@debug = 1,
	@FileDirectory = @FileDirectory,
	@FileExtension = @FileExtension,
	@PurgeType = @Type,
	@PurgeValue = @PurgeValue,
	@Databases = @Databases

--create umbrella config
EXEC [Configuration].[usp_CreateConfig]
	@debug = 1,
	@Name = 'DiskCleanup',
	@Desc = 'This is an umbrella configuration setup to only test the disk cleanup feature.',
	@IsEnabled = 1

--associate option to config
SELECT @OptionID = Opt.[OptionID]
FROM [DiskCleanup].[Options] Opt
INNER JOIN [Configuration].[DiskLocations] DL ON Opt.[DiskLocationID] = DL.[DiskLocationID]
INNER JOIN [Lookup].[PurgeTypes] PType ON [PType].[PurgeTypeID] = [Opt].[PurgeTypeID]
WHERE DL.[FilePath] = @FileDirectory
	AND DL.[FileExtension] = @FileExtension
	AND [PType].[PurgeTypeDesc] = @Type
	AND [Opt].[PurgeValue] = @PurgeValue
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'DiskCleanup'

EXEC [DiskCleanup].[usp_DiskCleanupOptionAssociation]
	@debug = 1,
	@OptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0

--Validate changes
SELECT * FROM [Utility].[DiskCleanup].[Options]
SELECT * FROM [Utility].[DiskCleanup].[Databases]
SELECT * FROM [Utility].[DiskCleanup].[Configs]
SELECT * FROM [Utility].[Configuration].[DiskLocations]
SELECT * FROM [Utility].[Configuration].[Configs]
	
COMMIT

PRINT ''
PRINT ''
PRINT '/*********************************************/'
PRINT '/*			Index Maint	Test Case			 */'
PRINT '/*********************************************/'
PRINT ''
PRINT ''

USE [Utility];

BEGIN TRANSACTION

SET @Databases = N'ALL_DATABASES'
SET @ScanDensity = 80
SET @LogicalFrag = 20
SET @ExtentFrag = 20
SET @ExecuteWindowEnd = NULL
SET @MaxDefrag = 50
SET @CheckPeriodicity = NULL

--create option
EXEC [IndexMaint].[usp_CreateIndexMaintOption]
	@debug = 1,
	@ScanDensity = @ScanDensity,
	@LogicalFrag = @LogicalFrag,
	@ExtentFrag = @ExtentFrag,
	@ExecuteWindowEnd = @ExecuteWindowEnd,
	@MaxDefrag = @MaxDefrag,
	@CheckPeriodicity = @CheckPeriodicity,
	@Databases = @Databases

--create umbrella config
EXEC [Configuration].[usp_CreateConfig]
	@debug = 1,
	@Name = 'IndexMaint',
	@Desc = 'This is an umbrella configuration setup to only test the index maintenance feature.',
	@IsEnabled = 1

--associate option to config
SELECT  @OptionID = Opt.[OptionID]
FROM    [IndexMaint].[Options] Opt
WHERE   [ScanDensity] = @ScanDensity
        AND [LogicalFrag] = @LogicalFrag
        AND [ExtentFrag] = @ExtentFrag
        AND ISNULL(CAST([ExecuteWindowEnd] AS VARCHAR),'NULL') = ISNULL(CAST(@ExecuteWindowEnd AS VARCHAR),'NULL')
        AND [MaxDefrag] = @MaxDefrag
        AND ISNULL(CAST([CheckPeriodicity] AS VARCHAR),'NULL') = ISNULL(CAST(@CheckPeriodicity AS VARCHAR),'NULL')
	
SELECT @ConfigID = [ConfigID]
FROM [Configuration].[Configs]
WHERE [ConfigName] = 'IndexMaint'

EXEC [IndexMaint].[usp_IndexMaintOptionAssociation]
	@debug = 1,
	@OptionID = @OptionID,
	@ConfigID = @ConfigID,
	@IsEnabled = 1,
	@Remove = 0

--Validate changes
SELECT * FROM [Utility].[IndexMaint].[Options]
SELECT * FROM [Utility].[IndexMaint].[Databases]
SELECT * FROM [Utility].[IndexMaint].[Configs]
SELECT * FROM [Utility].[Configuration].[DiskLocations]
SELECT * FROM [Utility].[Configuration].[Configs]
	
COMMIT

SET XACT_ABORT OFF;