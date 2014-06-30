/*
PROCEDURE:		[Logging].[usp_DropLoggingOption]
AUTHOR:			Derik Hammer
CREATION DATE:	10/11/2012
DESCRIPTION:	This procedure is used to drop an existing logging option and it's associated configs.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Equates to the Logging.Options.OptionID value needed to drop the correct Logging option.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Logging].[usp_DropLoggingOption]
	@ID INT,
	@debug BIT = 0
AS
	SET NOCOUNT ON

	--Declare Variables
	DECLARE @Configs TABLE ( ConfigID INT )
	DECLARE @FeatureReferences TABLE ( LoggingFeatureID INT, FeatureName SYSNAME )
	DECLARE @debugID INT
	DECLARE @debugSYSNAME SYSNAME
	DECLARE @debugUNIQUEIDENTIFIER UNIQUEIDENTIFIER
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION

		/*				Drop associated Logging configs			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Logging].[Configs] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [Logging].[Configs] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of configs to be dropped.
				INSERT INTO @Configs (ConfigID)
					SELECT ConfigID FROM [Logging].[Configs] WHERE [OptionID] = @ID

				--Print out the list for review
				PRINT 'Logging CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT ConfigID FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = ConfigID
					FROM @Configs
					ORDER BY ConfigID ASC

					PRINT 'ConfigID: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE ConfigID = @debugID
				END
			END
  
		/*				Drop associated logging features			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Logging].[Features] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [Logging].[Features] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of feature references to be dropped.
				INSERT INTO @FeatureReferences (LoggingFeatureID, FeatureName)
					SELECT LogFeats.LoggingFeatureID, Feats.FeatureName
					FROM [Logging].[Features] LogFeats 
					INNER JOIN [Lookup].[Features] Feats ON LogFeats.FeatureID = Feats.FeatureID
					WHERE LogFeats.[OptionID] = @ID

				--Print out the list for review
				PRINT 'Logging DATABASE REFERENCES that will be dropped.'

				WHILE EXISTS (SELECT LoggingFeatureID FROM @FeatureReferences)
				BEGIN
					SELECT TOP 1 @debugID = LoggingFeatureID
								, @debugSYSNAME = FeatureName
					FROM @FeatureReferences
					ORDER BY FeatureName ASC

					PRINT 'LoggingFeatureID: ' + CAST(@debugID AS VARCHAR) + '     FeatureName: ' + @debugSYSNAME

					DELETE FROM @FeatureReferences WHERE LoggingFeatureID = @debugID
				END
			END
  
		/*						Drop Logging option				*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Logging].[Options] WHERE [OptionID] = @ID
				SET @LogEntry = 'Dropped Logging OptionID: ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Logging', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				PRINT 'Logging OPTION that will be deleted: ' + CAST(@ID AS VARCHAR)
			END
  
	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		PRINT 'Drop Logging Option Transaction Rolled Back due to Error: ' + CAST(@@ERROR AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:      

	SET NOCOUNT OFF    