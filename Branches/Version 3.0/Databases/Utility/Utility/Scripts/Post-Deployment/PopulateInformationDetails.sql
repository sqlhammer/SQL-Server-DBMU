SET NOCOUNT ON;
USE [$(DatabaseName)];
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
