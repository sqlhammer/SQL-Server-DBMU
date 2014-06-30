/*
PROCEDURE:		[Logging].[usp_AlterLoggingOption]
AUTHOR:			Derik Hammer
CREATION DATE:	10/11/2012
DESCRIPTION:	This procedure is used to alter an existing logging option. 
PARAMETERS:		@OptionID INT --Mandatory OptionID to be updated.
				@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@LoggingModeDesc VARCHAR(50) = NULL --Logging mode to use.
				@PurgeType VARCHAR(50) = NULL --Type of purge to be performed by this option.
				@PurgeValue INT = NULL --Value to indicate how many days or files to keep.
				@Features VARCHAR(8000) = NULL --Comma separated list of database list.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Logging].[usp_AlterLoggingOption]
	@OptionID INT,
	@debug BIT = 0,
	@LoggingModeDesc VARCHAR(50) = NULL,
	@PurgeType VARCHAR(50) = NULL,
	@PurgeValue INT = NULL,
	@Features VARCHAR(8000) = NULL,
	@RemoveFeatureList BIT = 0  
AS
	SET NOCOUNT ON

	--Declare variables
	DECLARE @OptionsID INT
	DECLARE @FeatureID INT
	DECLARE @ErrorMsg VARCHAR(8000)
	DECLARE @UpdateStatement VARCHAR(8000)
	DECLARE @FeatureName SYSNAME
	--Current settings storage variables
	DECLARE @CurrentLoggingModeID VARCHAR(50)
	DECLARE @CurrentPurgeTypeID INT
	DECLARE @CurrentPurgeValue INT
	--Requested settings storage variables
	DECLARE @RequestedLoggingModeID VARCHAR(50)
	DECLARE @RequestedPurgeTypeID INT
	DECLARE @RequestedPurgeValue INT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)
	
	--This entire procedure is an all or nothing transaction
	BEGIN TRANSACTION 

		/*		Populate current option information for debugging and reference		*/
		--Validate that it exists.
		IF NOT EXISTS	(
							SELECT  [OptionID]
							FROM [Logging].[Options]
							WHERE [OptionID] = @OptionID
						)
		BEGIN
			SET @ErrorMsg = 'Cannot alter Logging OptionID ' + ISNULL(CAST(@OptionID AS VARCHAR(10)),'NULL') + ' because it does not exist.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @ErrorMsg, @LogMode = 'LIMITED'          
			RAISERROR(@ErrorMsg,16,1)
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END

		SELECT	@CurrentLoggingModeID = [LoggingModeID],
				@CurrentPurgeTypeID = [PurgeTypeID],
				@CurrentPurgeValue = [PurgeValue]
		FROM [Logging].[Options]
		WHERE [OptionID] = @OptionID

		IF @debug = 1
		BEGIN
			PRINT '----------Current Logging Option Settings----------'
			PRINT '--LoggingModeID = ' + CAST(@CurrentLoggingModeID AS VARCHAR)
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

		--Set/Validate LoggingModeID.
		IF @LoggingModeDesc IS NOT NULL
		BEGIN      
			IF EXISTS	(
							SELECT LoggingModeID
							FROM [Lookup].[LoggingModes]
							WHERE LoggingModeDesc = @LoggingModeDesc
						)
				BEGIN
					SELECT @RequestedLoggingModeID = [LoggingModeID]
					FROM [Lookup].[LoggingModes]
					WHERE LoggingModeDesc = @LoggingModeDesc
				END
			ELSE      
				BEGIN
					SET @ErrorMsg = 'Error: Logging Mode ''' + @LoggingModeDesc + ''' does not match an existing purge type.'      
					RAISERROR(@ErrorMsg,16,1)
					GOTO QuitWithRollback
				END
			
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedLoggingModeID, derived from @LoggingModeDesc, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END
		ELSE
		BEGIN      
			SELECT @RequestedLoggingModeID = @CurrentLoggingModeID
			
			IF @debug = 1
			BEGIN
				PRINT 'Population of @RequestedLoggingModeID, derived from @LoggingModeDesc, complete.'
			END

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END  
        
		--Set new feature list
		IF @Features IS NOT NULL
		BEGIN
			--If @RemoveFeatureList = 0 then append the features from the list provided if they don't already exist.
			IF @RemoveFeatureList = 0
			BEGIN
				--Add new feature references to the [Logging].[Features] table for @FeatureID
				IF @debug = 1
				BEGIN
					PRINT 'Insert new features references.'
					PRINT 'INSERT INTO [Logging].[Features] ([DatabaseID], [OptionID])' + CHAR(13) + CHAR(10) +
					'	SELECT Feats.FeatureID, @OptionID' + CHAR(13) + CHAR(10) +
					'	FROM [dbo].[udf_FeatureSelect] (@Features) FeatSelection' + CHAR(13) + CHAR(10) +
					'	INNER JOIN [Lookup].[Features] Feats ON FeatSelection.FeatureName = Feats.FeatureName' + CHAR(13) + CHAR(10) +
					'	WHERE FeatSelection.FeatureName NOT IN (SELECT Feats.FeatureName' + CHAR(13) + CHAR(10) +
					'								FROM [dbo].[udf_FeatureSelect] (@Features) DBlist' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [Lookup].[Features] Feats ON FeatSelection.FeatureName = Feats.FeatureName' + CHAR(13) + CHAR(10) +
					'								INNER JOIN [Logging].[Features] LogFeats ON Feats.FeatureID = LogFeats.FeatureID' + CHAR(13) + CHAR(10) +
					'								WHERE FeatureID.OptionID = @OptionID)'
				END
				ELSE
				BEGIN
					INSERT INTO [Logging].[Features] ([FeatureID], [OptionID])
						SELECT Feats.FeatureID, @OptionID
						FROM [dbo].[udf_FeatureSelect] (@Features) FeatSelection
						INNER JOIN [Lookup].[Features] Feats ON FeatSelection.FeatureName = Feats.FeatureName
						WHERE FeatSelection.FeatureName NOT IN (SELECT Feats.FeatureName
													FROM [dbo].[udf_FeatureSelect] (@Features) FeatSelection
													INNER JOIN [Lookup].[Features] Feats ON FeatSelection.FeatureName = Feats.FeatureName
													INNER JOIN [Logging].[Features] LogFeats ON Feats.FeatureID = LogFeats.FeatureID
													WHERE LogFeats.OptionID = @OptionID)

					SET @LogEntry = 'Inserted additional feature(s) to Logging Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Feature list = ' + @Features
					EXEC Logging.usp_InsertLogEntry @Feature = 'Logging',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END
			END
			ELSE --If @RemoveFeatureList = 1 then keep the current list but remove the features listed in the inputed list.
			BEGIN
				--Delete records from the [Logging].[Features] table based on the list of database names provided.
				IF @debug = 1
				BEGIN
					PRINT 'Deleting feature references.'      
					PRINT 'DELETE LogFeats' + CHAR(13) + CHAR(10) +
					'FROM [Logging].[Features] LogFeats' + CHAR(13) + CHAR(10) +
					'INNER JOIN [Lookup].[Features] Feats ON Feats.FeatureID = LogFeats.FeatureID' + CHAR(13) + CHAR(10) +
					'INNER JOIN [dbo].[udf_FeatureSelect] (@Features) Featlist ON Featlist.FeatureName = Feats.FeatureName' + CHAR(13) + CHAR(10) +
					'WHERE LogFeats.OptionID = @OptionID'     
				END
				ELSE             
				BEGIN
					--Delete the feature reference to @OptionID
					DELETE LogFeats
					FROM [Logging].[Features] LogFeats
					INNER JOIN [Lookup].[Features] Feats ON Feats.FeatureID = LogFeats.FeatureID
					INNER JOIN [dbo].[udf_FeatureSelect] (@Features) Featlist ON Featlist.FeatureName = Feats.FeatureName
					WHERE LogFeats.OptionID = @OptionID

					SET @LogEntry = 'Delete the feature(s) reference to Logging option ID ' + CAST(@OptionID AS VARCHAR(10)) + ' from [Logging].[Databases].'
					EXEC Logging.usp_InsertLogEntry @Feature = 'Logging',	@TextEntry = @LogEntry, @LogMode = 'VERBOSE'

					SET @LogEntry = 'Finished deleting listed feature(s) related to Logging Option ID ' + CAST(@OptionID AS VARCHAR(10)) + '. Purged Feature list = ' + @Features
					EXEC Logging.usp_InsertLogEntry @Feature = 'Logging',	@TextEntry = @LogEntry, @LogMode = 'LIMITED'
				END
					
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		END

		--Construct UPDATE statement.
		SET @UpdateStatement =	'UPDATE [Logging].[Options]' +
			' SET [LoggingModeID] = ' + CAST(@RequestedLoggingModeID AS VARCHAR) +
			', [PurgeValue] = ' + CAST(@RequestedPurgeValue AS VARCHAR) +
			', [PurgeTypeID] = ' + CAST(@RequestedPurgeTypeID AS VARCHAR) +
			' WHERE [OptionID] = ' + CAST(@OptionID AS VARCHAR)

		--Execute
		IF @debug = 1
		BEGIN
			PRINT '----------Requested Logging Option Settings----------'
			PRINT '--LoggingModeID = ' + CAST(@RequestedLoggingModeID AS VARCHAR)
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
			EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @UpdateStatement, @LogMode = 'LIMITED'      
			EXEC ( @UpdateStatement )

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback  
		END      

	--Commit
	COMMIT TRANSACTION 
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'Alter Logging Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		PRINT @LogEntry
		EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	EndSave:

	SET NOCOUNT OFF  
GO