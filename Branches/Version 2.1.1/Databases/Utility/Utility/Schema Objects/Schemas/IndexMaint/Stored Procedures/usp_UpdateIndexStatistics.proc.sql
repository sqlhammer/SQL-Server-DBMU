/*					Original Version					*/
/* ------------------------------------------------------
 * Procedure:	dbo.usp_Maintenance_UpdateIndexStatistics
 * Author:		Fred Loud
 * Dates:		Created - 18 Jan 2011
 * Description:	this is a migration of the usp_record_index_fragmentation
 *	- Reindexing is limited to 7 days a week between 0400 and 500 Monday thru Friday. 
 *	- The lowest scan density indexes are reindexed first 
 *	- The entire list of indexes are done on a global round robin per database until complete 
 *		then the round-robin list is re-generated
 * ------------------------------------------------------ */

/*		Modified for Utility Database Interfacing		*/
/*
PROCEDURE:		[IndexMaint].usp_UpdateIndexStatistics
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure is used to populate an index statistics table which will be used for short
				term historical reference (user determined but expected to be less than one week) and
				to support a separate stored procedure which will selectively REORGANIZE or REBUILD indexes
				based on thresholds and the values stored here.
PARAMETERS:		@ForceCheck BIT --Setting this parameter to 1 will force the procedure to rebuild the entire
				index statistics table rather than purging based on user configured values.
*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/01/2012 --	Altered the procedure to use sys.dm_db_index_physical_stats instead of DBCC SHOWCONTIG
									due to the deprecation of DBCC SHOWCONTIG in SQL 2012.

** Derik Hammer ** 10/04/2012 --	Added funtionality which supports updating statistics on indexes that don't get index
									maintenance very often but need accurate statistics.

** Derik Hammer ** 02/07/2013 --	Changed the mode of sys.dm_db_index_physical_stats from DETAILED to SAMPLED. Detailed was
									producing records that could not be corrected by an index REBUILD so SAMPLED is now used
									which mimics the queries run by SSMS 2008 R2 when displaying the fragmentation stats.

** Derik Hammer ** 02/07/2013 --	Changed the @CheckPeriodicity data type from TINYINT to INT so that it can accept negative values.

** Derik Hammer ** 04/11/2013 --	Corrected join condition between configuration.registereddatabases and sys.databases.

** Derik Hammer ** 04/15/2013 --	Moved the population of the @CheckPeriodicity variable into the Option level cursor and out of the 
									database level cursor.
									Removed the setting of @ForceCheck to 1 when @CheckPeriodicity was NULL because it was never being
									reset to 0 in between cursor iterations and putting in a setting line of code would invalidate
									the variable being passed in. Instead I now check for @ForceCheck = 1 and @CheckPeriodicity = NULL.

** Derik Hammer ** 04/30/2013 --	Commented out the WHERE clause section for setting 'Index is Optimal' which would cause index
									REBUILDs in the event that the space used is above the fill factor value. This was causing
									excessive index maintenance operations which resulted in excessive log file usage.

*/

CREATE PROCEDURE [IndexMaint].[usp_UpdateIndexStatistics] 
(
	@ForceCheck	BIT = 0
)
As 
BEGIN
	--Set NOCOUNT to improve performance
	SET NOCOUNT ON;

	--Declare variables
	DECLARE @IndexMaintOptionsID INT
	DECLARE @DatabaseName varchar (128)
	DECLARE @FragLimit tinyint 
	DECLARE @PageSpaceLimit tinyint 
	DECLARE @StatsExpiration tinyint
	DECLARE @CheckPeriodicity int 
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--Initiate cursor loop for all configurations set to ENABLED
	DECLARE EnabledConfigs CURSOR FAST_FORWARD
	FOR
	SELECT imo.[OptionID]
	FROM [IndexMaint].[Options] imo
	INNER JOIN [IndexMaint].[Configs] imc ON imc.[OptionID] = imo.[OptionID]
	INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = imc.[ConfigID]
	WHERE c.[IsEnabled] = 1 AND imc.[IsEnabled] = 1

	OPEN EnabledConfigs
	FETCH NEXT FROM EnabledConfigs INTO @IndexMaintOptionsID

	WHILE ( SELECT  fetch_status FROM    sys.dm_exec_cursors(@@SPID) WHERE   name = 'EnabledConfigs' ) = 0 
	BEGIN
		
		--Populate configurations for thresholds
		SELECT @FragLimit = FragLimit
			, @PageSpaceLimit = PageSpaceLimit
			, @StatsExpiration = StatisticsExpiration
		FROM [IndexMaint].[Options]
		WHERE [OptionID] = @IndexMaintOptionsID

		--Retrieve index check periodicity settings
		SELECT @CheckPeriodicity = Iopt.CheckPeriodicity
		FROM [IndexMaint].[Options] Iopt
		WHERE Iopt.[OptionID] = @IndexMaintOptionsID

		--Initiate cursor loop for all databases associated to the individual @IndexMaintOptionsID
		DECLARE Databases_cur CURSOR FAST_FORWARD
		FOR
		SELECT Rdb.DatabaseName
		FROM [Configuration].RegisteredDatabases Rdb
		INNER JOIN [IndexMaint].[Databases] Idb ON Idb.DatabaseID = Rdb.DatabaseID
		INNER JOIN sys.databases sysDBs ON Rdb.DatabaseName = sysDBs.name
		WHERE Idb.[OptionID] = @IndexMaintOptionsID
			AND sysDBs.[state] = 0 --Ensure the database is ONLINE to continue.

		OPEN Databases_cur
		FETCH NEXT FROM Databases_cur INTO @DatabaseName

		WHILE ( SELECT  fetch_status FROM    sys.dm_exec_cursors(@@SPID) WHERE   name = 'Databases_cur' ) = 0 
		BEGIN

			SET @LogEntry = 'Getting index statistics on database ' + @DatabaseName + ' in accordance with option ID ' + CAST(@IndexMaintOptionsID AS VARCHAR(10))
			EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

			IF @CheckPeriodicity > 0 AND @CheckPeriodicity IS NOT NULL
			BEGIN
				--Set the periodicity to a negative number for use in the DATEADD function.
				SET @CheckPeriodicity = 0 - @CheckPeriodicity
			END

			-- Purge old defragmentation records for the database. 
			DELETE FROM [IndexMaint].[Statistics]
			WHERE DatabaseName = @DatabaseName
				And (-- Remove entries that haven't been checked for a while
					InsertDate < DATEADD(dd, @CheckPeriodicity, GETDATE()) 
					-- Remove all if being forced
					Or @ForceCheck = 1 OR @CheckPeriodicity IS NULL)

			IF @ForceCheck = 1 OR @CheckPeriodicity IS NULL
			BEGIN
				SET @LogEntry = 'Purged all index statistics for ' + @DatabaseName + ' database due to the @ForceCheck bit being set to 1 or the @CheckPeriodicity set to NULL.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			END    
			ELSE
			BEGIN
				SET @LogEntry = 'Purged index statistics for ' + @DatabaseName + ' where the InsertDate was less than ' + CAST(DATEADD(dd, @CheckPeriodicity, GETDATE()) AS VARCHAR(25))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			END      

			-- Only rebuild the list after the indexes have been defragged
			IF (Select COUNT(IndexStatisticID) 
					From [IndexMaint].[Statistics] 
					WHERE DatabaseName = @DatabaseName And IndexStatus = 'Index Maintenance Required') = 0 
			BEGIN
				-- Remove the temp table used to store the index info during the run
				IF OBJECT_ID('tempdb..##FragmentationInfo') IS NOT NULL 
				Begin 
					EXEC ('Drop Table ##FragmentationInfo') 
				End
    
				-- Switch to the database to pull the index info from
				EXEC ('USE [' + @DatabaseName + ']') 
				
				-- Create the table to store the dm_db_index_physical_stats results
				EXEC ('CREATE TABLE ##FragmentationInfo
					(
						[DatabaseName] [nvarchar](128) NULL,
						[SchemaName] [sysname] NULL,
						[TableName] [nvarchar](128) NULL,
						[IndexName] [sysname] NULL,
						[IndexID] [int] NULL,
						[IndexDepth] [tinyint] NULL,
						[IndexLevel] [tinyint] NULL,
						[PartitionNumber] [int] NULL,
						[IndexTypeDesc] [nvarchar](60) NULL,
						[AllocUnitTypeDesc] [nvarchar](60) NULL,
						[AvgFragmentationPercent] [float] NULL,
						[AvgPageSpaceUsedPercent] [float] NULL,
						[FillFactor] [tinyint] NOT NULL,
						[IsDisabled] [bit] NULL,
						[PageCount] [bigint] NULL,
						[RecordCount] [bigint] NULL
					)')
				
				-- Load stats for current database from sys.dm_db_index_physical_stats
				--	- Ensure only base tables are scanned
				EXEC ('USE [' + @DatabaseName + '];
					Insert Into ##FragmentationInfo
					SELECT	DB_NAME(INX_Stat.Database_ID) AS [DatabaseName],
							INFO_Schema.TABLE_SCHEMA AS [SchemaName],
							OBJECT_NAME(INX_Stat.Object_Id) AS [TableName],
							INX.name AS [IndexName],
							INX_Stat.index_id AS [IndexID],
							INX_Stat.index_depth AS [IndexDepth],
							INX_Stat.index_level AS [IndexLevel],
							INX_Stat.partition_number AS [PartitionNumber],
							INX_Stat.index_type_desc AS [IndexTypeDesc],
							INX_Stat.alloc_unit_type_desc AS [AllocUnitTypeDesc],
							INX_Stat.avg_fragmentation_in_percent AS [AvgFragmentationPercent],
							INX_Stat.avg_page_space_used_in_percent AS [AvgPageSpaceUsedPercent],
							INX.fill_factor AS [FillFactor],
							INX.[is_disabled] AS [IsDisabled],
							INX_Stat.page_count AS [PageCount],
							INX_Stat.record_count AS [RecordCount]
					FROM sys.dm_db_index_physical_stats(DB_ID(''' + @DatabaseName + '''), NULL, NULL, NULL, ''SAMPLED'') INX_Stat
					INNER JOIN sys.indexes INX ON (INX.object_id = INX_Stat.object_id) AND (INX.index_id = INX_Stat.index_id)
					INNER JOIN INFORMATION_SCHEMA.TABLES INFO_Schema ON OBJECT_ID(INFO_Schema.TABLE_SCHEMA + ''.'' + INFO_Schema.TABLE_NAME) = INX_Stat.object_id
					WHERE INX.name IS NOT NULL
						AND INFO_Schema.TABLE_TYPE = ''BASE TABLE''
						AND INFO_Schema.TABLE_NAME <> ''dtproperties''
					ORDER BY INX_Stat.avg_fragmentation_in_percent DESC, INX_Stat.avg_page_space_used_in_percent ASC')

				-- Migrate the scan results into the [IndexMaint].[Statistics] table
				EXEC ('Insert Into [IndexMaint].[Statistics] ([DatabaseName],[SchemaName],[TableName],[IndexName],[IndexID]
																,[IndexDepth],[IndexLevel],[PartitionNumber],[IndexTypeDesc]
																,[AllocUnitTypeDesc],[AvgFragmentationPercent],[AvgPageSpaceUsedPercent]
																,[FillFactor],[IsDisabled],[PageCount],[RecordCount])
					Select INFO.[DatabaseName],INFO.[SchemaName],INFO.[TableName],INFO.[IndexName],INFO.[IndexID]
						  ,INFO.[IndexDepth],INFO.[IndexLevel],INFO.[PartitionNumber],INFO.[IndexTypeDesc],INFO.[AllocUnitTypeDesc]
						  ,INFO.[AvgFragmentationPercent],INFO.[AvgPageSpaceUsedPercent],INFO.[FillFactor],INFO.[IsDisabled],INFO.[PageCount],INFO.[RecordCount]
					From ##FragmentationInfo INFO
						-- Only add new indexes to the table
						Left Join [IndexMaint].[Statistics] INDX 
						On (INDX.DatabaseName = ''' + @DatabaseName + '''
							And INFO.TableName = INDX.TableName
							And INFO.IndexName = INDX.IndexName)
					Where LEN(INFO.IndexName) > 0
						And (INFO.IndexID > 0 And INFO.IndexID < 255)
						And INDX.IndexStatisticID IS NULL')
					
				SET @LogEntry = 'Inserted new index statistics records into [IndexMaint].[Statistics] for ' + @DatabaseName + ' database.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				-- Cleanup the temp table used to store the information
				EXEC ('Drop Table ##FragmentationInfo')

				-- Check the indexes and set the IndexStatus based on the settings, set the good indexes
				Update [IndexMaint].[Statistics]
				Set IndexStatus = 'Index is Optimal'
				WHERE DatabaseName = @DatabaseName
					And (
							(
								AvgFragmentationPercent <= @FragLimit  --Flag for optimal if the fragmentation is below the limit.
								And 
								((AvgPageSpaceUsedPercent  / (CASE [FillFactor] WHEN 0 THEN 100 ELSE [FillFactor] END) * 100) >= @PageSpaceLimit) -- Only flag as optimal if the space used percentage is above the limit adjusted for fill factor.
								/**************************************************************************************/
								/*See change history - 4/30/2013													  */
								/**************************************************************************************/
								--AND 
								--AvgPageSpaceUsedPercent  <= (CASE [FillFactor] WHEN 0 THEN 100 ELSE [FillFactor] END) --REBUILD if the space used is above the fill factor. This is the only way to allocate the space.
								/**************************************************************************************/
							) 
							OR RecordCount = 0	-- If there are no rows, there''s no need to reindex
							OR 
							(
								AvgFragmentationPercent <= @FragLimit
								AND
								[PageCount] <= 5
							) --Don't perform maintenance on extremely small tables unless they are fragmented. AvgPageSpaceUsedPercent is not a useful metric with such small tables.
						)
					And IndexStatus = 'Index Maintenance Required'

				SET @LogEntry = 'Updated index statistics records to ''Index is Optimal'' where their statistics met pre-determined/configured criteria in the ' + @DatabaseName + ' database.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				-- Check the statistics last updated date and set the IndexStatus based on the settings
				EXEC ('USE [' + @DatabaseName + '];
				Update [Utility].[IndexMaint].[Statistics]
				Set IndexStatus = ''Statistic Maintenance Required''
				WHERE DatabaseName = ''' + @DatabaseName + '''
					AND IndexName IN (	SELECT	INDX.name COLLATE SQL_Latin1_General_CP1_CI_AS AS IndexName
										FROM	sys.indexes INDX
										INNER JOIN sys.objects OBJS ON INDX.object_id = OBJS.object_id
										INNER JOIN [Utility].[IndexMaint].[Statistics] IXSTAT ON IXSTAT.IndexName = INDX.name COLLATE SQL_Latin1_General_CP1_CI_AS
																					   AND OBJS.object_id = OBJECT_ID(( QUOTENAME(LTRIM(RTRIM(IXSTAT.SchemaName)))
																									  + ''.''
																									  + QUOTENAME(LTRIM(RTRIM(IXSTAT.TableName)))))
										WHERE	OBJS.type = ''U'' --Ensure they are user tables only.
											AND DATEDIFF(dd, ISNULL(STATS_DATE(INDX.OBJECT_ID, index_id), OBJS.create_date), GETDATE()) > ' + @StatsExpiration + ') --Ensure that their stats are out of date based on configuration setting.
					AND IndexStatus != ''Index Maintenance Required'' --Do not mark for stats update when already marked for index maintenance because we use auto-update stats as a policy
																	--and index maintenance will do a better job updating the statistics than UPDATESTATISTICS will due to the sample size.
					AND RecordCount != 0');

				SET @LogEntry = 'Updated index statistics records to ''Statistic Maintenance Required'' where their statistics did not meet pre-determined/configured criteria in the ' + @DatabaseName + ' database.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			End 

			FETCH NEXT FROM Databases_cur INTO @DatabaseName
		END
  
		CLOSE Databases_cur
		DEALLOCATE Databases_cur

		FETCH NEXT FROM EnabledConfigs INTO @IndexMaintOptionsID
	END
  
	CLOSE EnabledConfigs
	DEALLOCATE EnabledConfigs
	
	SET NOCOUNT OFF
End

