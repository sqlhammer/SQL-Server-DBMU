/*
PROCEDURE:		[Trace].[usp_AlterTraceOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to alter an existing trace option. 
PARAMETERS:		@OptionID INT --Mandatory OptionID to be updated.
				@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@FileDirectory VARCHAR(8000) = NULL --Set the file directory to house the trace file.
				@TraceName VARCHAR(50) = NULL --Name of this trace Option. This will be included in the naming convension for the storage tables.
				@PurgeDays INT = NULL --Number of days to keep the trace storage tables.
				@MaxFileSize BIGINT = NULL --Max file size for the trace file. WARNING: If this limit is reached before the usp_PopulateCurrentTraceTables
					procedure is executed then the trace will stop and manual intervention will be required to start it again.
				@QueryRunTime VARCHAR(20) = NULL = NULL --Optional filter parameter for query "Duration".
					You must use 'NULL' if you want this option to change to NULL.
				@Reads VARCHAR(20) = NULL --Optional filter parameter for minimum reads before the query is traced.
					You must use 'NULL' if you want this option to change to NULL.
				@Writes VARCHAR(20) = NULL --Optional filter parameter for minimum writes before the query is traced.
					You must use 'NULL' if you want this option to change to NULL.
				@Databases VARCHAR(8000) = NULL --A list of databases to include in this configuration.
				@RemoveDBList BIT = 0 --Used to indicate whether to add or subtract the database list.
				@ValidateDatabasesExists BIT = 1 --If 1, CSV elements which don't match and existing database will be ignored.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/17/2012 --	Rewrote the database list portion of the procedure to perform insert or delete operations rather than a purge and reinsert
									method of populating the database list. This enabled me to remove a cursor and the user will no longer need to know or type
									the full list of databases registered to an OptionID to make the alteration.

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

** Derik Hammer ** 09/06/2013 --	Set XACT_ABORT to ON so that the first error in a transaction will roll back and not continue to execute further commands.

** Derik Hammer ** 09/07/2013 --	Created the @ValidateDatabasesExists parameter for passing into the udf_DatabaseSelect function.

*/
CREATE PROCEDURE [Trace].[usp_AlterTraceOption]
	@OptionID INT,
	@debug BIT = 0,
	@FileDirectory VARCHAR(8000) = NULL,
	@TraceName VARCHAR(50) = NULL,
	@PurgeDays INT = NULL,
	@MaxFileSize BIGINT = NULL,
	@QueryRunTime VARCHAR(20) = NULL,
	@Reads VARCHAR(20) = NULL,
	@Writes VARCHAR(20) = NULL,
	@Databases VARCHAR(8000) = NULL,
	@RemoveDBList BIT = 0,
	@ValidateDatabasesExist BIT = 1
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Declare variables
	DECLARE @DiskLocationID INT 
	DECLARE @DatabaseID INT
	DECLARE @ErrorMsg VARCHAR(8000)
	DECLARE @UpdateStatement VARCHAR(8000)
	DECLARE @DatabaseName SYSNAME
	DECLARE @FileExtension CHAR(3)
	--Current settings storage variables
	DECLARE @CurrentFileDirectory VARCHAR(8000)
	DECLARE @CurrentDiskLocationID INT
	DECLARE @CurrentTraceName VARCHAR(50)
	DECLARE @CurrentPurgeDays INT
	DECLARE @CurrentMaxFileSize BIGINT
	DECLARE @CurrentQueryRunTime BIGINT
	DECLARE @CurrentReads BIGINT
	DECLARE @CurrentWrites BIGINT
	--Requested settings storage variables
	DECLARE @RequestedFileDirectory VARCHAR(8000)
	DECLARE @RequestedDiskLocationID INT
	DECLARE @RequestedTraceName VARCHAR(50)
	DECLARE @RequestedPurgeDays INT
	DECLARE @RequestedMaxFileSize BIGINT
	DECLARE @RequestedQueryRunTime BIGINT
	DECLARE @RequestedReads BIGINT
	DECLARE @RequestedWrites BIGINT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION

		/*		Populate CURRENT option information for debugging and reference			*/
		--Validate that it exists.
		IF NOT EXISTS	(
							SELECT  [OptionID]
							FROM [Trace].[Options]
							WHERE [OptionID] = @OptionID
						)
		BEGIN
			SET @ErrorMsg = 'Cannot alter Trace OptionID ' + ISNULL(CAST(@OptionID AS VARCHAR(10)),'NULL') + ' because it does not exist.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'          
			RAISERROR(@ErrorMsg,16,1)
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
        
		--Set variables.
		SELECT  @CurrentDiskLocationID = [DiskLocationID],
				@CurrentTraceName = [TraceName],
				@CurrentPurgeDays = [PurgeDays],
				@CurrentMaxFileSize = [MaxFileSize],
				@CurrentQueryRunTime = [QueryRunTime],
				@CurrentReads = [Reads],
				@CurrentWrites = [Writes]
		FROM [Trace].[Options]
		WHERE [OptionID] = @OptionID

		--Set File extension.
		SET @FileExtension = 'TRC'

		IF @debug = 1
		BEGIN
			PRINT '----------Current Trace Option Settings----------'
			PRINT '--DiskLocationID = ' + CAST(@CurrentDiskLocationID AS VARCHAR)
			PRINT '--TraceName = ' + @CurrentTraceName
			PRINT '--PurgeDays = ' + CAST(@CurrentPurgeDays AS VARCHAR)
			PRINT '--MaxFileSize = ' + CAST(@CurrentMaxFileSize AS VARCHAR)
			PRINT '--QueryRunTime = ' + ISNULL(CAST(@CurrentQueryRunTime AS VARCHAR),'NULL')
			PRINT '--Reads = ' + ISNULL(CAST(@CurrentReads AS VARCHAR),'NULL')
			PRINT '--Writes = ' + ISNULL(CAST(@CurrentWrites AS VARCHAR),'NULL')
			PRINT '--------------------------------------------------'
			PRINT ''
		END

		/*		Populate REQUESTED option information for debugging and reference		*/

		--Set/Validate Trace Name.
		IF @TraceName IS NOT NULL
		BEGIN      
			IF NOT EXISTS	(
								SELECT [OptionID]
								FROM [Trace].[Options]
								WHERE [TraceName] = @TraceName
									AND [OptionID] <> @OptionID
							)
			BEGIN
				SET @RequestedTraceName = @TraceName

				IF @debug = 1
				BEGIN
					PRINT 'Population of @RequestedTraceName, derived from @TraceName, complete.'
				END
			END
			ELSE
			BEGIN
				SET @ErrorMsg = 'Error: There is already another trace option with the trace name, ''' + @TraceName + '''. Each trace option must have a unique trace name.'      
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'          
				RAISERROR(@ErrorMsg,16,1)
				GOTO QuitWithRollback
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback          
		END
		ELSE
		BEGIN      
			SELECT @RequestedTraceName = @CurrentTraceName
			
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedTraceName, derived from @CurrentTraceName, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END  

		--Set/Validate PurgeDays.
		IF @PurgeDays IS NOT NULL
		BEGIN      
			SET @RequestedPurgeDays = @PurgeDays

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeDays, derived from @PurgeDays, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedPurgeDays = @CurrentPurgeDays

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeDays, derived from @CurrentPurgeDays, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
  
		--Set/Validate MaxFileSize
		IF @MaxFileSize IS NOT NULL
		BEGIN      
			SET @RequestedMaxFileSize = @MaxFileSize

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedMaxFileSize, derived from @MaxFileSize, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback          
		END
		ELSE
		BEGIN      
			SET @RequestedMaxFileSize = @CurrentMaxFileSize

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedMaxFileSize, derived from @CurrentMaxFileSize, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback        
		END
  
		--Create disk location record if not exists
		IF @FileDirectory IS NOT NULL
		BEGIN
			IF NOT EXISTS	(
								SELECT [DiskLocationID]
								FROM [Configuration].[DiskLocations]
								WHERE [FileExtension] = @FileExtension 
									AND [FilePath] = @FileDirectory
							)
				BEGIN
					INSERT INTO [Configuration].[DiskLocations]
					(
						[FileExtension],
						[FilePath]
					)
					VALUES
					(
						@FileExtension,
						@FileDirectory
					)

					SET @LogEntry = 'Registered new Disk Location: File Extension = ' + @FileExtension + ', Directory = ' + @FileDirectory
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				
					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback        

					IF @debug = 1
					BEGIN
						PRINT 'New disk location record created.'
					END
				END

			--Set Requested Disk Location ID
			SELECT @RequestedDiskLocationID = [DiskLocationID]
			FROM [Configuration].[DiskLocations]
			WHERE [FileExtension] = @FileExtension 
				AND [FilePath] = @FileDirectory

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedDiskLocationID, derived from @FileDirectory, complete.'
			END              
		END
		ELSE
		BEGIN
			--Set Requested Disk Location ID
			SELECT @RequestedDiskLocationID = @CurrentDiskLocationID

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedDiskLocationID, derived from @CurrentDiskLocationID, complete.'
			END  
		END      
			
		--Set/Validate QueryRunTime filter.
		IF @QueryRunTime IS NOT NULL
		BEGIN      
			--Set the 'NULL' setting to an actual NULL and an attempt an BIGINT convert so it 
			--will throw an error now if a non-BIGINT was inputted.
			SET @RequestedQueryRunTime = CAST(REPLACE(UPPER(@QueryRunTime),'NULL','') AS BIGINT)

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedQueryRunTime, derived from @QueryRunTime, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN
			SET @RequestedQueryRunTime = @CurrentQueryRunTime

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedQueryRunTime, derived from @CurrentQueryRunTime, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END

		--Set/Validate Reads filter.
		IF @Reads IS NOT NULL
		BEGIN      
			--Set the 'NULL' setting to an actual NULL and an attempt an BIGINT convert so it 
			--will throw an error now if a non-BIGINT was inputted.
			SET @RequestedReads = CAST(REPLACE(UPPER(@Reads),'NULL','') AS BIGINT)

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedReads, derived from @Reads, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN
			SET @RequestedReads = @CurrentReads

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedReads, derived from @CurrentReads, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
  
		--Set/Validate Writes filter.
		IF @Writes IS NOT NULL
		BEGIN      
			--Set the 'NULL' setting to an actual NULL and an attempt an BIGINT convert so it 
			--will throw an error now if a non-BIGINT was inputted.
			SET @RequestedWrites = CAST(REPLACE(UPPER(@Writes),'NULL','') AS BIGINT)

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedWrites, derived from @Writes, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN
			SET @RequestedWrites = @CurrentWrites

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedQueryRunTime, derived from @CurrentWrites, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
    
		--Set new database list
		IF @Databases IS NOT NULL
		BEGIN
			--If @RemoveDBList = 0 then append the databases from the list provided if they don't already exist.
			IF @RemoveDBList = 0
			BEGIN
				--Add new database references to the [Trace].[Databases] table for @OptionID
				IF @debug = 1
				BEGIN
					PRINT 'Insert new database references.'
					PRINT 'INSERT INTO [Trace].[Databases] ([DatabaseID], [OptionID])' + CHAR(13) + CHAR(10) +
					'	SELECT rDBs.DatabaseID, @OptionID' + CHAR(13) + CHAR(10) +
					'	FROM [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBSelection' + CHAR(13) + CHAR(10) +
					'	INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'	WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'								FROM [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBlist' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [Trace].[Databases] TraceDBs ON regDBs.DatabaseID = TraceDBs.DatabaseID' + CHAR(13) + CHAR(10) +
					'								WHERE TraceDBs.OptionID = @OptionID)'
				END
				ELSE
				BEGIN
					INSERT INTO [Trace].[Databases] ([DatabaseID], [OptionID])
						SELECT rDBs.DatabaseID, @OptionID
						FROM [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBSelection
						INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName
						WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName
													FROM [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBlist
													INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName
													INNER JOIN [Trace].[Databases] TraceDBs ON regDBs.DatabaseID = TraceDBs.DatabaseID
													WHERE TraceDBs.OptionID = @OptionID)
					
					SET @LogEntry = 'Inserted additional databases to Trace Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Database list = ' + @Databases
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END
			END
			ELSE --If @RemoveDBList = 1 then keep the current list but remove the databases listed in the inputted list.
			BEGIN
				--Delete records from the [Trace].[Databases] table based on the list of database names provided.
				IF @debug = 1
				BEGIN
					PRINT 'Deleting database references.'      
					PRINT 'DELETE TraceDBs' + CHAR(13) + CHAR(10) +
					'FROM [Trace].[Databases] TraceDBs' + CHAR(13) + CHAR(10) +
					'INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = TraceDBs.DatabaseID' + CHAR(13) + CHAR(10) +
					'INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBlist ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'WHERE TraceDBs.OptionID = @OptionID'     
				END
				ELSE             
				BEGIN
					--Delete the database reference to @OptionID
					DELETE TraceDBs
					FROM [Trace].[Databases] TraceDBs
					INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = TraceDBs.DatabaseID
					INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBlist ON DBlist.DatabaseName = regDBs.DatabaseName
					WHERE TraceDBs.OptionID = @OptionID

					SET @LogEntry = 'Delete the database reference to Trace option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' from [Trace].[Databases].'
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace',	@TextEntry = @LogEntry, @LogMode = 'VERBOSE'

					SET @LogEntry = 'Finished deleting listed databases related to Trace Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Purged Database list = ' + @Databases
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
				END
					
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		END      

		--Construct UPDATE statement.
		SET @UpdateStatement =	'UPDATE [Trace].[Options]'
		SET @UpdateStatement = @UpdateStatement + ' SET [DiskLocationID] = ' + CAST(@RequestedDiskLocationID AS VARCHAR)
		SET @UpdateStatement = @UpdateStatement + ', [TraceName] = ''' + CAST(@RequestedTraceName AS VARCHAR) + ''''
		SET @UpdateStatement = @UpdateStatement + ', [PurgeDays] = ' + CAST(@RequestedPurgeDays AS VARCHAR)
		SET @UpdateStatement = @UpdateStatement + ', [MaxFileSize] = ' + CAST(@RequestedMaxFileSize AS VARCHAR)
		SET @UpdateStatement = @UpdateStatement + ', [QueryRunTime] = ' + ISNULL(CAST(@RequestedQueryRunTime AS VARCHAR),'NULL')
		SET @UpdateStatement = @UpdateStatement + ', [Reads] = ' + ISNULL(CAST(@RequestedReads AS VARCHAR),'NULL')
		SET @UpdateStatement = @UpdateStatement + ', [Writes] = ' + ISNULL(CAST(@RequestedWrites AS VARCHAR),'NULL')
		SET @UpdateStatement = @UpdateStatement + ' WHERE [OptionID] = ' + CAST(@OptionID AS VARCHAR)

		--Execute
		IF @debug = 1
		BEGIN
			PRINT ''      
			PRINT '----------Requested Trace Option Settings----------'
			PRINT '--DiskLocationID = ' + CAST(@RequestedDiskLocationID AS VARCHAR)
			PRINT '--TraceName = ' + @RequestedTraceName
			PRINT '--PurgeDays = ' + CAST(@RequestedPurgeDays AS VARCHAR)
			PRINT '--MaxFileSize = ' + CAST(@RequestedMaxFileSize AS VARCHAR)
			PRINT '--QueryRunTime = ' + ISNULL(CAST(@RequestedQueryRunTime AS VARCHAR),'NULL')
			PRINT '--Reads = ' + ISNULL(CAST(@RequestedReads AS VARCHAR),'NULL')
			PRINT '--Writes = ' + ISNULL(CAST(@RequestedWrites AS VARCHAR),'NULL')
			PRINT '--------------------------------------------------'
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
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace',	@TextEntry = @UpdateStatement, @LogMode = 'LIMITED'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback  
		END

	--Commit
	COMMIT TRANSACTION 
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'Alter Trace Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		PRINT @LogEntry
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
	
	SET NOCOUNT OFF  
GO