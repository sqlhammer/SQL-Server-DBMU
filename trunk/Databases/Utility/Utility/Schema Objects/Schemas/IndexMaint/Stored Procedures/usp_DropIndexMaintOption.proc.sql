/*
PROCEDURE:		[IndexMaint].[usp_DropIndexMaintOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to drop an existing index maintenance option and it's associated configs.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Equates to the IndexMaint.Options.OptionID value needed to drop the correct index maintenance option.

*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [IndexMaint].[usp_DropIndexMaintOption]
	@ID INT,
	@debug BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Declare Variables
	DECLARE @Configs TABLE ( ConfigID INT )
	DECLARE @DatabaseReferences TABLE ( IndexDatabaseID INT, DatabaseName SYSNAME )
	DECLARE @debugID INT
	DECLARE @debugSYSNAME SYSNAME
	DECLARE @debugUNIQUEIDENTIFIER UNIQUEIDENTIFIER
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION

		/*				Drop associated index maintenance configs			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [IndexMaint].[Configs] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [IndexMaint].[Configs] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of configs to be dropped.
				INSERT INTO @Configs (ConfigID)
					SELECT ConfigID FROM [IndexMaint].[Configs] WHERE [OptionID] = @ID

				--Print out the list for review
				PRINT 'Index Maintenance CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT ConfigID FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = ConfigID
					FROM @Configs
					ORDER BY ConfigID ASC

					PRINT 'ConfigID: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE ConfigID = @debugID
				END
			END
  
		/*				Drop associated index maintenance databases			*/
		IF @debug = 0
			BEGIN
				DELETE FROM [IndexMaint].[Databases] WHERE [OptionID] = @ID
				SET @LogEntry = 'DELETE FROM [IndexMaint].[Databases] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of database references to be dropped.
				INSERT INTO @DatabaseReferences (IndexDatabaseID, DatabaseName)
					SELECT BakDBs.IndexDatabaseID, RegDBs.DatabaseName
					FROM [IndexMaint].[Databases] BakDBs 
					INNER JOIN [Configuration].[RegisteredDatabases] RegDBs ON BakDBs.DatabaseID = RegDBs.DatabaseID
					WHERE BakDBs.[OptionID] = @ID

				--Print out the list for review
				PRINT 'Index Maintenance DATABASE REFERENCES that will be dropped.'

				WHILE EXISTS (SELECT IndexDatabaseID FROM @DatabaseReferences)
				BEGIN
					SELECT TOP 1 @debugID = IndexDatabaseID
								, @debugSYSNAME = DatabaseName
					FROM @DatabaseReferences
					ORDER BY DatabaseName ASC

					PRINT 'IndexDatabaseID: ' + CAST(@debugID AS VARCHAR) + '     DatabaseName: ' + @debugSYSNAME

					DELETE FROM @DatabaseReferences WHERE IndexDatabaseID = @debugID
				END
			END
  
		/*						Drop index maintenance option				*/
		IF @debug = 0
			BEGIN
				DELETE FROM [IndexMaint].[Options] WHERE [OptionID] = @ID				
				SET @LogEntry = 'Dropped Index Maintenance OptionID: ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				PRINT 'Index Maintenance OPTION that will be deleted: ' + CAST(@ID AS VARCHAR)
			END
  
	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		PRINT 'Drop Index Maintenance Option Transaction Rolled Back due to Error: ' + CAST(@@ERROR AS VARCHAR)
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:      

	SET NOCOUNT OFF    