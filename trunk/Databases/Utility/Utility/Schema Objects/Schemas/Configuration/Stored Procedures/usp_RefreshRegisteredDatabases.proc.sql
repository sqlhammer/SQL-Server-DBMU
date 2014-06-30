/*
PROCEDURE:		Configuration.usp_RefreshRegisteredDatabases
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure updates the RegisteredDatabases table with new databases and optionally will delete databases
				that have been removed.
PARAMETERS:		@Purge BIT --The default value is 0 which indicates that you do not want to remove databases from the RegisteredDatabases
					table. It will instead raise an error indicated that there is a database or databases that are missing. It might not be
					desirable for this process to delete database records because the DatabaseIDs might be associated to several configurtions.
					Preventing the purge will allow a DBA to restore the database without having to do complicated updates to the configurations.
					If a value of 1 is set then this process will silently delete databases from the table when they are removed from the instance.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/22/2012 --	Accounted for the ALL_SSAS_DATABASES placeholder necessary to handle the SSAS backup SSIS package.

** Derik Hammer ** 04/30/2013 --	Added integration with the [Configuration].[usp_PurgeAllReferencesToDatabase] stored procedure
									to allow for automated purging of configurations related to databases which have been dropped.

*/
CREATE PROCEDURE [Configuration].[usp_RefreshRegisteredDatabases] 
	@Purge BIT = 0
AS 
	SET NOCOUNT ON;

	--Vars
	DECLARE @LogEntry VARCHAR(8000)
	DECLARE @PurgeDBList udt_DatabaseList

	--Populate new databases, if there are any
	IF EXISTS ( SELECT  [Sdb].[name]
				FROM    [sys].[databases] Sdb
						LEFT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
				WHERE   Rdb.DatabaseName IS NULL )
	BEGIN
		INSERT INTO [Configuration].[RegisteredDatabases] (DatabaseName)
				SELECT  [Sdb].[name]
				FROM    [sys].[databases] Sdb
						LEFT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
				WHERE   Rdb.DatabaseName IS NULL
	
		SET @LogEntry = 'Inserted new databases into the [Configuration].[RegisteredDatabases] table.'
		EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
	END
  
	--Populate SSAS work around
	IF NOT EXISTS (	SELECT  Rdb.DatabaseID
					FROM    [Configuration].[RegisteredDatabases] Rdb
					WHERE   Rdb.DatabaseName = 'ALL_SSAS_DATABASES' )
	BEGIN
		INSERT INTO [Configuration].[RegisteredDatabases] (DatabaseName, VerifyIndexMaint, VerifyBackup, VerifyDiskCleanup)
			SELECT 'ALL_SSAS_DATABASES', 0, 0, 0
	
		SET @LogEntry = 'Inserted SSAS database reference into the [Configuration].[RegisteredDatabases] table.'
		EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
	END

	--Throw error if database(s) no longer exist but the @Purge flag is set to 0.
    IF EXISTS ( SELECT   [Rdb].[DatabaseName]
                FROM     [sys].[databases] Sdb
                        RIGHT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
                WHERE    Sdb.name IS NULL
					AND Rdb.DatabaseName <> 'ALL_SSAS_DATABASES' )
				AND @Purge = 0 
        BEGIN
            RAISERROR('Registered database(s) no longer exists. If any configurations are pointing to this database they will fail. Query Configuration.vwOrphanedDatabases for more details.',16,1)
        END	

	--Remove databases from the list where they don't exist anymore
    IF EXISTS ( SELECT   [Rdb].[DatabaseName]
                FROM     [sys].[databases] Sdb
                        RIGHT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
                WHERE    Sdb.name IS NULL 
					AND Rdb.DatabaseName <> 'ALL_SSAS_DATABASES' )
				AND @Purge = 1
        BEGIN  
			INSERT INTO @PurgeDBList (RegisteredDatabaseID, DatabaseName)
			SELECT   Rdb.DatabaseID, [Rdb].[DatabaseName]
            FROM     [sys].[databases] Sdb
            RIGHT OUTER JOIN [Configuration].[RegisteredDatabases] Rdb ON [Sdb].name = Rdb.DatabaseName
            WHERE    Sdb.name IS NULL
				AND Rdb.DatabaseName <> 'ALL_SSAS_DATABASES'

            EXEC [Configuration].[usp_PurgeAllReferencesToDatabase] @DatabaseList = @PurgeDBList
			
			SET @LogEntry = 'Purged missing databases from the [Configuration].[RegisteredDatabases] table.'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Configuration', @TextEntry = @LogEntry, @LogMode = 'LIMITED'          
		END

	SET NOCOUNT OFF
