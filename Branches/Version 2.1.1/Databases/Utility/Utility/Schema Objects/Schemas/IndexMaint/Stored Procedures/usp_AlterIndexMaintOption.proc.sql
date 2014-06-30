/*
PROCEDURE:		[IndexMaint].[usp_AlterIndexMaintOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to alter an existing backup option. 
PARAMETERS:		@OptionID INT --Mandatory OptionID to be updated.
				@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@FragLimit TINYINT --Set the maximum fragmentation level to be considered to be optimal.
				@PageSpaceLimit TINYINT --Minimum amount of space used in index pages before a maintenance action is performed.
				@ExecuteWindowEnd VARCHAR(11) = NULL --This is a hour value from 1-24 that indicated a stopping time for any reindexing process. This
					prevents indexing operations from running over into production peak times. You must input the character string 'NULL' if you
					want this setting set to NULL.
				@MaxDefrag INT --Maximum fragmenation before a REBUILD is required over a REORGANIZE.
				@CheckPeriodicity VARCHAR(11) = NULL --How often to re-check an index's statistics. By default (NULL) it will check everytime the procedure runs.
					You must input the character string 'NULL' if you want this setting set to NULL.
				@Databases VARCHAR(8000) --A list of databases to include in this configuration.
				@RemoveDBList BIT = 0 --Used to indicate whether to add or subtract the database list.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/01/2012 --	Altered parameters to account for stored procedure changes to use sys.dm_db_index_physical_stats 
									for versions SQL 2005 and greater due to the deprecation of DBCC SHOWCONTIG in SQL 2012.

** Derik Hammer ** 01/27/2013 --	Removed the purge of databases before the addition/subtraction section. It was meant to be removed in an earlier version.

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

*/
CREATE PROCEDURE [IndexMaint].[usp_AlterIndexMaintOption]
	@OptionID INT,
	@debug BIT = 0,
	@FragLimit TINYINT = NULL,
	@PageSpaceLimit TINYINT = NULL,
	@ExecuteWindowEnd VARCHAR(11) = NULL,
	@MaxDefrag TINYINT = NULL,
	@CheckPeriodicity VARCHAR(11) = NULL,
	@Databases VARCHAR(8000) = NULL,
	@RemoveDBList BIT = 0
AS
	SET NOCOUNT ON

	--Declare variables
	DECLARE @OptionsID INT
	DECLARE @DiskLocationID INT 
	DECLARE @DatabaseID INT
	DECLARE @ErrorMsg VARCHAR(8000)
	DECLARE @UpdateStatement VARCHAR(8000)
	DECLARE @DatabaseName SYSNAME
	--Current settings storage variables
	DECLARE @CurrentFragLimit TINYINT
	DECLARE @CurrentPageSpaceLimit TINYINT
	DECLARE @CurrentExecuteWindowEnd TINYINT
	DECLARE @CurrentMaxDefrag TINYINT
	DECLARE @CurrentCheckPeriodicity TINYINT
	--Requested settings storage variables
	DECLARE @RequestedFragLimit TINYINT
	DECLARE @RequestedPageSpaceLimit TINYINT
	DECLARE @RequestedExecuteWindowEnd TINYINT
	DECLARE @RequestedMaxDefrag TINYINT
	DECLARE @RequestedCheckPeriodicity TINYINT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION 

		/*		Populate current option information for debugging and reference		*/
		--Validate that it exists.
		IF NOT EXISTS	(
							SELECT  [OptionID]
							FROM [IndexMaint].[Options]
							WHERE [OptionID] = @OptionID
						)
		BEGIN
			SET @ErrorMsg = 'Cannot alter Index Maintenance OptionID ' + ISNULL(CAST(@OptionID AS VARCHAR(10)),'NULL') + ' because it does not exist.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'    
			RAISERROR(@ErrorMsg,16,1)
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
        
		SELECT	@CurrentFragLimit = [FragLimit],
				@CurrentPageSpaceLimit = [PageSpaceLimit],
				@CurrentExecuteWindowEnd = [ExecuteWindowEnd],
				@CurrentMaxDefrag = [MaxDeFrag],
				@CurrentCheckPeriodicity = [CheckPeriodicity]
		FROM [IndexMaint].[Options]
		WHERE [OptionID] = @OptionID

		IF @debug = 1
		BEGIN
			PRINT '----------Current Index Maintenace Option Settings----------'
			PRINT '--FragLimit = ' + CAST(@CurrentFragLimit AS VARCHAR)
			PRINT '--PageSpaceLimit = ' + CAST(@CurrentPageSpaceLimit AS VARCHAR)
			PRINT '--ExecuteWindowEnd = ' + ISNULL(CAST(@CurrentExecuteWindowEnd AS VARCHAR),'NULL')
			PRINT '--MaxDeFrag = ' + CAST(@CurrentMaxDefrag AS VARCHAR)
			PRINT '--CheckPeriodicity = ' + ISNULL(CAST(@CurrentCheckPeriodicity AS VARCHAR),'NULL')
			PRINT '------------------------------------------------------------'
			PRINT ''
		END

		/*		Populate requested option information for debugging and reference	*/

		--Set/Validate FragLimit
		IF @FragLimit IS NOT NULL
		BEGIN      
			SET @RequestedFragLimit = @FragLimit

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFragLimit, derived from @FragLimit, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedFragLimit = @CurrentFragLimit

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFragLimit, derived from @CurrentFragLimit, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END 

		--Set/Validate PageSpaceLimit
		IF @PageSpaceLimit IS NOT NULL
		BEGIN      
			SET @RequestedPageSpaceLimit = @PageSpaceLimit

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPageSpaceLimit, derived from @PageSpaceLimit, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedPageSpaceLimit = @CurrentPageSpaceLimit

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPageSpaceLimit, derived from @CurrentPageSpaceLimit, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END 
		
		--Set/Validate ExecuteWindowEnd
		IF @ExecuteWindowEnd IS NOT NULL
		BEGIN      
			IF @ExecuteWindowEnd = 'NULL'
			BEGIN
				SET @RequestedExecuteWindowEnd = NULL
			END
			ELSE
			BEGIN
				SET @RequestedExecuteWindowEnd = CAST(@ExecuteWindowEnd AS INT)
			END 

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedExecuteWindowEnd, derived from @ExecuteWindowEnd, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN
			SET @RequestedExecuteWindowEnd = @CurrentExecuteWindowEnd

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedExecuteWindowEnd, derived from @CurrentExecuteWindowEnd, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END 

		--Set/Validate MaxDeFrag
		IF @MaxDeFrag IS NOT NULL
		BEGIN      
			SET @RequestedMaxDeFrag = @MaxDeFrag

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedMaxDeFrag, derived from @MaxDeFrag, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedMaxDeFrag = @CurrentMaxDeFrag

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedMaxDeFrag, derived from @CurrentMaxDeFrag, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END 

		--Set/Validate CheckPeriodicity
		IF @CheckPeriodicity IS NOT NULL
		BEGIN      
			IF @CheckPeriodicity = 'NULL'
			BEGIN
				SET @RequestedCheckPeriodicity = NULL
			END
			ELSE
			BEGIN
				SET @RequestedCheckPeriodicity = CAST(@CheckPeriodicity AS INT)
			END         

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedCheckPeriodicity, derived from @CheckPeriodicity, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN
			SET @RequestedCheckPeriodicity = @CurrentCheckPeriodicity

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedCheckPeriodicity, derived from @CurrentCheckPeriodicity, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END 

		--Set new database list
		IF @Databases IS NOT NULL
		BEGIN      
			--Alter database references
			IF @Databases IS NOT NULL
			BEGIN
				--If @RemoveDBList = 0 then append the databases from the list provided if they don't already exist.
				IF @RemoveDBList = 0
				BEGIN
					--Add new database references to the [IndexMaint].[Databases] table for @OptionID
					IF @debug = 1
					BEGIN
						PRINT 'Insert new database references.'
						PRINT 'INSERT INTO [IndexMaint].[Databases] ([DatabaseID], [OptionID])' + CHAR(13) + CHAR(10) +
						'	SELECT rDBs.DatabaseID, @OptionID' + CHAR(13) + CHAR(10) +
						'	FROM [dbo].[udf_DatabaseSelect] (@Databases,1) DBSelection' + CHAR(13) + CHAR(10) +
						'	INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName' + CHAR(13) + CHAR(10) +
						'	WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
						'								FROM [dbo].[udf_DatabaseSelect] (@Databases,1) DBlist' + CHAR(13) + CHAR(10) +
						'								INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
						'								INNER JOIN [IndexMaint].[Databases] INXDBs ON regDBs.DatabaseID = INXDBs.DatabaseID' + CHAR(13) + CHAR(10) +
						'								WHERE INXDBs.OptionID = @OptionID)'
					END
					ELSE
					BEGIN
						INSERT INTO [IndexMaint].[Databases] ([DatabaseID], [OptionID])
							SELECT rDBs.DatabaseID, @OptionID
							FROM [dbo].[udf_DatabaseSelect] (@Databases,1) DBSelection
							INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName
							WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName
														FROM [dbo].[udf_DatabaseSelect] (@Databases,1) DBlist
														INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName
														INNER JOIN [IndexMaint].[Databases] INXDBs ON regDBs.DatabaseID = INXDBs.DatabaseID
														WHERE INXDBs.OptionID = @OptionID)
					
						SET @LogEntry = 'Inserted additional databases to backup Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Database list = ' + @Databases
						EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'

						--Roll back if error occurs.
						IF @@ERROR <> 0 GOTO QuitWithRollback
					END
				END
				ELSE --If @RemoveDBList = 1 then keep the current list but remove the databases listed in the inputted list.
				BEGIN
					--Delete records from the [IndexMaint].[Databases] table based on the list of database names provided.
					IF @debug = 1
					BEGIN
						PRINT 'Deleting database references.'      
						PRINT 'DELETE INXDBs' + CHAR(13) + CHAR(10) +
						'FROM [IndexMaint].[Databases] INXDBs' + CHAR(13) + CHAR(10) +
						'INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = INXDBs.DatabaseID' + CHAR(13) + CHAR(10) +
						'INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,1) DBlist ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
						'WHERE INXDBs.OptionID = @OptionID'     
					END
					ELSE             
					BEGIN
						--Delete the database reference to @OptionID
						DELETE INXDBs
						FROM [IndexMaint].[Databases] INXDBs
						INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = INXDBs.DatabaseID
						INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,1) DBlist ON DBlist.DatabaseName = regDBs.DatabaseName
						WHERE INXDBs.OptionID = @OptionID

						SET @LogEntry = 'Delete the database reference to backup option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' from [IndexMaint].[Databases].'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance',	@TextEntry = @LogEntry, @LogMode = 'VERBOSE'

						SET @LogEntry = 'Finished deleting listed databases related to backup Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Purged Database list = ' + @Databases
						EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
					END
					
					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END
			END      
		END

		--Construct UPDATE statement.
		SET @UpdateStatement =	'UPDATE [IndexMaint].[Options]' +
			' SET [FragLimit] = ' + CAST(@RequestedFragLimit AS VARCHAR) +
			', [PageSpaceLimit] = ' + CAST(@RequestedPageSpaceLimit AS VARCHAR) +
			', [ExecuteWindowEnd] = ' + ISNULL(CAST(@RequestedExecuteWindowEnd AS VARCHAR),'NULL') +
			', [MaxDeFrag] = ' + CAST(@RequestedMaxDeFrag AS VARCHAR) +
			', [CheckPeriodicity] = ' + ISNULL(CAST(@RequestedCheckPeriodicity AS VARCHAR),'NULL') +
			' WHERE [OptionID] = ' + CAST(@OptionID AS VARCHAR)

		--Execute
		IF @debug = 1
		BEGIN
			PRINT ''      
			PRINT '----------Requested Index Maintenance Option Settings----------'
			PRINT '--FragLimit = ' + CAST(@RequestedFragLimit AS VARCHAR)
			PRINT '--PageSpaceLimit = ' + CAST(@RequestedPageSpaceLimit AS VARCHAR)
			PRINT '--ExecuteWindowEnd = ' + ISNULL(CAST(@RequestedExecuteWindowEnd AS VARCHAR),'NULL')
			PRINT '--MaxDeFrag = ' + CAST(@RequestedMaxDefrag AS VARCHAR)
			PRINT '--CheckPeriodicity = ' + ISNULL(CAST(@RequestedCheckPeriodicity AS VARCHAR),'NULL')
			PRINT '---------------------------------------------------------------'
			PRINT ''
			PRINT '@UpdateStatement = '
			PRINT @UpdateStatement
			PRINT ''
			PRINT 'EXEC ( @UpdateStatement )'
			PRINT ''
			PRINT '**************************************************************************'
			PRINT 'NOTE: Your UPDATE command was not executed due to debugging being enabled.'
			PRINT '**************************************************************************'
		END
		ELSE
		BEGIN
			EXEC ( @UpdateStatement )
			EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance',	@TextEntry = @UpdateStatement, @LogMode = 'LIMITED'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback  
		END      

	--Commit
	COMMIT TRANSACTION 
	GOTO EndSave
	QuitWithRollback:
		PRINT 'Alter Index Maintenance Option Transaction Rolled Back due to Error: ' + CAST(@@ERROR AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	EndSave:

	SET NOCOUNT OFF  
GO