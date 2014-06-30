/*
PROCEDURE:		[Configuration].[usp_DropConfig]
AUTHOR:			Derik Hammer
CREATION DATE:	5/1/2012
DESCRIPTION:	This procedure is used to create a new umbrella configuration without any associated feature options.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Configuration.Configs ConfigID that is to be dropped.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Configuration].[usp_DropConfig]
	@ID INT,
	@debug BIT = 0
AS
	SET NOCOUNT ON

	--Declare Variables
	DECLARE @Configs TABLE ( OptionID INT )
	DECLARE @debugID INT
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION DropConfig

		/*				Drop associated Tier 2 configs				*/
		IF @debug = 0
			BEGIN
				--Drop [Backup] configs
				DELETE FROM [Backup].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'DELETE FROM [Backup].[Configs] WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback

				--Drop [DiskCleanup] configs
				DELETE FROM [DiskCleanup].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'DELETE FROM [DiskCleanup].[Configs] WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback

				--Drop [Trace] configs
				DELETE FROM [Trace].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'DELETE FROM [Trace].[Configs] WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback

				--Drop [IndexMaint] configs
				DELETE FROM [IndexMaint].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'DELETE FROM [IndexMaint].[Configs] WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback

				--Drop [Logging] configs
				DELETE FROM [Logging].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'DELETE FROM [Logging].[Configs] WHERE [ConfigID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback
			END
		ELSE
			BEGIN
				PRINT ''
				          
				--Populate list of [Backup] configs to be dropped.
				INSERT INTO @Configs (OptionID)
					SELECT [OptionID] FROM [Backup].[Configs] WHERE [ConfigID] = @ID

				--Print out the list for review
				PRINT 'Backup CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT [OptionID] FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = [OptionID]
					FROM @Configs
					ORDER BY [OptionID] ASC

					PRINT '[OptionID]: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE [OptionID] = @debugID
				END
				
				--Clean up temp table
				DELETE FROM @Configs
  
				
				--Populate list of [DiskCleanup] configs to be dropped.
				INSERT INTO @Configs (OptionID)
					SELECT [OptionID] FROM [DiskCleanup].[Configs] WHERE [ConfigID] = @ID

				--Print out the list for review
				PRINT 'DiskCleanup CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT [OptionID] FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = [OptionID]
					FROM @Configs
					ORDER BY [OptionID] ASC

					PRINT '[OptionID]: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE [OptionID] = @debugID
				END
				
				--Clean up temp table
				DELETE FROM @Configs
				
				--Populate list of [Trace] configs to be dropped.
				INSERT INTO @Configs (OptionID)
					SELECT [OptionID] FROM [Trace].[Configs] WHERE [ConfigID] = @ID

				--Print out the list for review
				PRINT 'Trace CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT [OptionID] FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = [OptionID]
					FROM @Configs
					ORDER BY [OptionID] ASC

					PRINT '[OptionID]: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE [OptionID] = @debugID
				END
				
				--Clean up temp table
				DELETE FROM @Configs
				
				--Populate list of [IndexMaint] configs to be dropped.
				INSERT INTO @Configs (OptionID)
					SELECT [OptionID] FROM [IndexMaint].[Configs] WHERE [ConfigID] = @ID

				--Print out the list for review
				PRINT 'IndexMaint CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT [OptionID] FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = [OptionID]
					FROM @Configs
					ORDER BY [OptionID] ASC

					PRINT '[OptionID]: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE [OptionID] = @debugID
				END
				
				--Clean up temp table
				DELETE FROM @Configs
				
				--Populate list of [Logging] configs to be dropped.
				INSERT INTO @Configs (OptionID)
					SELECT [OptionID] FROM [Logging].[Configs] WHERE [ConfigID] = @ID

				--Print out the list for review
				PRINT 'Logging CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT [OptionID] FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = [OptionID]
					FROM @Configs
					ORDER BY [OptionID] ASC

					PRINT '[OptionID]: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE [OptionID] = @debugID
				END
  
				--Clean up temp table
				DELETE FROM @Configs              

				PRINT ''
				PRINT '**********************************************************************************************'
				PRINT 'NOTE: All ''Options'' associated to the above listed configs will NOT be deleted at this time.'
				PRINT '**********************************************************************************************'
			END
		
		/*					Drop  Tier 1 config						*/	
		IF @debug = 0
			BEGIN
				--Drop config
				DELETE FROM [Configuration].[Configs] WHERE [ConfigID] = @ID
  				SET @LogEntry = 'Drop tier one Configuration ID: ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO DropConfigQuitWithRollback
			END
		ELSE
			BEGIN
				PRINT ''
				PRINT 'Tier 1 Config ID to be dropped: ' + CAST(@ID AS VARCHAR)
				PRINT ''
				PRINT '***********************************************************************************'
				PRINT 'NOTE: The tier 1 config has not been deleted at this time due to debugging enabled.'
				PRINT '***********************************************************************************'       
			END

	--Commit
	COMMIT TRANSACTION DropConfig

	GOTO DropConfigEndSave
	DropConfigQuitWithRollback:
		PRINT 'Drop Config Transaction Rolled Back due to Error: ' + CAST(@@ERROR AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION DropConfig
	DropConfigEndSave:
    
	SET NOCOUNT OFF