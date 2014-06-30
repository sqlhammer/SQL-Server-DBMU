/*
PROCEDURE:		[Trace].[usp_DropTraceOption]
AUTHOR:			Derik Hammer
CREATION DATE:	5/2/2012
DESCRIPTION:	This procedure is used to drop an existing trace option and it's associated configs.
PARAMETERS:		@debug BIT = 0 --Setting this parameter to 1 will enable debugging print statements.
				@ID INT --Equates to the Trace.Options.OptionID value needed to drop the correct Trace option.

*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [Trace].[usp_DropTraceOption]
	@ID INT,
	@debug BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON  

	--Declare Variables
	DECLARE @Configs TABLE ( ConfigID INT )
	DECLARE @DatabaseReferences TABLE ( TraceDatabaseID INT, DatabaseName SYSNAME )
	DECLARE @debugID INT
	DECLARE @debugSYSNAME SYSNAME
	DECLARE @debugUNIQUEIDENTIFIER UNIQUEIDENTIFIER
	DECLARE @TableID INT
	DECLARE @TableName VARCHAR(60)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--This procedure is one large all or nothing transaction
	BEGIN TRANSACTION

		/*						Stop traces								*/
		
		IF @debug = 1
		BEGIN
			PRINT 'Disabling trace config.'
			PRINT 'UPDATE [Trace].[Configs] SET [IsEnabled] = 0 WHERE [OptionID] = ' + CAST(@ID AS VARCHAR)
			PRINT ''
			PRINT 'Stopping and closing associated trace(s).'
			PRINT 'EXEC [Trace].[usp_PopulateCurrentTraceTables] @TraceOptionsID = ' + CAST(@ID AS VARCHAR)
		END
		ELSE
		BEGIN
			--Disable
			UPDATE [Trace].[Configs] SET [IsEnabled] = 0 WHERE [OptionID] = @ID
			SET @LogEntry = 'UPDATE [Trace].[Configs] SET [IsEnabled] = 0 WHERE [OptionID] = ' + CAST(@ID AS VARCHAR(10)) + ' --Disable configs'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			--Stop and close
			EXEC [Trace].[usp_PopulateCurrentTraceTables] @TraceOptionsID = @ID
			SET @LogEntry = 'EXEC [Trace].[usp_PopulateCurrentTraceTables] @TraceOptionsID = ' + CAST(@ID AS VARCHAR(10)) + ' --Stop and close trace'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
		END
  
		/*						Drop traces tables						*/

		--Drop tables
		DECLARE TraceTable_Cursor CURSOR FAST_FORWARD FOR
			SELECT [TableID], [TableName]
			FROM [Trace].[Tables]
			WHERE [OptionID] = @ID

		OPEN TraceTable_Cursor

		FETCH NEXT FROM TraceTable_Cursor INTO @TableID, @TableName

		WHILE ( SELECT fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE name = 'TraceTable_Cursor' ) = 0 
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT 'DROP TABLE [Trace].[' + @TableName + ']'
			END
			ELSE
			BEGIN
				--Drop table
				EXEC ( 'DROP TABLE [Trace].[' + @TableName + ']' )
				
				SET @LogEntry = 'DROP TABLE [Trace].[' + @TableName + '] --Purging trace tables for Trace Option ID: '  + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END          

			FETCH NEXT FROM TraceTable_Cursor INTO @TableID, @TableName
		END

		CLOSE TraceTable_Cursor
		DEALLOCATE TraceTable_Cursor

		--Delete table records
		IF @debug = 1
		BEGIN
			PRINT 'DELETE FROM [Trace].[Tables] WHERE [OptionID] = ' + CAST(@ID AS VARCHAR)
		END
		ELSE
		BEGIN
			DELETE FROM [Trace].[Tables] WHERE [OptionID] = @ID

			SET @LogEntry = 'DELETE FROM [Trace].[Tables] WHERE [OptionID] = '  + CAST(@ID AS VARCHAR(10)) + ' --to purge references to the now dropped tables.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

			--Roll back if error occurs.
			IF @@ERROR <> 0 GOTO QuitWithRollback
		END

		/*				Drop associated Trace configs					*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Trace].[Configs] WHERE [OptionID] = @ID
				
				SET @LogEntry = 'DELETE FROM [Trace].[Configs] WHERE [OptionID] = '  + CAST(@ID AS VARCHAR(10)) + ' --to purge assocated trace configs.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of configs to be dropped.
				INSERT INTO @Configs (ConfigID)
					SELECT ConfigID FROM [Trace].[Configs] WHERE [OptionID] = @ID

				--Print out the list for review
				PRINT 'Trace CONFIGS that will be dropped.'

				WHILE EXISTS (SELECT ConfigID FROM @Configs)
				BEGIN
					SELECT TOP 1 @debugID = ConfigID
					FROM @Configs
					ORDER BY ConfigID ASC

					PRINT 'ConfigID: ' + CAST(@debugID AS VARCHAR)

					DELETE FROM @Configs WHERE ConfigID = @debugID
				END
			END
  
		/*				Drop associated Trace databases					*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Trace].[Databases] WHERE [OptionID] = @ID
				
				SET @LogEntry = 'DELETE FROM [Trace].[Databases] WHERE [OptionID] = '  + CAST(@ID AS VARCHAR(10)) + ' --to purge assocated databases.'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				--Populate list of database references to be dropped.
				INSERT INTO @DatabaseReferences (TraceDatabaseID, DatabaseName)
					SELECT BakDBs.TraceDatabaseID, RegDBs.DatabaseName
					FROM [Trace].[Databases] BakDBs 
					INNER JOIN [Configuration].[RegisteredDatabases] RegDBs ON BakDBs.DatabaseID = RegDBs.DatabaseID
					WHERE BakDBs.[OptionID] = @ID

				--Print out the list for review
				PRINT 'Trace DATABASE REFERENCES that will be dropped.'

				WHILE EXISTS (SELECT TraceDatabaseID FROM @DatabaseReferences)
				BEGIN
					SELECT TOP 1 @debugID = TraceDatabaseID
								, @debugSYSNAME = DatabaseName
					FROM @DatabaseReferences
					ORDER BY DatabaseName ASC

					PRINT 'TraceDatabaseID: ' + CAST(@debugID AS VARCHAR) + '     DatabaseName: ' + @debugSYSNAME

					DELETE FROM @DatabaseReferences WHERE TraceDatabaseID = @debugID
				END
			END
		
		/*				Drop Trace Tables and references				*/

		--Drop Trace tables

		/*						Drop Trace option						*/
		IF @debug = 0
			BEGIN
				DELETE FROM [Trace].[Options] WHERE [OptionID] = @ID
				
				SET @LogEntry = 'Drop Trace Option ID: ' + CAST(@ID AS VARCHAR(10))
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
				
				--Roll back if error occurs.
				IF @@ERROR <> 0 GOTO QuitWithRollback
			END
		ELSE
			BEGIN
				PRINT 'Trace OPTION that will be deleted: ' + CAST(@ID AS VARCHAR)
			END
  
	--Commit
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
		SET @LogEntry = 'Drop Trace Option Transaction Rolled Back due to Error Message: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
		PRINT @LogEntry
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:      

	SET NOCOUNT OFF