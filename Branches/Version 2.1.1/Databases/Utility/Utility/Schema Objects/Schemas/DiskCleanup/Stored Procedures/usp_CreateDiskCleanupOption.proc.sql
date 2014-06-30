/*
PROCEDURE:		[DiskCleanup].[usp_CreateDiskCleanupOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to create a new disk cleanup option. This includes selecting or creating a new option, creating
				a new entry in DiskCleanup.Configs and selecting or creating and umbrella configuration (Configuration.Configs). Most parameters
				are required and the procedure will decide if an identical match exists.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@FileDirectory VARCHAR(MAX) --Directory to search when purging.
				@FileExtension VARCHAR(4) --File extension to search for.
				@PurgeType VARCHAR(50) --Type of purging to be performed by this option.
				@PurgeValue INT --Number of days or files to keep in the selected directory.
				@Databases VARCHAR(MAX) --Comma separated list of databases to include in the purging.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

*/
CREATE PROCEDURE [DiskCleanup].[usp_CreateDiskCleanupOption]
	@debug BIT = 0,
	@FileDirectory VARCHAR(8000),
	@FileExtension VARCHAR(4),
	@PurgeType VARCHAR(50),
	@PurgeValue INT,
	@Databases VARCHAR(8000)
AS
	SET NOCOUNT ON

	--Declare variables
	DECLARE @DiskLocationINT INT
	DECLARE @PurgeTypeID INT
	DECLARE @OptionID INT
	DECLARE @DatabaseName SYSNAME
	DECLARE @DatabaseID INT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION

		/*			Select or create disk cleanup option			*/
		--Remove periods from file extension
		SET @FileExtension = REPLACE(@FileExtension,'.','')

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
			EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

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
		
		--Polulate Lookups.PurgeTypes
		IF NOT EXISTS (SELECT [PurgeTypeID] FROM [Lookup].[PurgeTypes] WHERE [PurgeTypeDesc] = 'PURGE BY DAYS')
			INSERT INTO [Utility].[Lookup].[PurgeTypes] ([PurgeTypeDesc]) VALUES ('PURGE BY DAYS')
		IF NOT EXISTS (SELECT [PurgeTypeID] FROM [Lookup].[PurgeTypes] WHERE [PurgeTypeDesc] = 'PURGE BY NUMBER OF FILES')
			INSERT INTO [Utility].[Lookup].[PurgeTypes] ([PurgeTypeDesc]) VALUES ('PURGE BY NUMBER OF FILES')

		IF EXISTS (SELECT [PurgeTypeID] FROM [Lookup].[PurgeTypes] WHERE [PurgeTypeDesc] = @PurgeType)
		BEGIN
			SELECT @PurgeTypeID = [PurgeTypeID]
			FROM [Lookup].[PurgeTypes]
			WHERE [PurgeTypeDesc] = @PurgeType

			IF @debug = 1
			BEGIN
				PRINT 'The Purge Type requested is valid.'
			END 
		END
		ELSE
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'The Purge Type requested does not exists and therefore is invalid.'

				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		END

		--INSERT Option Settings
		IF NOT EXISTS	(
							SELECT [OptionID]
							FROM [DiskCleanup].[Options]
							WHERE [DiskLocationID] = @DiskLocationINT
								AND [PurgeValue] = @PurgeValue
								AND [PurgeTypeID] = @PurgeTypeID
						)
			BEGIN
				INSERT INTO [DiskCleanup].[Options]
					   ([DiskLocationID]
					   ,[PurgeValue]
					   ,[PurgeTypeID])
				VALUES
					   (@DiskLocationINT
					   ,@PurgeValue
					   ,@PurgeTypeID)

				SET @LogEntry = 'Created new Disk Cleanup Option: [DiskLocationID] = ' + CAST(@DiskLocationINT AS VARCHAR(10)) + ', [PurgeValue] = ' + CAST(@PurgeValue AS VARCHAR(10)) + ', [PurgeTypeID] = ' + CAST(@PurgeTypeID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

				IF @debug = 1
				BEGIN
					PRINT 'New Disk Cleanup Option inserted.'
				END
				
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
			ELSE
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Disk Cleanup Option set already existed, moving on.'
				END
			END
  
		--Set OptionID
		SELECT @OptionID = [OptionID]
		FROM [DiskCleanup].[Options]
		WHERE [DiskLocationID] = @DiskLocationINT
			AND [PurgeValue] = @PurgeValue
			AND [PurgeTypeID] = @PurgeTypeID

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
								SELECT [DiskCleanupDatabaseID] 
								FROM [DiskCleanup].[Databases] 
								WHERE [DatabaseID] = @DatabaseID 
									AND [OptionID] = @OptionID
							)
			BEGIN
				INSERT INTO [DiskCleanup].[Databases] 
						   ([DatabaseID]
						   ,[OptionID])
					 VALUES
						   (@DatabaseID
						   ,@OptionID)
			END
			--Fetch next database name.
			FETCH NEXT FROM Databases_Cursor INTO @DatabaseName
		END
  
		CLOSE Databases_Cursor
		DEALLOCATE Databases_Cursor
  
		SET @LogEntry = 'Disk Cleanup Option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' now associated with database(s): ' + @Databases
		EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
        
		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback
		
	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'New Disk Cleanup Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		PRINT @LogEntry
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:

	SET NOCOUNT OFF  
GO