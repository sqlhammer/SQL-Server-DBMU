/*
PROCEDURE:		[DiskCleanup].[usp_DropDiskCleanupOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to drop an existing disk cleanup option and it's associated configs.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Equates to the DiskCleanup.Options.OptionID value needed to drop the correct disk cleanup option.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [DiskCleanup].[usp_DropDiskCleanupOption]
	@ID INT,
	@debug BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Declare Variables
	DECLARE @Configs TABLE ( ConfigID INT )
	DECLARE @DatabaseReferences TABLE ( DiskCleanupDatabaseID INT, DatabaseName SYSNAME )
	DECLARE @debugID INT
	DECLARE @debugSYSNAME SYSNAME
	DECLARE @debugUNIQUEIDENTIFIER UNIQUEIDENTIFIER
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION

		/*				Drop associated disk cleanup configs			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [DiskCleanup].[Configs] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [DiskCleanup].[Configs] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of configs to be dropped.
				INSERT INTO @Configs (ConfigID)
					SELECT ConfigID FROM [DiskCleanup].[Configs] WHERE [OptionID] = @ID

				--Print out the list for review
				PRINT 'Disk Cleanup CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT ConfigID FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = ConfigID
					FROM @Configs
					ORDER BY ConfigID ASC

					PRINT 'ConfigID: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE ConfigID = @debugID
				END
			END
  
		/*				Drop associated disk cleanup databases			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [DiskCleanup].[Databases] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [DiskCleanup].[Databases] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of database references to be dropped.
				INSERT INTO @DatabaseReferences (DiskCleanupDatabaseID, DatabaseName)
					SELECT BakDBs.DiskCleanupDatabaseID, RegDBs.DatabaseName
					FROM [DiskCleanup].[Databases] BakDBs 
					INNER JOIN [Configuration].[RegisteredDatabases] RegDBs ON BakDBs.DatabaseID = RegDBs.DatabaseID
					WHERE BakDBs.[OptionID] = @ID

				--Print out the list for review
				PRINT 'Disk Cleanup DATABASE REFERENCES that will be dropped.'

				WHILE EXISTS (SELECT DiskCleanupDatabaseID FROM @DatabaseReferences)
				BEGIN
					SELECT TOP 1 @debugID = DiskCleanupDatabaseID
								, @debugSYSNAME = DatabaseName
					FROM @DatabaseReferences
					ORDER BY DatabaseName ASC

					PRINT 'DiskCleanupDatabaseID: ' + CAST(@debugID AS VARCHAR) + '     DatabaseName: ' + @debugSYSNAME

					DELETE FROM @DatabaseReferences WHERE DiskCleanupDatabaseID = @debugID
				END
			END
  
		/*						Drop disk cleanup option				*/
		IF @debug = 0
			BEGIN
				DELETE FROM [DiskCleanup].[Options] WHERE [OptionID] = @ID
				SET @LogEntry = 'Dropped Disk Cleanup OptionID: ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				PRINT 'Disk Cleanup OPTION that will be deleted: ' + CAST(@ID AS VARCHAR)
			END
  
	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		PRINT 'Drop Disk Cleanup Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:      

	SET NOCOUNT OFF    