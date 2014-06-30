/*
PROCEDURE:		[Configuration].[usp_SetFeatureValidation]
AUTHOR:			Derik Hammer
CREATION DATE:	11/14/2013
DESCRIPTION:	Job to check enable or disable feature validation.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enabled a print out of all statements which would
					have been conducted. The stored procedures referenced by this one will not actually be executed,
					nor will any other DML/DDL/DB_Mail commands.
*/
/*
CHANGE HISTORY:



*/

CREATE PROCEDURE [Configuration].[usp_SetFeatureValidation]
	@debug BIT = 0,
	@Databases VARCHAR(8000),
	@VerifyBackup BIT = NULL,
	@VerifyDiskCleanup BIT = NULL,
	@VerifyIndexMaint BIT = NULL
AS
	SET NOCOUNT ON

	BEGIN TRANSACTION

		DECLARE @InvalidDatabases TABLE (DatabaseName SYSNAME NOT NULL);
		DECLARE @ValidDatabases TABLE (DatabaseName SYSNAME NOT NULL);

		INSERT INTO @InvalidDatabases(DatabaseName)
			SELECT DBSelection.DatabaseName
			FROM [dbo].[udf_DatabaseSelect] (@Databases,0) DBSelection
			LEFT JOIN [Configuration].[RegisteredDatabases] rDBs ON DBSelection.DatabaseName = rDBs.DatabaseName
			WHERE rDBs.DatabaseName IS NULL

		IF @debug = 1
		BEGIN
			PRINT '---------------------------------------------------------------------'
			PRINT '@InvalidDatabases result-set'
			PRINT '---------------------------------------------------------------------'
			SELECT DatabaseName
			FROM @InvalidDatabases
		END

		INSERT INTO @ValidDatabases(DatabaseName)
			SELECT DatabaseName
			FROM [dbo].[udf_DatabaseSelect] (@Databases,1) DBSelection

		IF @debug = 1
		BEGIN
			PRINT '---------------------------------------------------------------------'
			PRINT '@ValidDatabases result-set'
			PRINT '---------------------------------------------------------------------'
			SELECT DatabaseName
			FROM @ValidDatabases
		END

		IF @VerifyBackup IS NOT NULL
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT '---------------------------------------------------------------------'
				PRINT '@VerifyBackup update statement.'
				PRINT 'This command was not performed in debug mode.'
				PRINT '---------------------------------------------------------------------'
				PRINT 'UPDATE [Configuration].[RegisteredDatabases]'
				PRINT 'SET [VerifyBackup] = ' + ISNULL(CAST(@VerifyBackup AS CHAR(1)), 'NULL')
				PRINT 'WHERE DatabaseName IN (	SELECT DatabaseName'
				PRINT '                         FROM @ValidDatabases )'
				PRINT '    AND [VerifyBackup] <> @VerifyBackup'
			END
			ELSE
			BEGIN
				UPDATE [Configuration].[RegisteredDatabases]
				SET [VerifyBackup] = @VerifyBackup
				WHERE DatabaseName IN (	SELECT DatabaseName
										FROM @ValidDatabases )
					AND [VerifyBackup] <> @VerifyBackup
			END
		END
	
		IF @VerifyDiskCleanup IS NOT NULL
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT '---------------------------------------------------------------------'
				PRINT '@VerifyDiskCleanup update statement.'
				PRINT 'This command was not performed in debug mode.'
				PRINT '---------------------------------------------------------------------'
				PRINT 'UPDATE [Configuration].[RegisteredDatabases]'
				PRINT 'SET [VerifyDiskCleanup] = ' + ISNULL(CAST(@VerifyDiskCleanup AS CHAR(1)), 'NULL')
				PRINT 'WHERE DatabaseName IN (	SELECT DatabaseName'
				PRINT '                         FROM @ValidDatabases )'
				PRINT '    AND [VerifyDiskCleanup] <> @VerifyDiskCleanup'
			END
			ELSE
			BEGIN
				UPDATE [Configuration].[RegisteredDatabases]
				SET [VerifyDiskCleanup] = @VerifyDiskCleanup
				WHERE DatabaseName IN (	SELECT DatabaseName
										FROM @ValidDatabases )
					AND [VerifyDiskCleanup] <> @VerifyDiskCleanup
			END
		END
	
		IF @VerifyIndexMaint IS NOT NULL
		BEGIN
			IF @debug = 1
			BEGIN
				PRINT '---------------------------------------------------------------------'
				PRINT '@VerifyIndexMaint update statement.'
				PRINT 'This command was not performed in debug mode.'
				PRINT '---------------------------------------------------------------------'
				PRINT 'UPDATE [Configuration].[RegisteredDatabases]'
				PRINT 'SET [VerifyIndexMaint] = ' + ISNULL(CAST(@VerifyIndexMaint AS CHAR(1)), 'NULL')
				PRINT 'WHERE DatabaseName IN (	SELECT DatabaseName'
				PRINT '                         FROM @ValidDatabases )'
				PRINT '    AND [VerifyIndexMaint] <> @VerifyIndexMaint'
			END
			ELSE
			BEGIN
				UPDATE [Configuration].[RegisteredDatabases]
				SET [VerifyIndexMaint] = @VerifyIndexMaint
				WHERE DatabaseName IN (	SELECT DatabaseName
										FROM @ValidDatabases )
					AND [VerifyIndexMaint] <> @VerifyIndexMaint 
			END
		END
	
		DECLARE @output VARCHAR(8000) = '';

		IF EXISTS (SELECT TOP 1 DatabaseName FROM @ValidDatabases)
		BEGIN
			PRINT '---------------------------------------------------------------------'
			PRINT 'Successfully configured the below listed databases:'
			SELECT @output = @output + [DatabaseName] + CHAR(13)
			FROM @ValidDatabases
			PRINT @output
			PRINT '---------------------------------------------------------------------'
		END

		IF EXISTS (SELECT TOP 1 DatabaseName FROM @InvalidDatabases)
		BEGIN
			SET @output = '---------------------------------------------------------------------'
			SET @output = @output + 'The below listed database names are invalid:'
			SELECT @output = @output + [DatabaseName] + CHAR(13)
			FROM @ValidDatabases
			SET @output = LEFT(@output,LEN(@output-1)) + '---------------------------------------------------------------------'

			RAISERROR(@output,16,1);
		END

	IF @@TRANCOUNT > 0
		COMMIT
GO
