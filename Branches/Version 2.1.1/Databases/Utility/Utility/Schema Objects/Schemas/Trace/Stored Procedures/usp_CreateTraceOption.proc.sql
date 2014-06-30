/*
PROCEDURE:		[Trace].[usp_CreateTraceOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to create a new Trace option. This includes selecting or creating a new option, creating
				a new entry in Trace.Configs and selecting or creating and umbrella configuration (Configuration.Configs). Most parameters
				are required and the procedure will decide if an identical match exists.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@FileDirectory VARCHAR(8000) --Set the file directory to house the trace file.
				@TraceName VARCHAR(50) --Name of this trace Option. This will be included in the naming convension for the storage tables.
				@PurgeDays INT --Number of days to keep the trace storage tables.
				@MaxFileSize BIGINT --Max file size for the trace file. WARNING: If this limit is reached before the usp_PopulateCurrentTraceTables
					procedure is executed then the trace will stop and manual intervention will be required to start it again.
				@QueryRunTime BIGINT = NULL --Optional filter parameter for query "Duration".
				@Reads BIGINT = NULL --Optional filter parameter for minimum reads before the query is traced.
				@Writes BIGINT = NULL --Optional filter parameter for minimum writes before the query is traced.
				@Databases VARCHAR(8000) --A list of databases to include in this configuration.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

*/
CREATE PROCEDURE [Trace].[usp_CreateTraceOption]
	@debug BIT = 0,
	@FileDirectory VARCHAR(8000),
	@TraceName VARCHAR(50),
	@PurgeDays INT,
	@MaxFileSize BIGINT,
	@QueryRunTime BIGINT = NULL,
	@Reads BIGINT = NULL,
	@Writes BIGINT = NULL,
	@Databases VARCHAR(8000)
AS
	SET NOCOUNT ON

	--Declare variables
	DECLARE @DiskLocationINT INT
	DECLARE @OptionID INT
	DECLARE @DatabaseName SYSNAME
	DECLARE @DatabaseID INT
	DECLARE @FileExtension CHAR(3)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION

		/*		Select or create backup option				*/
		
		--Set the file extension.
		SET @FileExtension = 'TRC'
			
		--Create DiskLocation entry if it doesn't already exist.
		IF NOT EXISTS	(
							SELECT [DiskLocationID] 
							FROM [Configuration].[DiskLocations] 
							WHERE [FileExtension] = @FileExtension 
								AND [FilePath] = @FileDirectory
						)
		BEGIN
			INSERT INTO [Configuration].[DiskLocations]
					   ([FileExtension]
					   ,[FilePath])
				 VALUES
					   (@FileExtension
					   ,@FileDirectory)
					   
			SET @LogEntry = 'Registered new Disk Location: File Extension = ' + @FileExtension + ', Directory = ' + @FileDirectory
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'New Disk Location entry inserted.'
			END
		END
		ELSE
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'Disk Location already existed, moving on.'
			END
		END      

		--Set Disklocation ID
		SELECT @DiskLocationINT = DiskLocationID
		FROM [Configuration].[DiskLocations]
		WHERE [FileExtension] = @FileExtension
			AND [FilePath] = @FileDirectory

		IF @debug = 1
		BEGIN
			PRINT 'Selected DiskLocationID = ' + ISNULL(CAST(@DiskLocationINT AS VARCHAR),'NULL')
		END 

		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback
		
		--Ensure the RegisteredDatabases are up-to-date before mapping the foreign keys.
		EXEC [Configuration].[usp_RefreshRegisteredDatabases] 

		IF @debug = 1
		BEGIN
			PRINT 'Registered Databases have been refreshed.'
		END 

		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback

		--Create new trace option if it doesn't exist
		IF NOT EXISTS	(
							SELECT [OptionID]
							FROM [Trace].[Options]
							WHERE [DiskLocationID] = @DiskLocationINT
								  AND [TraceName] = @TraceName
								  AND [PurgeDays] = @PurgeDays
								  AND [MaxFileSize] = @MaxFileSize
								  AND ISNULL(CAST([QueryRunTime] AS VARCHAR),'NULL') = ISNULL(CAST(@QueryRunTime AS VARCHAR),'NULL')
								  AND ISNULL(CAST([Reads] AS VARCHAR),'NULL') = ISNULL(CAST(@Reads AS VARCHAR),'NULL')
								  AND ISNULL(CAST([Writes] AS VARCHAR),'NULL') = ISNULL(CAST(@Writes AS VARCHAR),'NULL')
						)
		BEGIN
			INSERT INTO [Trace].[Options]
				   (
						[DiskLocationID]
					   ,[TraceName]
					   ,[PurgeDays]
					   ,[MaxFileSize]
					   ,[QueryRunTime]
					   ,[Reads]
					   ,[Writes]
				   )
			 VALUES
				   (
					   @DiskLocationINT
					   ,@TraceName
					   ,@PurgeDays
					   ,@MaxFileSize
					   ,@QueryRunTime
					   ,@Reads
					   ,@Writes
				   )

			SET @LogEntry = 'Created new Query Trace Option: [DiskLocationID] = ' + CAST(@DiskLocationINT AS VARCHAR(10)) + ', [TraceName] = ' + CAST(@TraceName AS VARCHAR(100)) + ', [PurgeDays] = ' + CAST(@PurgeDays AS VARCHAR(10)) +
				 ', [MaxFileSize] = ' + CAST(@MaxFileSize AS VARCHAR(20)) + ', [QueryRunTime] = ' + CAST(@QueryRunTime AS VARCHAR(20)) + ', [Reads] = ' + CAST(@Reads AS VARCHAR(20)) + ', [Writes] = ' + CAST(@Writes AS VARCHAR(20))
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback

			IF @debug = 1
			BEGIN
				PRINT 'INSERT of new Trace Option is complete.'
			END
		END
		ELSE      
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'Trace Option already existed, moving on.'
			END
		END
  
		--Set trace option ID
		SELECT @OptionID = [OptionID]
		FROM [Trace].[Options]
		WHERE [DiskLocationID] = @DiskLocationINT
			AND [TraceName] = @TraceName
			AND [PurgeDays] = @PurgeDays
			AND [MaxFileSize] = @MaxFileSize
			AND ISNULL(CAST([QueryRunTime] AS VARCHAR),'NULL') = ISNULL(CAST(@QueryRunTime AS VARCHAR),'NULL')
			AND ISNULL(CAST([Reads] AS VARCHAR),'NULL') = ISNULL(CAST(@Reads AS VARCHAR),'NULL')
			AND ISNULL(CAST([Writes] AS VARCHAR),'NULL') = ISNULL(CAST(@Writes AS VARCHAR),'NULL')

		--Populate Databases List
		DECLARE Trace_Databases_Cursor CURSOR FAST_FORWARD FOR
			SELECT DatabaseName
			FROM [dbo].[udf_DatabaseSelect] (@Databases,1)
		
		OPEN Trace_Databases_Cursor
		FETCH NEXT FROM Trace_Databases_Cursor INTO @DatabaseName

		WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'Trace_Databases_Cursor' ) = 0 
		BEGIN
			--Find the Registered ID associated to this database name.      
			SELECT @DatabaseID = DatabaseID
			FROM [Configuration].[RegisteredDatabases]
			WHERE databasename = @DatabaseName
			--Insert into the Trace.Databases table if needed.
			IF NOT EXISTS	(
								SELECT [TraceDatabaseID] 
								FROM [Trace].[Databases] 
								WHERE [DatabaseID] = @DatabaseID 
									AND [OptionID] = @OptionID
							)
			BEGIN
				INSERT INTO [Trace].[Databases]
						   ([DatabaseID]
						   ,[OptionID])
					 VALUES
						   (@DatabaseID
						   ,@OptionID)
			END
			--Fetch next database name.
			FETCH NEXT FROM Trace_Databases_Cursor INTO @DatabaseName
		END
  
		CLOSE Trace_Databases_Cursor
		DEALLOCATE Trace_Databases_Cursor      
        
		SET @LogEntry = 'Query Trace Option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' now associated with database(s): ' + @Databases
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
        
		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback

		IF @debug = 1
		BEGIN
			PRINT 'Associated databases to Trace Option.'
		END

	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'New Trace Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		PRINT @LogEntry
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:

	SET NOCOUNT OFF  
GO