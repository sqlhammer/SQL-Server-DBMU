/*
PROCEDURE:		Configuration.usp_RefreshRegisteredDatabases
AUTHOR:			Derik Hammer
CREATION DATE:	3/18/2013
DESCRIPTION:	This procedure will safely back out all configurations and options associated to a list of databases from the server.
PARAMETERS:		@DatabaseList udt_DatabaseList -- This input parameter is a user defined table type with the definition of
				(RegisteredDatabaseID INT NULL,DatabaseName SYSNAME NULL). The first column is the DatabaseID from the Configuration.RegisteredDatabases
				table and the second is the database name. Whenever both columns are populated both columns will be validated before dropping configs.
				@debug BIT -- Used to display debug information without purging anything.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Configuration].[usp_PurgeAllReferencesToDatabase]
	@DatabaseList udt_DatabaseList READONLY,
	@debug BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	--Stored Proc scoped variables
	DECLARE @msg NVARCHAR(4000)
	DECLARE @SkippedDatabases udt_DatabaseList

	BEGIN TRANSACTION
  
		/**************************************************************************************/
		--Validate parameter data
		/**************************************************************************************/
		
		--IDs which don't exist in the Configuration.RegisteredDatabases table
		INSERT INTO @SkippedDatabases (RegisteredDatabaseID)
			SELECT RegisteredDatabaseID
			FROM @DatabaseList DBs
			LEFT JOIN Configuration.RegisteredDatabases regDBs ON regDBs.DatabaseID = DBs.RegisteredDatabaseID
			WHERE regDBs.DatabaseID IS NULL

		--Database Names which don't exist in the Configuration.RegisteredDatabases table
		INSERT INTO @SkippedDatabases (DatabaseName)
			SELECT DBs.DatabaseName
			FROM @DatabaseList DBs
			LEFT JOIN Configuration.RegisteredDatabases regDBs ON regDBs.DatabaseName = DBs.DatabaseName
			WHERE regDBs.DatabaseName IS NULL

		--Dual column references which don't match in the Configuration.RegisteredDatabases table
		INSERT INTO @SkippedDatabases (RegisteredDatabaseID)
			SELECT DBs.RegisteredDatabaseID
			FROM @DatabaseList DBs
			LEFT JOIN Configuration.RegisteredDatabases regDBs ON regDBs.DatabaseID = DBs.RegisteredDatabaseID
			WHERE DBs.DatabaseName IS NOT NULL
				AND DBs.RegisteredDatabaseID IS NOT NULL
				AND regDBs.DatabaseID IS NOT NULL          
				AND regDBs.DatabaseName <> ISNULL(DBs.DatabaseName,'NULL')

		/**************************************************************************************/
		--Cursor through the databases to be purged after excluding those to be skipped.
		/**************************************************************************************/
		
		--Purge Scoped Variables
		DECLARE @JobID UNIQUEIDENTIFIER
		DECLARE @BackupDatabaseID INT
		DECLARE @OptID INT
		DECLARE @DBID INT
		DECLARE @DBName SYSNAME

		--Cursor
		DECLARE DatabasesToPurge CURSOR FAST_FORWARD LOCAL READ_ONLY
		FOR
		SELECT DBs.DatabaseName, DBs.RegisteredDatabaseID
		FROM @DatabaseList DBs
		LEFT JOIN @SkippedDatabases Skp1 ON Skp1.DatabaseName = DBs.DatabaseName
		LEFT JOIN @SkippedDatabases Skp2 ON Skp2.RegisteredDatabaseID = DBs.RegisteredDatabaseID
		WHERE Skp1.DatabaseName IS NULL
			AND Skp2.RegisteredDatabaseID IS NULL
  
		OPEN DatabasesToPurge
		FETCH NEXT FROM DatabasesToPurge INTO @DBName, @DBID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			--Set @DBID if only the database name is available
			IF @DBID IS NULL
			BEGIN
				SELECT @DBID = DatabaseID FROM Configuration.RegisteredDatabases WHERE DatabaseName = @DBName
			END

			--Set @DBName if only the database id is available
			IF @DBName IS NULL
			BEGIN
				SELECT @DBName = DatabaseName FROM Configuration.RegisteredDatabases WHERE DatabaseID = @DBID
			END

			/**************************************************************************************/
			--Back-out backup feature references
			/**************************************************************************************/
			
			WHILE EXISTS (SELECT TOP 1 dbs.OptionID
						FROM [Backup].[Databases] dbs
						WHERE dbs.DatabaseID = @DBID)
			BEGIN

				SET @OptID = NULL
				SELECT TOP 1 @OptID = dbs.OptionID FROM [Backup].[Databases] dbs WHERE dbs.DatabaseID = @DBID

				IF @OptID IS NOT NULL
				BEGIN       
					EXEC [Backup].[usp_AlterBackupOption] @BackupOptionID = @OptID, @BackupDatabases = @DBName, @RemoveDBList = 1, @ValidateDatabasesExist = 0

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END

			END --remove backup databases - while  
			
			/**************************************************************************************/
			--Back-out disk cleanup feature references
			/**************************************************************************************/

			WHILE EXISTS (SELECT TOP 1 dbs.OptionID
						FROM [DiskCleanup].[Databases] dbs
						WHERE dbs.DatabaseID = @DBID)
			BEGIN

				SET @OptID = NULL
				SELECT TOP 1 @OptID = dbs.OptionID FROM [DiskCleanup].[Databases] dbs WHERE dbs.DatabaseID = @DBID

				IF @OptID IS NOT NULL
				BEGIN
					EXEC [DiskCleanup].[usp_AlterDiskCleanupOption] @OptionID = @OptID, @Databases = @DBName, @RemoveDBList = 1, @ValidateDatabasesExist = 0

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END

			END --remove disk cleanup databases - while  

			/**************************************************************************************/
			--Back-out index maintenance feature references
			/**************************************************************************************/
			
			WHILE EXISTS (SELECT TOP 1 dbs.OptionID
						FROM [IndexMaint].[Databases] dbs
						WHERE dbs.DatabaseID = @DBID)
			BEGIN

				SET @OptID = NULL
				SELECT TOP 1 @OptID = dbs.OptionID FROM [IndexMaint].[Databases] dbs WHERE dbs.DatabaseID = @DBID

				IF @OptID IS NOT NULL
				BEGIN
					EXEC [IndexMaint].[usp_AlterIndexMaintOption] @OptionID = @OptID, @Databases = @DBName, @RemoveDBList = 1, @ValidateDatabasesExist = 0

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END

			END --remove index maint databases - while  

			/**************************************************************************************/
			--Back-out trace feature references
			/**************************************************************************************/

			WHILE EXISTS (SELECT TOP 1 dbs.OptionID
						FROM [Trace].[Databases] dbs
						WHERE dbs.DatabaseID = @DBID)
			BEGIN

				SET @OptID = NULL
				SELECT TOP 1 @OptID = dbs.OptionID FROM [Trace].[Databases] dbs WHERE dbs.DatabaseID = @DBID

				IF @OptID IS NOT NULL
				BEGIN
					EXEC [Trace].[usp_AlterTraceOption] @OptionID = @OptID, @Databases = @DBName, @RemoveDBList = 1, @ValidateDatabasesExist = 0

					--Roll back if error occurs.
					IF @@ERROR <> 0 GOTO QuitWithRollback
				END

			END --remove trace databases - while  

			/**************************************************************************************/

			FETCH NEXT FROM DatabasesToPurge INTO @DBName, @DBID
		END --cursor loop - while
		
		/**************************************************************************************/
		--Unregister Database(s)
		/**************************************************************************************/

		DELETE FROM [Configuration].[RegisteredDatabases]
		WHERE DatabaseID IN (SELECT DBs.RegisteredDatabaseID
							FROM @DatabaseList DBs
							LEFT JOIN @SkippedDatabases Skp1 ON Skp1.DatabaseName = DBs.DatabaseName
							LEFT JOIN @SkippedDatabases Skp2 ON Skp2.RegisteredDatabaseID = DBs.RegisteredDatabaseID
							WHERE Skp1.DatabaseName IS NULL
								AND Skp2.RegisteredDatabaseID IS NULL)

		--Roll back if error occurs.
		IF @@ERROR <> 0 GOTO QuitWithRollback

		/**************************************************************************************/

	IF @@TRANCOUNT > 0 COMMIT  
	GOTO QuitEndSave

	QuitWithRollback:
	PRINT 'Purge Database(s) Transaction Rolled Back due to Error: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
	SET @msg = 'Purge Database(s) Transaction Rolled Back due to Error: ' + CAST(ERROR_MESSAGE() AS VARCHAR)
	EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @msg, @LogMode = 'LIMITED'

	IF @@TRANCOUNT > 0 ROLLBACK
  
	QuitEndSave:

	--Close Cursors which might not have been due to GOTO logic
	CLOSE DatabasesToPurge
	DEALLOCATE DatabasesToPurge	


	SET NOCOUNT OFF    
