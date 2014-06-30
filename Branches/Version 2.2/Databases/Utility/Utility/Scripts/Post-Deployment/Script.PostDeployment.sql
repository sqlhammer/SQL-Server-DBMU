/*
Post-Deployment Script 
*/

SET NOCOUNT ON;
/**************************************************************************************/
--Set data and log file initialization sizes
/**************************************************************************************/
IF ((SELECT (size * 8) / 1024 AS [Size_MB]
	FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)') < 5)
BEGIN
	ALTER DATABASE [$(DatabaseName)] 
	MODIFY FILE
		(NAME = $(DatabaseName),
		SIZE = 5MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 100MB);
END

IF ((SELECT (size * 8) / 1024 AS [Size_MB]
	FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_log') < 5)
BEGIN
	ALTER DATABASE [$(DatabaseName)] 
	MODIFY FILE
		(NAME = $(DatabaseName)_log,
		SIZE = 5MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 100MB);
END
/**************************************************************************************/
--Create auditing and logging filegroup
/**************************************************************************************/
USE [$(DatabaseName)]
GO
DECLARE @Auditing SYSNAME
DECLARE @Logging SYSNAME

SELECT @Auditing = name
FROM sys.[database_files]
WHERE name LIKE '%Auditing%'
       AND name <> '$(DatabaseName)_Auditing'

SELECT @Logging = name
FROM sys.[database_files]
WHERE name LIKE '%Logging%'
       AND name <> '$(DatabaseName)_Logging'

IF @Auditing IS NOT NULL AND @Logging IS NOT NULL
       AND EXISTS (SELECT * FROM sys.[databases] WHERE name = '$(DatabaseName)')
BEGIN
       DECLARE @sql NVARCHAR(4000) = '
              USE [master];
              ALTER DATABASE [$(DatabaseName)] MODIFY FILE (NAME=N''' + @Auditing + ''', NEWNAME=N''$(DatabaseName)_Auditing'');
              ALTER DATABASE [$(DatabaseName)] MODIFY FILE (NAME=N''' + @Logging + ''', NEWNAME=N''$(DatabaseName)_Logging'');
              ';
       EXEC sp_executesql @sql;
END

GO

/**************************************************************************************/

IF NOT EXISTS (SELECT file_id FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_Auditing')
BEGIN
	ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Auditing],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Auditing.ndf',
		SIZE = 5MB, MAXSIZE = UNLIMITED, FILEGROWTH = 100MB
	) TO FILEGROUP [Auditing]
END
IF NOT EXISTS (SELECT file_id FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_Logging')
BEGIN
	ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Logging],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Logging.ndf',
		SIZE = 5MB, MAXSIZE = UNLIMITED, FILEGROWTH = 100MB
	) TO FILEGROUP [Logging]
END
/**************************************************************************************/
--Create credential and proxy
USE [msdb];
GO

IF NOT EXISTS (SELECT credential_id FROM master.sys.credentials WHERE name = 'UtilityCredential')
	EXEC ('CREATE CREDENTIAL UtilityCredential WITH IDENTITY = ''$(ServiceAccount)'', SECRET = ''$(ServiceAccountPassword)'';')
IF NOT EXISTS (SELECT proxy_id FROM msdb.dbo.sysproxies WHERE name = 'UtilityProxy')
BEGIN
	EXEC msdb.dbo.sp_add_proxy @proxy_name=N'UtilityProxy',@credential_name=N'UtilityCredential', @enabled=1
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'UtilityProxy', @subsystem_id=11 --SSIS
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'UtilityProxy', @subsystem_id=12 --PowerShell
END

--Service account needs to be sysadmin so these are irrelevant until we get more granular with the access
--EXEC msdb.dbo.sp_grant_login_to_proxy @login_name = @ServiceAccount, @proxy_name = 'UtilityProxy'

GO
USE [$(DatabaseName)];
GO
/****************************************************/

/*			Populate Tally Table					*/
DECLARE @TallyCount INT = 1000
IF (SELECT COUNT(*) FROM dbo.Tally) < @TallyCount
BEGIN
	TRUNCATE TABLE dbo.Tally;

	WITH Base AS ( SELECT 1 AS n
				UNION ALL
				SELECT	n + 1 FROM Base WHERE n < CEILING(SQRT(@TallyCount))),
		Expand AS ( SELECT 1 AS C FROM Base AS B1, Base AS B2 ),
		Nums AS ( SELECT ROW_NUMBER() OVER (ORDER BY C) AS n FROM Expand )
	INSERT INTO dbo.Tally (N)
		SELECT n FROM Nums WHERE n <= @TallyCount

	ALTER INDEX PK_Tally_N ON dbo.Tally REBUILD;
END

/*			Populate lookups						*/
--Populate [Lookup].[BackupTypes]
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'FULL')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('FULL', 'BAK')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'LOG')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('LOG', 'TRN')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'DIFF')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('DIFF', 'BAK')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'SSAS')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('SSAS', 'ADF')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'MasterKey')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('MasterKey', 'KEY')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'ServerCertificate')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('ServerCertificate', 'CER')
IF NOT EXISTS (SELECT BackupTypeID FROM [Lookup].[BackupTypes] WHERE BackupTypeDesc = 'ServerCertificateKey')
	INSERT INTO [Lookup].[BackupTypes] (BackupTypeDesc, FileExtension) VALUES ('ServerCertificateKey', 'KEY')

--Populate [Lookup].[PurgeTypes]
IF NOT EXISTS (SELECT PurgeTypeID FROM [Lookup].[PurgeTypes] WHERE PurgeTypeDesc = 'PURGE BY DAYS')
	INSERT INTO [Lookup].[PurgeTypes] (PurgeTypeDesc) VALUES ('PURGE BY DAYS')
IF NOT EXISTS (SELECT PurgeTypeID FROM [Lookup].[PurgeTypes] WHERE PurgeTypeDesc = 'PURGE BY NUMBER OF FILES')
	INSERT INTO [Lookup].[PurgeTypes] (PurgeTypeDesc) VALUES ('PURGE BY NUMBER OF FILES')
IF NOT EXISTS (SELECT PurgeTypeID FROM [Lookup].[PurgeTypes] WHERE PurgeTypeDesc = 'PURGE BY NUMBER OF ROWS')
	INSERT INTO [Lookup].[PurgeTypes] (PurgeTypeDesc) VALUES ('PURGE BY NUMBER OF ROWS')

--Populate [Lookup].[LoggingModes]
IF NOT EXISTS (SELECT LoggingModeID FROM [Lookup].[LoggingModes] WHERE LoggingModeDesc = 'LIMITED')
	INSERT INTO [Lookup].[LoggingModes] (LoggingModeDesc) VALUES ('LIMITED')
IF NOT EXISTS (SELECT LoggingModeID FROM [Lookup].[LoggingModes] WHERE LoggingModeDesc = 'VERBOSE')
	INSERT INTO [Lookup].[LoggingModes] (LoggingModeDesc) VALUES ('VERBOSE')

--Populate [Lookup].[Features]
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Backup')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Backup')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Disk Cleanup')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Disk Cleanup')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Query Trace')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Query Trace')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Index Maintenance')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Index Maintenance')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Configuration')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Configuration')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Utility')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Utility')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Logging')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Logging')
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'Audit')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('Audit')

--Populate [Lookup].[InformationTypes]
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'Description')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('Description')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'Version')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('Version')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'How To')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('How To')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'Example')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('Example')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'ServiceAccount')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('ServiceAccount')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'Environment')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('Environment')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'SSIS Package Store')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('SSIS Package Store')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'SSAS Data Source')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('SSAS Data Source')
IF NOT EXISTS (SELECT InformationTypeID FROM [Lookup].[InformationTypes] WHERE InfoTypeDesc = 'Alert Recipients')
	INSERT INTO [Lookup].[InformationTypes] (InfoTypeDesc) VALUES ('Alert Recipients')

--Populate [Lookup].[KeyTypes]
IF NOT EXISTS (SELECT KeyTypeID FROM [Lookup].[KeyTypes] WHERE KeyTypeDesc = 'Master Key')
	INSERT INTO [Lookup].[KeyTypes] (KeyTypeDesc) VALUES ('Master Key')
IF NOT EXISTS (SELECT KeyTypeID FROM [Lookup].[KeyTypes] WHERE KeyTypeDesc = 'Server Certificate')
	INSERT INTO [Lookup].[KeyTypes] (KeyTypeDesc) VALUES ('Server Certificate')
IF NOT EXISTS (SELECT KeyTypeID FROM [Lookup].[KeyTypes] WHERE KeyTypeDesc = 'Certificate Private Key')
	INSERT INTO [Lookup].[KeyTypes] (KeyTypeDesc) VALUES ('Certificate Private Key')
/****************************************************/

/*		Set Deployment Versioning information		*/
--Utility DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Logging DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Logging'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Logging' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Logging'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Backup Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Backup'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Backup' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Backup'
									AND InfoT.InfoTypeDesc = 'Version')
END
--IndexMaint Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Index Maintenance'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Index Maintenance' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Index Maintenance'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Trace Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Query Trace'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Query Trace' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Query Trace'
									AND InfoT.InfoTypeDesc = 'Version')
END
--DiskCleanup Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Disk Cleanup'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Disk Cleanup' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Disk Cleanup'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Configuration Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Configuration'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Configuration' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Configuration'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Audit Feature Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Audit'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Audit' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '$(Version)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Version)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Audit'
									AND InfoT.InfoTypeDesc = 'Version')
END
--Feature validation details.
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'Alert Recipients' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Alert Recipients' ) AS [InformationTypeID]
			, ( 'DatabaseAdministration@libtax.com' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'DatabaseAdministration@libtax.com'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'Alert Recipients')
END
/****************************************************/

/*		Set Deployment Descriptions information		*/
--Utility DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
				'The Utility database is a central administration database designed to simplify and organize advanced database administration tasks and set a standard of operation that can reduce troubleshooting time by providing one place to look for database maintenance configurations.'
			 ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Utility database is a central administration database designed to simplify and organize advanced database administration tasks and set a standard of operation that can reduce troubleshooting time by providing one place to look for database maintenance configurations.'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'Description')
END
--Logging DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Logging'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Logging' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
				'The Logging feature accepts text entries from the other features when they execute commands. These commands are stored locally for administrator review and purged based on settings for each feature.'
			 ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Logging feature accepts text entries from the other features when they execute commands. These commands are stored locally for administrator review and purged based on settings for each feature.'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Logging'
									AND InfoT.InfoTypeDesc = 'Description')
END
--Audit DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Audit'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Audit' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
				'The Audit feature keeps a server level trigger on all DDL events and stored this information temporarily in a local table. Then on a heart beat the CentralUtility database will round-robin all of the servers and pull the records to a central auditing table. The records are then purged from the local tables to prevent ballooning of database files.'
			 ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Audit feature keeps a server level trigger on all DDL events and stored this information temporarily in a local table. Then on a heart beat the CentralUtility database will round-robin all of the servers and pull the records to a central auditing table. The records are then purged from the local tables to prevent ballooning of database files.'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Audit'
									AND InfoT.InfoTypeDesc = 'Description')
END
--Backup Feature Description
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Backup'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Backup' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
			'The backup feature facilitates comprehensize backup plans that are organized, easily viewed, and highly customizable. Backup plans are created, droppped, or altered via stored procedures which handle the configuration information tracking, SQL Agent job spawning, and execution of the database backups.' 
			) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The backup feature facilitates comprehensize backup plans that are organized, easily viewed, and highly customizable. Backup plans are created, droppped, or altered via stored procedures which handle the configuration information tracking, SQL Agent job spawning, and execution of the database backups.' 
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Backup'
									AND InfoT.InfoTypeDesc = 'Description')
END
--IndexMaint Feature Description
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Index Maintenance'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Index Maintenance' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
			'The Index Maintenance feature goes beyond the norm by allowing for custom tolerance thredholds for index statistics per database and dynamically rebuilds or reorganizes each index based on it''s need. This feature reduces run time by not conducting mainenance on indexes which do not require it and provides a high level of flexibility for the administrator to set his/her preferences for conditional based maintenance.' 
			) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Index Maintenance feature goes beyond the norm by allowing for custom tolerance thredholds for index statistics per database and dynamically rebuilds or reorganizes each index based on it''s need. This feature reduces run time by not conducting mainenance on indexes which do not require it and provides a high level of flexibility for the administrator to set his/her preferences for conditional based maintenance.' 
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Index Maintenance'
									AND InfoT.InfoTypeDesc = 'Description')
END
--Trace Feature Description
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Query Trace'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Query Trace' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
			'The Query Trace feature is for short term query tracking for the purposes of performance tuning or identification of expensive queries that run intermittently. This feature will trace queries based on user defined filters and store the data into daily rotating trace tables which auto purge based on user configured values.' 
			) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Query Trace feature is for short term query tracking for the purposes of performance tuning or identification of expensive queries that run intermittently. This feature will trace queries based on user defined filters and store the data into daily rotating trace tables which auto purge based on user configured values.' 
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Query Trace'
									AND InfoT.InfoTypeDesc = 'Description')
END
--DiskCleanup Feature Description
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Disk Cleanup'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Disk Cleanup' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
			'The Disk Cleanup feature is designed as a partner to the Backup feature. It''s purpose is to prevent a situation where there are excessive backup files taking up disk space on backup media. The disk cleanup feature is intentionally limited to purging files of extensions .bak, .trn, .cer, and .key.' 
			) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Disk Cleanup feature is designed as a partner to the Backup feature. It''s purpose is to prevent a situation where there are excessive backup files taking up disk space on backup media. The disk cleanup feature is intentionally limited to purging files of extensions .bak, .trn, .cer, and .key.' 
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Disk Cleanup'
									AND InfoT.InfoTypeDesc = 'Description')
END
--Configuration Feature Description
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Configuration'
					AND InfoT.InfoTypeDesc = 'Description' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Configuration' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Description' ) AS [InformationTypeID]
			, ( 
			'The Configuration feature of this Database Maintenance Utility is referring to both the meta data stored and the structure/organization of the features. This enables features to be snapped in and out of the database as necessary for future releases along with providing versioning, description, examples, and other helpful information to the user. All features are setup in a dual tiered approach where administrators can enable/disable entire configurations or individual feature options.' 
			) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = 'The Configuration feature of this Database Maintenance Utility is referring to both the meta data stored and the structure/organization of the features. This enables features to be snapped in and out of the database as necessary for future releases along with providing versioning, description, examples, and other helpful information to the user. All features are setup in a dual tiered approach where administrators can enable/disable entire configurations or individual feature options.' 
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Configuration'
									AND InfoT.InfoTypeDesc = 'Description')
END
/****************************************************/

/*	Set Deployment Service Account information		*/

IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'ServiceAccount' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'ServiceAccount' ) AS [InformationTypeID]
			, ( '$(ServiceAccount)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(ServiceAccount)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'ServiceAccount')
END
GO
/****************************************************/

/*			Set Environment information				*/
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'Environment' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Environment' ) AS [InformationTypeID]
			, ( '$(Environment)' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '$(Environment)'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'Environment')
END
GO
/****************************************************/

/*		Populate initial audit option record.		*/
IF NOT EXISTS (SELECT OptionID FROM [Audit].[Options])
	INSERT INTO [Audit].[Options] ( [PurgeValue], [PurgeTypeID] ) VALUES (NULL, NULL);
/****************************************************/

/*			Set Package Store information			*/
--Utility DB registered SSIS Package store
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'Utility'
					AND InfoT.InfoTypeDesc = 'SSIS Package Store' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'Utility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'SSIS Package Store' ) AS [InformationTypeID]
			,	( 
					SELECT CASE ( '$(Environment)' ) 
								WHEN 'DEV' THEN 'V-DEV-DB-008'
								WHEN 'SIT' THEN 'SSISPackageStore.db.SIT.libertytax.net'
								WHEN 'QA' THEN 'SSISPackageStore.db.QA.libertytax.net'
								WHEN 'PROD' THEN 'SSISPackageStore.db.libertytax.net'
							END
				) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = ( 
					SELECT CASE ( '$(Environment)' )  
								WHEN 'DEV' THEN 'V-DEV-DB-008'
								WHEN 'SIT' THEN 'SSISPackageStore.db.SIT.libertytax.net'
								WHEN 'QA' THEN 'SSISPackageStore.db.QA.libertytax.net'
								WHEN 'PROD' THEN 'SSISPackageStore.db.libertytax.net'
							END
					)
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Utility'
									AND InfoT.InfoTypeDesc = 'SSIS Package Store')
END
/****************************************************/

/*Create SQL Agent Operator if one does not exist*/
USE [msdb]
GO

DECLARE @recipients VARCHAR(500);
SELECT @recipients = [Detail] 
FROM [$(DatabaseName)].[Configuration].[InformationDetails] InfoD
INNER JOIN [$(DatabaseName)].[Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
INNER JOIN [$(DatabaseName)].[Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
WHERE F.FeatureName = 'Utility'
	AND InfoT.InfoTypeDesc = 'Alert Recipients'

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'OPERATOR', @type=N'NONE', @name=N'Database Maintenance Utility'
END

IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DatabaseAdministration')
EXEC msdb.dbo.sp_add_operator @name=N'DatabaseAdministration', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=@recipients, 
		@category_name=N'Database Maintenance Utility'
GO
/***************************************************/


/*
Utility - Disk Cleanup File Purge job
--------------------------------------------------------------------------------------
 This drops and creates the Disk Cleanup File Purge job 
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Disk Cleanup File Purge]'

USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Disk Cleanup File Purge')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Disk Cleanup File Purge'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO



BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Disk Cleanup File Purge', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Deletes log and full backup files that are registered with a Disk Cleanup Config.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)', 
		@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
END   
ELSE
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Disk Cleanup File Purge', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Deletes log and full backup files that are registered with a Disk Cleanup Config.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)',  @job_id = @jobId OUTPUT
END

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete bak files]    Script Date: 03/19/2012 12:25:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [DiskCleanup].[usp_RemoveOldBackupFiles]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Midnight', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120125, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



/*
Backup Job Spawning Controller					
--------------------------------------------------------------------------------------
 This drops and creates the Backup Job Spawning Controller job 
 which has an added step to run the [usp_RefreshRegisteredDatabases] proc
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Backup Job Spawning Controller]'

USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Backup Job Spawning Controller')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Backup Job Spawning Controller'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO


BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Backup Job Spawning Controller', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job triggers a stored procedure which parses the Utility database configuration tables and identifies all of the backup jobs that should exist. It then spawns new job and drops others where necessary.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)', 
		@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
END   
ELSE
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Backup Job Spawning Controller', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job triggers a stored procedure which parses the Utility database configuration tables and identifies all of the backup jobs that should exist. It then spawns new job and drops others where necessary.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)',  @job_id = @jobId OUTPUT
END

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Refresh Registered Databases', 
	@step_id=1, 
	@cmdexec_success_code=0, 
	@on_success_action=3, 
	@on_success_step_id=0, 
	@on_fail_action=2, 
	@on_fail_step_id=0, 
	@retry_attempts=0, 
	@retry_interval=0, 
	@os_run_priority=0, @subsystem=N'TSQL', 
	@command=N'EXEC [Configuration].[usp_RefreshRegisteredDatabases] @Purge = 1', 
	@database_name=N'Utility', 
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trigger Job Spawning', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [Backup].[usp_SpawnedJobsController]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'5 mins', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120327, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


USE [msdb]
GO

/*
Cycle Trace File job						
--------------------------------------------------------------------------------------
 This drops and creates the cycle trace file job 
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Cycle All Trace Tables]'

USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Cycle All Trace Tables')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Cycle All Trace Tables'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO

BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Cycle All Trace Tables', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Daily at midnight, cycles all trace tables in the Utility database with a Purge date of TODAY-7 days.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC [Trace].usp_CycleTraceTables', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=2, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [Trace].usp_CycleTraceTables', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Midnight', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120124, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

/*
Populate current tables job.					
--------------------------------------------------------------------------------------
 This job merges trace file data with the current trace table.
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and recreating Job [Utility - PopulateCurrentTraceTables]'
USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - PopulateCurrentTraceTables')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - PopulateCurrentTraceTables'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO


BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - PopulateCurrentTraceTables', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Populate Traces]    Script Date: 02/02/2012 15:34:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate Traces', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [Trace].[usp_PopulateCurrentTraceTables]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Minute', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120127, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

/*
Reindexing Job					
--------------------------------------------------------------------------------------
 This creates the reindexing job if it doesn't exist already.
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Selective Reindex All Databases]'
USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Selective Reindex All Databases')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Selective Reindex All Databases'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO


BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Selective Reindex All Databases', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name='$(ServiceAccount)',
		@notify_email_operator_name=N'DatabaseAdministration',
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Record Index Fragmentation', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [IndexMaint].[usp_UpdateIndexStatistics]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defrag Indexes', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [IndexMaint].[usp_SelectiveReIndex]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110120, 
		@active_end_date=99991231, 
		@active_start_time=14500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

/*
Validate Backup Plans Job					
--------------------------------------------------------------------------------------
 This drops the [Utility - Validate Backup Plans] job
--------------------------------------------------------------------------------------
*/
USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Backup Plans')
BEGIN
	PRINT 'Dropping and Creating Job [Utility - Validate Backup Plans] - Clean up from previous version 2.2.2 and below'
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Backup Plans'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO

/*
Validate Backup Plans Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Validate Backup Plans] job
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Validate Feature Configurations]'

USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Feature Configurations')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Feature Configurations'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO

BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Validate Feature Configurations', 
	@enabled=1, 
	@notify_level_eventlog=0, 
	@notify_level_email=2, 
	@notify_level_netsend=0, 
	@notify_level_page=0, 
	@delete_level=0, 
	@description=N'This job will execute the necessary stored procedures to send alerts when database backups, disk clean-up, and index maintenance features are misconfigured.', 
	@category_name=N'Database Maintenance Utility', 
	@owner_login_name='$(ServiceAccount)', 
	@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC [Backup].[usp_VerifyBackupPlansExist]', 
	@step_id=1, 
	@cmdexec_success_code=0, 
	@on_success_action=3, 
	@on_success_step_id=0, 
	@on_fail_action=2, 
	@on_fail_step_id=0, 
	@retry_attempts=0, 
	@retry_interval=0, 
	@os_run_priority=0, @subsystem=N'TSQL', 
	@command=N'EXEC [Utility].[Backup].[usp_VerifyBackupPlansExist] @debug = 0, @MailProfile = ''DefaultMailProfile''', 
	@database_name=N'Utility', 
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC [DiskCleanup].[usp_VerifyDiskCleanupPlansExist]', 
	@step_id=2, 
	@cmdexec_success_code=0, 
	@on_success_action=1, 
	@on_success_step_id=0, 
	@on_fail_action=2, 
	@on_fail_step_id=0, 
	@retry_attempts=0, 
	@retry_interval=0, 
	@os_run_priority=0, @subsystem=N'TSQL', 
	@command=N'EXEC [Utility].[DiskCleanup].[usp_VerifyDiskCleanupPlansExist] @debug = 0, @MailProfile = ''DefaultMailProfile''', 
	@database_name=N'Utility', 
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120919, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

/*
Purge Log Entries Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Purge Log Entries] job
--------------------------------------------------------------------------------------
*/
USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Log Entries')
BEGIN
	PRINT 'Dropping Job [Utility - Purge Log Entries] - Clean up from previous version 2.2.3 and below'
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Log Entries'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO

/*
Purge Table Entries Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Purge Table Entries] job
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and recreating Job [Utility - Purge Table Entries]'
USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Table Entries')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Table Entries'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO


BEGIN TRANSACTION

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Purge Table Entries', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'Database Maintenance Utility', 
			@owner_login_name='$(ServiceAccount)', 
			@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
END   
ELSE
BEGIN
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Utility - Purge Table Entries', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'Database Maintenance Utility', 
			@owner_login_name='$(ServiceAccount)',  @job_id = @jobId OUTPUT
END       
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Log Entries', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [Utility].[Logging].[usp_PurgeLogEntries]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge DDL Audit Entries', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [Utility].[Audit].[usp_PurgeDDLEntries]', 
		@database_name=N'Utility', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121216, 
		@active_end_date=99991231, 
		@active_start_time=600, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


/*						Correct db owner						*/
USE [$(DatabaseName)]; 
IF EXISTS ( SELECT name
			FROM   sys.databases
			WHERE SUSER_SNAME(owner_sid) <> 'sa' 
				AND NAME = '$(DatabaseName)'
		  )
BEGIN
	EXEC sp_changedbowner 'sa';
END
/****************************************************************/

/***************** Setup Server DDL Auditing **************************/

IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
	EXEC [Utility].[Audit].[usp_SetupServerDDLAudit]

/**********************************************************************/

/** End Post-Deployment Script **/