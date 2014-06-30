/*
PROCEDURE:		[Logging].[usp_CreateLoggingOption]
AUTHOR:			Derik Hammer
CREATION DATE:	10/11/2012
DESCRIPTION:	This procedure is used to create a new logging option. Most parameters are required and 
					the procedure will decide if an identical match exists.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@LoggingModeDesc VARCHAR(50) --Logging mode to use.
				@PurgeType VARCHAR(50) --Type of purging to be performed by this option.
				@PurgeValue INT --Number of days or files to keep in the selected directory.
				@Features VARCHAR(8000) --Comma separated list of features to include in the purging.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 09/06/2013 --	Set return value to provide user with the new option id.

*/
CREATE PROCEDURE [Logging].[usp_CreateLoggingOption]
	@debug BIT = 0,
	@LoggingModeDesc VARCHAR(50),
	@PurgeType VARCHAR(50),
	@PurgeValue INT,
	@Features VARCHAR(8000)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON  

	--Declare variables
	DECLARE @PurgeTypeID INT
	DECLARE @LoggingModeID INT
	DECLARE @OptionID INT
	DECLARE @FeatureName SYSNAME
	DECLARE @FeatureID INT
	DECLARE @ReturnValue INT = 0;
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION

		/*			Select or create Logging option			*/
		
		--Polulate Lookups.PurgeTypes
		IF NOT EXISTS (SELECT [PurgeTypeID] FROM [Lookup].[PurgeTypes] WHERE [PurgeTypeDesc] = 'PURGE BY DAYS')
			INSERT INTO [Utility].[Lookup].[PurgeTypes] ([PurgeTypeDesc]) VALUES ('PURGE BY DAYS')
		IF NOT EXISTS (SELECT [PurgeTypeID] FROM [Lookup].[PurgeTypes] WHERE [PurgeTypeDesc] = 'PURGE BY NUMBER OF ROWS')
			INSERT INTO [Utility].[Lookup].[PurgeTypes] ([PurgeTypeDesc]) VALUES ('PURGE BY NUMBER OF ROWS')

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

		--Populate [Lookup].[LoggingModes]
		IF NOT EXISTS (SELECT LoggingModeID FROM [Lookup].[LoggingModes] WHERE LoggingModeDesc = 'LIMITED')
			INSERT INTO [Lookup].[LoggingModes] (LoggingModeDesc) VALUES ('LIMITED')
		IF NOT EXISTS (SELECT LoggingModeID FROM [Lookup].[LoggingModes] WHERE LoggingModeDesc = 'VERBOSE')
			INSERT INTO [Lookup].[LoggingModes] (LoggingModeDesc) VALUES ('VERBOSE')

		IF EXISTS (SELECT LoggingModeID FROM [Lookup].[LoggingModes] WHERE LoggingModeDesc = @LoggingModeDesc)
		BEGIN
			SELECT @LoggingModeID = LoggingModeID
			FROM [Lookup].[LoggingModes]
			WHERE LoggingModeDesc = @LoggingModeDesc

			IF @debug = 1
			BEGIN
				PRINT 'The Logging Mode requested is valid.'
			END 
		END
		ELSE
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'The Logging Mode requested does not exists and therefore is invalid.'

				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		END

		--INSERT Option Settings
		IF NOT EXISTS	(
							SELECT [OptionID]
							FROM [Logging].[Options]
							WHERE [LoggingModeID] = @LoggingModeID
								AND [PurgeValue] = @PurgeValue
								AND [PurgeTypeID] = @PurgeTypeID
						)
			BEGIN
				INSERT INTO [Logging].[Options]
					   ([LoggingModeID]
					   ,[PurgeValue]
					   ,[PurgeTypeID])
				VALUES
					   (@LoggingModeID
					   ,@PurgeValue
					   ,@PurgeTypeID)

				SET @LogEntry = 'Created new Logging Option: [LoggingModeID] = ' + CAST(@LoggingModeID AS VARCHAR(10)) + ', [PurgeValue] = ' + CAST(@PurgeValue AS VARCHAR(10)) + ', [PurgeTypeID] = ' + CAST(@PurgeTypeID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

				IF @debug = 1
				BEGIN
					PRINT 'New Logging Option inserted.'
				END
				
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
			ELSE
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Logging Option set already existed, moving on.'
				END
			END
  
		--Set OptionID
		SELECT @OptionID = [OptionID]
		FROM [Logging].[Options]
		WHERE [LoggingModeID] = @LoggingModeID
			AND [PurgeValue] = @PurgeValue
			AND [PurgeTypeID] = @PurgeTypeID

		--Populate Feature List
		DECLARE Features_Cursor CURSOR FAST_FORWARD FOR
		SELECT FeatureName --The Database udf is being used for this purpose even though they are features
		FROM [dbo].[udf_FeatureSelect] (@Features)
		
		OPEN Features_Cursor
		FETCH NEXT FROM Features_Cursor INTO @FeatureName

		WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'Features_Cursor' ) = 0 
		BEGIN
			--Find the ID associated to this feature name.      
			SELECT @FeatureID = FeatureID
			FROM [Lookup].[Features]
			WHERE FeatureName = @FeatureName

			--Insert into the [Logging].[Features] table if needed.
			IF NOT EXISTS	(
								SELECT [LoggingFeatureID] 
								FROM [Logging].[Features] 
								WHERE FeatureID = @FeatureID 
									AND [OptionID] = @OptionID
							)
			BEGIN
				INSERT INTO [Logging].[Features] 
						   ([FeatureID]
						   ,[OptionID])
					 VALUES
						   (@FeatureID
						   ,@OptionID)

				SET @LogEntry = 'Logging Option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' now associated with feature(s): ' + @Features
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			END
			--Fetch next Feature name.
			FETCH NEXT FROM Features_Cursor INTO @FeatureName
		END
  
		CLOSE Features_Cursor
		DEALLOCATE Features_Cursor
        
		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback
		
	--Commit
	COMMIT TRANSACTION
	SET @ReturnValue = @OptionID;
    
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'New Logging Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

		PRINT @LogEntry
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:

	SET NOCOUNT OFF  
	RETURN ISNULL(@ReturnValue,0);
GO