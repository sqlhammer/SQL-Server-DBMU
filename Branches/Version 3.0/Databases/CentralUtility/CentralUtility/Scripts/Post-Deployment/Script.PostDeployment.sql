/*
Begin CentralUtility Post-Deployment Script 
*/

/*		Identify environment and service account	*/
IF OBJECT_ID('tempdb..##UtilityServiceAccount') IS NOT NULL
BEGIN
	DROP TABLE ##UtilityServiceAccount
END

CREATE TABLE ##UtilityServiceAccount (ServiceAccount SYSNAME, ServiceSecret VARCHAR(128))

--Identify which service account to use. Pick the lowest environment account found.
IF EXISTS (	SELECT InformationDetailID 
			FROM [Configuration].[InformationDetails] InfoD
			INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
			INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
			WHERE F.FeatureName = 'Utility'
				AND InfoT.InfoTypeDesc = 'ServiceAccount' )
BEGIN
	INSERT INTO ##UtilityServiceAccount (ServiceAccount, ServiceSecret)
	SELECT TOP 1 
		InfoD.Detail
		, CASE InfoD.Detail
			WHEN 'LIBERTY\DevUtility' THEN '3resEG6'
			WHEN 'LIBERTY\SITUtility' THEN 'Yu2abu3'
			WHEN 'LIBERTY\QAUtility' THEN 'CHexUr2'
			WHEN 'LIBERTY\Utility' THEN 'ne4eruH'
		END
	FROM [Configuration].[InformationDetails] InfoD
	INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
	INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
	WHERE F.FeatureName = 'Utility'
		AND InfoT.InfoTypeDesc = 'ServiceAccount'
END
ELSE
BEGIN
	--If the lookup table is missing data resort to an environment IF tree.  
	IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\DevUtility')
	BEGIN
		INSERT INTO ##UtilityServiceAccount (ServiceAccount, ServiceSecret) VALUES (N'LIBERTY\DevUtility','3resEG6')
	END  
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\SITUtility')
		BEGIN
			INSERT INTO ##UtilityServiceAccount (ServiceAccount, ServiceSecret) VALUES (N'LIBERTY\SITUtility','Yu2abu3')
			END  
		ELSE
		BEGIN
			IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\QAUtility')
			BEGIN
				INSERT INTO ##UtilityServiceAccount (ServiceAccount, ServiceSecret) VALUES (N'LIBERTY\QAUtility','CHexUr2')
			END  
			ELSE
			BEGIN
				IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\Utility')
				BEGIN
					INSERT INTO ##UtilityServiceAccount (ServiceAccount, ServiceSecret) VALUES (N'LIBERTY\Utility','ne4eruH')
				END
				ELSE
				BEGIN
					RAISERROR('Appropriate service account not present on server.',16,1)
				END              
			END	
		END		
	END 
END

--Create credential and proxy
USE [msdb];
GO

DECLARE @ServiceAccount SYSNAME
DECLARE @ServiceSecret VARCHAR(128)
SELECT TOP 1 @ServiceAccount = ServiceAccount, @ServiceSecret = ServiceSecret FROM ##UtilityServiceAccount

IF NOT EXISTS (SELECT credential_id FROM master.sys.credentials WHERE name = 'UtilityCredential')
	EXEC ('CREATE CREDENTIAL UtilityCredential WITH IDENTITY = ''' + @ServiceAccount + ''', SECRET = ''' + @ServiceSecret + ''';')
IF NOT EXISTS (SELECT proxy_id FROM msdb.dbo.sysproxies WHERE name = 'UtilityProxy')
BEGIN
	EXEC msdb.dbo.sp_add_proxy @proxy_name=N'UtilityProxy',@credential_name=N'UtilityCredential', @enabled=1
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'UtilityProxy', @subsystem_id=11
END

--Service account needs to be sysadmin so these are irrelevant until we get more granular with the access
--EXEC msdb.dbo.sp_grant_login_to_proxy @login_name = @ServiceAccount, @proxy_name = 'UtilityProxy'

GO
USE [$(DatabaseName)];
GO
/****************************************************/

--Populate [Lookup].[PurgeTypes]
IF NOT EXISTS (SELECT PurgeTypeID FROM [Lookup].[PurgeTypes] WHERE PurgeTypeDesc = 'PURGE BY DAYS')
	INSERT INTO [Lookup].[PurgeTypes] (PurgeTypeDesc) VALUES ('PURGE BY DAYS')
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
IF NOT EXISTS (SELECT FeatureID FROM [Lookup].[Features] WHERE FeatureName = 'CentralUtility')
	INSERT INTO [Lookup].[Features] (FeatureName) VALUES ('CentralUtility')
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
/****************************************************/

/*		Set Deployment Versioning information		*/
--Utility DB Version
IF NOT EXISTS (	SELECT InformationDetailID 
				FROM [Configuration].[InformationDetails] InfoD
				INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
				INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
				WHERE F.FeatureName = 'CentralUtility'
					AND InfoT.InfoTypeDesc = 'Version' )
BEGIN
	INSERT INTO [Configuration].[InformationDetails] (FeatureID, InformationTypeID, Detail) 
		SELECT ( SELECT FeatureID FROM [Lookup].[Features] WHERE [FeatureName] = 'CentralUtility' ) AS [FeatureID]
			, ( SELECT [InformationTypeID] FROM [Lookup].[InformationTypes] WHERE [InfoTypeDesc] = 'Version' ) AS [InformationTypeID]
			, ( '1.00.00' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '1.00.00'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'CentralUtility'
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
			, ( '2.00.00' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '2.00.00'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Logging'
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
			, ( '2.00.00' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '2.00.00'
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
			, ( '2.00.00' ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = '2.00.00'
	WHERE InformationDetailID = (SELECT InformationDetailID 
								FROM [Configuration].[InformationDetails] InfoD
								INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
								INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
								WHERE F.FeatureName = 'Audit'
									AND InfoT.InfoTypeDesc = 'Version')
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
DECLARE @ServiceAccount SYSNAME
SELECT TOP 1 @ServiceAccount = ServiceAccount FROM ##UtilityServiceAccount

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
			, ( @ServiceAccount ) AS [Detail]
END
ELSE
BEGIN
	UPDATE [Configuration].[InformationDetails]
	SET [Detail] = @ServiceAccount
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

/*			Set Initial Utility database string		*/
IF NOT EXISTS	(
					SELECT DataSourceID
					FROM [Configuration].[DataSources]
					WHERE ConnectionName = @@SERVERNAME
				)
BEGIN
	DECLARE @ConenctionString NVARCHAR(4000)
	SET @ConenctionString = N'Data Source=' +  @@SERVERNAME + ';Initial Catalog=Utility;Provider=SQLNCLI10.1;Integrated Security=SSPI;Application Name=Utility;Auto Translate=False;'
	INSERT INTO [Configuration].[DataSources] ([ConnectionName] ,[ConnectionString])
		 VALUES (@@SERVERNAME ,@ConenctionString)
END
/****************************************************/

/*Create SQL Agent Operator if one does not exist*/
USE [msdb]
GO

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
		@email_address=N'DatabaseAdministration@libtax.com', 
		@category_name=N'[Uncategorized]'
GO
/***************************************************/

/*
Load Audit Data Job					
--------------------------------------------------------------------------------------
 This drops and creates the [CentralUtility - Load Audit Data] job
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [CentralUtility - Load Audit Data]'

USE [msdb]
GO

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'CentralUtility - Load Audit Data')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'CentralUtility - Load Audit Data'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END
GO

BEGIN TRANSACTION
--set service account
DECLARE @ServiceAccount SYSNAME
SELECT TOP 1 @ServiceAccount = ServiceAccount FROM ##UtilityServiceAccount

--set ssis package store and Central Utility location
DECLARE @SSISCommand NVARCHAR(4000)
DECLARE @SSISPackageStore NVARCHAR(4000)
DECLARE @CentralUtilityServer SYSNAME

SELECT @CentralUtilityServer =	CASE '$(Environment)'
									WHEN 'DEV' THEN 'V-DEV-DB-008'
									WHEN 'SIT' THEN 'DW.db.SIT.libertytax.net'
									WHEN 'QA' THEN 'DW.db.QA.libertytax.net'
									WHEN 'PROD' THEN 'DW.db.libertytax.net'
								END

SELECT @SSISPackageStore = InfoD.Detail
FROM CentralUtility.[Configuration].[InformationDetails] InfoD
INNER JOIN CentralUtility.[Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
INNER JOIN CentralUtility.[Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
WHERE F.FeatureName = 'Utility'
	AND InfoT.InfoTypeDesc = 'SSIS Package Store'

SET @SSISCommand = N'/SQL "\"\Database Maintenance Utility\LoadAuditDDL\"" /SERVER "\"' + @SSISPackageStore + '\""' + 
	' /SET "\"\Package.Variables[User::CentralUtilityServerName].Properties[Value]\"";"\"' + @CentralUtilityServer + '\"" /CHECKPOINTING OFF /REPORTING E'

--Create category
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

--Create job
DECLARE @jobId BINARY(16)
IF '$(Environment)' = 'DEV' OR '$(Environment)' = 'SIT'
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CentralUtility - Load Audit Data', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name=@ServiceAccount, 
		@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
 END
IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CentralUtility - Load Audit Data', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance Utility', 
		@owner_login_name=@ServiceAccount, 
		@notify_email_operator_name=N'DatabaseAdministration', @job_id = @jobId OUTPUT
END
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Server Audit Data', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=2, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=@SSISCommand, 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'UtilityProxy'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 15 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121022, 
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

/*
Check to see if login accounts exist and create if they do not
GRANT READONLY access to specific objects
*/

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\librasharepointservi')
BEGIN
	CREATE LOGIN [LIBERTY\librasharepointservi] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
END

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'LIBERTY\DiscoveryUtility')
BEGIN
	CREATE LOGIN [LIBERTY\DiscoveryUtility] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
END

USE [$(DatabaseName)]

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'LIBERTY\librasharepointservi')
BEGIN
	CREATE USER [LIBERTY\librasharepointservi] FOR LOGIN [LIBERTY\librasharepointservi]
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'LIBERTY\DiscoveryUtility')
BEGIN
	CREATE USER [LIBERTY\DiscoveryUtility] FOR LOGIN [LIBERTY\DiscoveryUtility]
END

IF NOT EXISTS (SELECT a.name AS rolename,
					  c.name AS username,
					  d.name AS login
			   FROM dbo.sysusers a
			   INNER JOIN dbo.sysmembers b ON a.uid = b.groupuid
			   INNER JOIN dbo.sysusers c ON b.memberuid = c.uid
			   INNER JOIN master.dbo.syslogins d ON c.sid = d.sid
			   WHERE c.name = N'LIBERTY\DiscoveryUtility'
			   AND a.name = 'db_owner')
BEGIN
	EXEC sys.sp_addrolemember @membername = N'LIBERTY\DiscoveryUtility', @rolename = N'db_owner'
END

GRANT SELECT ON Documentation.Databases TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Documentation.vwShowAllDatabases TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Hold.Databases TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Hold.Environments TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Hold.Locations TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Hold.Servers TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Lookup.Environments TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Lookup.Locations TO [LIBERTY\librasharepointservi]
GRANT SELECT ON Lookup.Servers TO [LIBERTY\librasharepointservi]
GO

/*				Garbage Collect						*/
IF OBJECT_ID('tempdb..##UtilityServiceAccount') IS NOT NULL
BEGIN
	DROP TABLE ##UtilityServiceAccount
END
/***************************************************/
/*
End CentralUtility Post-Deployment Script 
*/