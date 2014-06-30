/*
PROCEDURE:		[IndexMaint].[usp_CreateIndexMaintOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to create a new index maintenance option. This includes selecting or creating a new option, creating
				a new entry in IndexMaint.Configs and selecting or creating and umbrella configuration (Configuration.Configs). Most parameters
				are required and the procedure will decide if an identical match exists.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@FragLimit TINYINT --Set the maximum fragmentation level to be considered to be optimal.
				@PageSpaceLimit TINYINT --Minimum amount of space used in index pages before a maintenance action is performed.
				@ExecuteWindowEnd INT = NULL --This is a hour value from 1-24 that indicated a stopping time for any reindexing process. This
					prevents indexing operations from running over into production peak times.
				@MaxDefrag INT --Maximum fragmenation before a REBUILD is required over a REORGANIZE.
				@CheckPeriodicity INT = NULL --How often to re-check an index's statistics. By default (NULL) it will check everytime the procedure runs.
				@Databases VARCHAR(MAX) --A list of databases to include in this configuration.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/01/2012 --	Altered the table to account for stored procedure changes to use sys.dm_db_index_physical_stats 
									for versions SQL 2005 and greater due to the deprecation of DBCC SHOWCONTIG in SQL 2012.

** Derik Hammer ** 12/18/2012 --	Added the ability to receive and insert into the StatisticsExpiration column of the IndexMaint.Options table.

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

** Derik Hammer ** 09/06/2013 --	Set return value to provide user with the new option id.

** Derik Hammer ** 12/25/2013 --	Added support for the new column PreferOnline in the IndexMaint.Options table.

*/
CREATE PROCEDURE [IndexMaint].[usp_CreateIndexMaintOption]
	@debug BIT = 0,
	@FragLimit TINYINT,
	@PageSpaceLimit TINYINT,
	@ExecuteWindowEnd TINYINT = NULL,
	@MaxDefrag TINYINT,
	@StatsExpiration TINYINT,
	@CheckPeriodicity TINYINT = NULL,
	@PreferOnline BIT = 1,
	@Databases VARCHAR(8000)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Declare variables
	DECLARE @OptionID INT
	DECLARE @DatabaseName SYSNAME
	DECLARE @DatabaseID INT
	DECLARE @ReturnValue INT = 0
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION

		/*			Select or create index maint option			*/
		
		--INSERT Option Settings
		IF NOT EXISTS	(
							SELECT [OptionID]
							FROM [IndexMaint].[Options]
							WHERE [FragLimit] = @FragLimit
								AND [PageSpaceLimit] = @PageSpaceLimit
								AND ISNULL(CAST([ExecuteWindowEnd] AS VARCHAR),'NULL') = ISNULL(CAST(@ExecuteWindowEnd AS VARCHAR),'NULL')
								AND [StatisticsExpiration] = @StatsExpiration
								AND [MaxDefrag] = @MaxDefrag
								AND ISNULL(CAST([CheckPeriodicity] AS VARCHAR),'NULL') = ISNULL(CAST(@CheckPeriodicity AS VARCHAR),'NULL')
								AND @PreferOnline = [PreferOnline]
						)
			BEGIN
				INSERT INTO [IndexMaint].[Options]
					   ([FragLimit]
					   ,[PageSpaceLimit]
					   ,[ExecuteWindowEnd]
					   ,[StatisticsExpiration]
					   ,[MaxDefrag]
					   ,[CheckPeriodicity]
					   ,[PreferOnline])
				VALUES
					   (@FragLimit
					   ,@PageSpaceLimit
					   ,@ExecuteWindowEnd
					   ,@StatsExpiration
					   ,@MaxDefrag
					   ,@CheckPeriodicity
					   ,@PreferOnline)

				SET @LogEntry = 'Created new Index Maintenance Option: [FragLimit] = ' + CAST(@FragLimit AS VARCHAR(3)) + ', [PageSpaceLimit] = ' + 
					CAST(@PageSpaceLimit AS VARCHAR(3)) + ', [ExecuteWindowEnd] = ' + CAST(@ExecuteWindowEnd AS VARCHAR(3)) + ', [MaxDefrag] = ' + 
					CAST(@MaxDefrag AS VARCHAR(3)) + ', [StatisticExpiration] = ' + CAST(@StatsExpiration AS VARCHAR(3)) + ', [CheckPeriodicity] = ' + 
					CAST(@CheckPeriodicity AS VARCHAR(10)) + ', [PrferOnline] = ' + CAST(@PreferOnline AS CHAR(1))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

				IF @debug = 1
				BEGIN
					PRINT 'New Index Maintenance Option inserted.'
				END
				
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
			ELSE
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Index Maintenance Option set already existed, moving on.'
				END
			END
  
		--Set OptionID
		SELECT @OptionID = [OptionID]
		FROM [IndexMaint].[Options]
		WHERE [FragLimit] = @FragLimit
			AND [PageSpaceLimit] = @PageSpaceLimit
			AND ISNULL(CAST([ExecuteWindowEnd] AS VARCHAR),'NULL') = ISNULL(CAST(@ExecuteWindowEnd AS VARCHAR),'NULL')
			AND [StatisticsExpiration] = @StatsExpiration
			AND [MaxDefrag] = @MaxDefrag
			AND ISNULL(CAST([CheckPeriodicity] AS VARCHAR),'NULL') = ISNULL(CAST(@CheckPeriodicity AS VARCHAR),'NULL')
			AND @PreferOnline = [PreferOnline]

		--Populate Databases List
		DECLARE Databases_Cursor CURSOR FAST_FORWARD FOR
		SELECT DatabaseName
		FROM [dbo].[udf_DatabaseSelect] (@Databases,1)
		
		OPEN Databases_Cursor
		FETCH NEXT FROM Databases_Cursor INTO @DatabaseName

		WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'Databases_Cursor' ) = 0 
		BEGIN
			--Find the Registered ID associated to this database name.      
			SELECT @DatabaseID = DatabaseID
			FROM [Configuration].[RegisteredDatabases]
			WHERE databasename = @DatabaseName
			--Insert into the Backup.Databases table if needed.
			IF NOT EXISTS	(
								SELECT [IndexDatabaseID] 
								FROM [IndexMaint].[Databases] 
								WHERE [DatabaseID] = @DatabaseID 
									AND [OptionID] = @OptionID
							)
			BEGIN
				INSERT INTO [IndexMaint].[Databases] 
						   ([DatabaseID]
						   ,[OptionID])
					 VALUES
						   (@DatabaseID
						   ,@OptionID)

				SET @LogEntry = 'Index Maintenance Option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' now associated with database(s): ' + @Databases
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			END
			--Fetch next database name.
			FETCH NEXT FROM Databases_Cursor INTO @DatabaseName
		END
  
		CLOSE Databases_Cursor
		DEALLOCATE Databases_Cursor
        
		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback
		
	--Commit
	COMMIT TRANSACTION
	SET @ReturnValue = @OptionID
    
	GOTO EndSave
	QuitWithRollback:
		PRINT 'New Index Maintenance Option Transaction Rolled Back due to Error: ' + CAST(@@ERROR AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:

	SET NOCOUNT OFF  
	RETURN ISNULL(@ReturnValue, 0);
GO