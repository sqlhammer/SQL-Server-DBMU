/*
PROCEDURE:		[DiskCleanup].[usp_AlterDiskCleanupOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to alter an existing Disk Cleanup option. 
PARAMETERS:		@OptionID INT --Mandatory OptionID to be updated.
				@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@FileDirectory VARCHAR(8000) = NULL --Directory to check the files.
				@FileExtension VARCHAR(4) = NULL --File extension to search for.
				@PurgeType VARCHAR(50) = NULL --Type of backup to be performed by this option.
				@PurgeValue INT = NULL --Value to indicate how many days or files to keep.
				@Databases VARCHAR(8000) = NULL --Comma separated list of database list.
				@RemoveDBList BIT = 0 --Used to indicate whether to add or subtract the database list.
				@ValidateDatabasesExists BIT = 1 --If 1, CSV elements which don't match and existing database will be ignored.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/16/2012 --	Rewrote the database list portion of the procedure to perform insert or delete operations rather than a purge and reinsert
									method of populating the database list. This enabled me to remove a cursor and the user will no longer need to know or type
									the full list of databases registered to an OptionID to make the alteration.

** Derik Hammer ** 03/20/2013 --	Added new parameter required for udf_DatabaseSelect to ensure database name validation.

** Derik Hammer ** 09/06/2013 --	Set XACT_ABORT to ON so that the first error in a transaction will roll back and not continue to execute further commands.

** Derik Hammer ** 09/07/2013 --	Created the @ValidateDatabasesExists parameter for passing into the udf_DatabaseSelect function.

*/
CREATE PROCEDURE [DiskCleanup].[usp_AlterDiskCleanupOption]
	@OptionID INT,
	@debug BIT = 0,
	@FileDirectory VARCHAR(MAX) = NULL,
	@FileExtension VARCHAR(4) = NULL,
	@PurgeType VARCHAR(50) = NULL,
	@PurgeValue INT = NULL,
	@Databases VARCHAR(MAX) = NULL,
	@RemoveDBList BIT = 0,
	@ValidateDatabasesExist BIT = 1
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Declare variables
	DECLARE @OptionsID INT
	DECLARE @DiskLocationID INT 
	DECLARE @DatabaseID INT
	DECLARE @ErrorMsg VARCHAR(MAX)
	DECLARE @UpdateStatement VARCHAR(MAX)
	DECLARE @DatabaseName SYSNAME
	--Current settings storage variables
	DECLARE @CurrentFileExtension VARCHAR(4)
	DECLARE @CurrentFileDirectory VARCHAR(MAX)
	DECLARE @CurrentPurgeTypeID INT
	DECLARE @CurrentPurgeValue INT
	DECLARE @CurrentDiskLocationID INT
	--Requested settings storage variables
	DECLARE @RequestedFileExtension VARCHAR(4)
	DECLARE @RequestedFileDirectory VARCHAR(MAX)
	DECLARE @RequestedPurgeTypeID INT
	DECLARE @RequestedPurgeValue INT
	DECLARE @RequestedDiskLocationID INT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION 

		/*		Populate current option information for debugging and reference		*/
		--Validate that it exists.
		IF NOT EXISTS	(
							SELECT  [OptionID]
							FROM [DiskCleanup].[Options]
							WHERE [OptionID] = @OptionID
						)
		BEGIN
			SET @ErrorMsg = 'Cannot alter Disk Cleanup OptionID ' + ISNULL(CAST(@OptionID AS VARCHAR(10)),'NULL') + ' because it does not exist.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'          
			RAISERROR(@ErrorMsg,16,1)
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END

		SELECT	@CurrentDiskLocationID = [DiskLocationID],
				@CurrentPurgeTypeID = [PurgeTypeID],
				@CurrentPurgeValue = [PurgeValue]
		FROM [DiskCleanup].[Options]
		WHERE [OptionID] = @OptionID

		SELECT @CurrentFileExtension = [FileExtension],
				@CurrentFileDirectory = [FilePath]
		FROM [Configuration].[DiskLocations]
		WHERE [DiskLocationID] = @CurrentDiskLocationID

		IF @debug = 1
		BEGIN
			PRINT '----------Current Disk Cleanup Option Settings----------'
			PRINT '--DiskLocationID = ' + CAST(@CurrentDiskLocationID AS VARCHAR)
			PRINT '--PurgeTypeID = ' + CAST(@CurrentPurgeTypeID AS VARCHAR)
			PRINT '--PurgeValue = ' + CAST(@CurrentPurgeValue AS VARCHAR)
			PRINT '--------------------------------------------------------'
			PRINT ''
		END

		/*		Populate requested option information for debugging and reference	*/

		--Set/Validate Purge Type ID.
		IF @PurgeType IS NOT NULL
		BEGIN      
			IF EXISTS	(
							SELECT PurgeTypeID
							FROM [Lookup].[PurgeTypes]
							WHERE PurgeTypeDesc = @PurgeType
						)
				BEGIN
					SELECT @RequestedPurgeTypeID = [PurgeTypeID]
					FROM [Lookup].[PurgeTypes]
					WHERE [PurgeTypeDesc] = @PurgeType
				END
			ELSE      
				BEGIN
					SET @ErrorMsg = 'Error: Purge Type ''' + @PurgeType + ''' does not match an existing purge type.'      
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'          
					RAISERROR(@ErrorMsg,16,1)
					GOTO QuitWithRollback
				END
			
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeTypeID, derived from @PurgeType, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SELECT @RequestedPurgeTypeID = @CurrentPurgeTypeID
			
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeTypeID, derived from @CurrentPurgeTypeID, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END  

		--Set/Validate Purge Value.
		IF @PurgeValue IS NOT NULL
		BEGIN      
			SELECT @RequestedPurgeValue = @PurgeValue
						
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeValue, derived from @PurgeValue, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SELECT @RequestedPurgeValue = @CurrentPurgeValue
						
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedPurgeValue, derived from @CurrentPurgeValue, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END

		--Set/Validate File extension.
		IF @FileExtension IS NOT NULL
		BEGIN      
			SET @RequestedFileExtension = REPLACE(@FileExtension,'.','')

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFileExtension, derived from @FileExtension, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedFileExtension = @CurrentFileExtension

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFileExtension, derived from @CurrentFileExtension, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback          
		END
  
		--Set/Validate Directory.
		IF @FileDirectory IS NOT NULL
		BEGIN      
			SET @RequestedFileDirectory = REPLACE(@FileDirectory,'.','')

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFileDirectory, derived from @FileDirectory, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SET @RequestedFileDirectory = @CurrentFileDirectory

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedFileDirectory, derived from @CurrentFileDirectory, complete.'
			END
  
			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback          
		END
  
		--Create disk location record if not exists
		IF @FileDirectory IS NOT NULL OR @FileExtension IS NOT NULL
		BEGIN
			SELECT	@CurrentFileDirectory = [FilePath],
					@CurrentFileExtension = [FileExtension]
			FROM [Configuration].[DiskLocations]
			WHERE [DiskLocationID] = @CurrentDiskLocationID
			      
			IF NOT EXISTS	(
								SELECT [DiskLocationID]
								FROM [Configuration].[DiskLocations]
								WHERE [FileExtension] = ISNULL(@FileExtension,@CurrentFileExtension)
									AND [FilePath] = ISNULL(@FileDirectory,@CurrentFileDirectory)
							)
				BEGIN
					INSERT INTO [Configuration].[DiskLocations]
					(
						[FileExtension],
						[FilePath]
					)
					VALUES
					(
						ISNULL(@FileExtension,@CurrentFileExtension),
						ISNULL(@FileDirectory,@CurrentFileDirectory)
					)

					SET @LogEntry = 'Registered new Disk Location: File Extension = ' + ISNULL(@FileExtension,@CurrentFileExtension) + ', Directory = ' + ISNULL(@FileDirectory,@CurrentFileDirectory)
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				
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
			WHERE [FileExtension] = ISNULL(@FileExtension,@CurrentFileExtension)
				AND [FilePath] = ISNULL(@FileDirectory,@CurrentFileDirectory)

			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedDiskLocationID, derived from @FileDirectory and @FileExtension, complete.'
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
        
		--Set new database list
		IF @Databases IS NOT NULL
		BEGIN
			--If @RemoveDBList = 0 then append the databases from the list provided if they don't already exist.
			IF @RemoveDBList = 0
			BEGIN
				--Add new database references to the [DiskCleanup].[Databases] table for @OptionID
				IF @debug = 1
				BEGIN
					PRINT 'Insert new database references.'
					PRINT 'INSERT INTO [DiskCleanup].[Databases] ([DatabaseID], [OptionID])' + CHAR(13) + CHAR(10) +
					'	SELECT rDBs.DatabaseID, @OptionID' + CHAR(13) + CHAR(10) +
					'	FROM [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBSelection' + CHAR(13) + CHAR(10) +
					'	INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'	WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'								FROM [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBlist' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [DiskCleanup].[Databases] DiskDBs ON regDBs.DatabaseID = DiskDBs.DatabaseID' + CHAR(13) + CHAR(10) +
					'								WHERE DiskDBs.OptionID = @OptionID)'
				END
				ELSE
				BEGIN
					INSERT INTO [DiskCleanup].[Databases] ([DatabaseID], [OptionID])
						SELECT rDBs.DatabaseID, @OptionID
						FROM [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBSelection
						INNER JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName
						WHERE DBSelection.DatabaseName NOT IN (SELECT regDBs.DatabaseName
													FROM [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBlist
													INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON DBlist.DatabaseName = regDBs.DatabaseName
													INNER JOIN [DiskCleanup].[Databases] DiskDBs ON regDBs.DatabaseID = DiskDBs.DatabaseID
													WHERE DiskDBs.OptionID = @OptionID)
					
					SET @LogEntry = 'Inserted additional databases to Disk Cleanup Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Database list = ' + @Databases
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END
			END
			ELSE --If @RemoveDBList = 1 then keep the current list but remove the databases listed in the inputted list.
			BEGIN
				--Delete records from the [DiskCleanup].[Databases] table based on the list of database names provided.
				IF @debug = 1
				BEGIN
					PRINT 'Deleting database references.'      
					PRINT 'DELETE DiskDBs' + CHAR(13) + CHAR(10) +
					'FROM [DiskCleanup].[Databases] DiskDBs' + CHAR(13) + CHAR(10) +
					'INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = DiskDBs.DatabaseID' + CHAR(13) + CHAR(10) +
					'INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,' + CAST(@ValidateDatabasesExist AS CHAR(1)) + ') DBlist ON DBlist.DatabaseName = regDBs.DatabaseName' + CHAR(13) + CHAR(10) +
					'WHERE DiskDBs.OptionID = @OptionID'     
				END
				ELSE             
				BEGIN
					--Delete the database reference to @OptionID
					DELETE DiskDBs
					FROM [DiskCleanup].[Databases] DiskDBs
					INNER JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseID = DiskDBs.DatabaseID
					INNER JOIN [dbo].[udf_DatabaseSelect] (@Databases,@ValidateDatabasesExist) DBlist ON DBlist.DatabaseName = regDBs.DatabaseName
					WHERE DiskDBs.OptionID = @OptionID

					SET @LogEntry = 'Delete the database reference to Disk Cleanup option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' from [DiskCleanup].[Databases].'
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup',	@TextEntry = @LogEntry, @LogMode = 'VERBOSE'

					SET @LogEntry = 'Finished deleting listed databases related to Disk Cleanup Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Purged Database list = ' + @Databases
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
				END
					
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		END      
		
		--Construct UPDATE statement.
		SET @UpdateStatement =	'UPDATE [DiskCleanup].[Options]' +
			' SET [DiskLocationID] = ' + CAST(@RequestedDiskLocationID AS VARCHAR) +
			', [PurgeValue] = ' + CAST(@RequestedPurgeValue AS VARCHAR) +
			', [PurgeTypeID] = ' + CAST(@RequestedPurgeTypeID AS VARCHAR) +
			' WHERE [OptionID] = ' + CAST(@OptionID AS VARCHAR)

		--Execute
		IF @debug = 1
		BEGIN
			PRINT '----------Requested Disk Cleanup Option Settings----------'
			PRINT '--DiskLocationID = ' + CAST(@RequestedDiskLocationID AS VARCHAR)
			PRINT '--PurgeTypeID = ' + CAST(@RequestedPurgeTypeID AS VARCHAR)
			PRINT '--PurgeValue = ' + CAST(@RequestedPurgeValue AS VARCHAR)
			PRINT '----------------------------------------------------------'
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
			EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup',	@TextEntry = @UpdateStatement, @LogMode = 'LIMITED'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback  
		END      

	--Commit
	COMMIT TRANSACTION 
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'Alter Disk Cleanup Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		PRINT @LogEntry
		EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	EndSave:

	SET NOCOUNT OFF  
GO