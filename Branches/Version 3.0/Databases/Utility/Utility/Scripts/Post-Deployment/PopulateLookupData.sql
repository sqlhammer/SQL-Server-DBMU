SET NOCOUNT ON;
USE [$(DatabaseName)];

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
