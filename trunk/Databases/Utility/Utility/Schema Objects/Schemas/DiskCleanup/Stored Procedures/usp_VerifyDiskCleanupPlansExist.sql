/*
PROCEDURE:		[DiskCleanup].[usp_VerifyDiskCleanupPlansExist]
AUTHOR:			Derik Hammer
CREATION DATE:	11/17/2013
DESCRIPTION:	Job to check for backup plans and alter administrators if databases aren't being backed up properly.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enabled a print out of all statements which would
					have been conducted. The stored procedures referenced by this one will not actually be executed,
					nor will any other DML/DDL/DB_Mail commands.
*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [DiskCleanup].[usp_VerifyDiskCleanupPlansExist]
	@debug BIT = 0,
	@MailProfile VARCHAR(128)
AS
	DECLARE @body NVARCHAR(4000)
	DECLARE @sub NVARCHAR(100)
	DECLARE @recipients NVARCHAR(100)
	DECLARE @dbName sysname
	DECLARE @MissingPlanFlag BIT = 0
	DECLARE @sql NVARCHAR(4000)

	--populate log shipped databases to temp table
	-- - this is because we won't throw an alert for log backups if log shipped
	IF OBJECT_ID('tempdb..##log_shipped_databases') IS NOT NULL
		DROP TABLE ##log_shipped_databases
		
	create table ##log_shipped_databases
	(
		status bit null
		,is_primary bit not null default 0
		,server sysname 
		,database_name sysname
		,time_since_last_backup int null
		,last_backup_file nvarchar(500) null
		,backup_threshold int null
		,is_backup_alert_enabled bit null
		,time_since_last_copy int null
		,last_copied_file nvarchar(500) null
		,time_since_last_restore int null
		,last_restored_file nvarchar(500) null
		,last_restored_latency int null
		,restore_threshold int null
		,is_restore_alert_enabled bit null
		,primary key (is_primary, server, database_name)
	)

	INSERT INTO ##log_shipped_databases 
		exec master.sys.sp_help_log_shipping_monitor

	--populate subject line
	SET @sub = 'Utility - Disk Cleanup Plan Violations - ' + @@SERVERNAME

	--populate recipients
	SELECT @recipients = [Detail] 
	FROM [Configuration].[InformationDetails] InfoD
	INNER JOIN [Lookup].[Features] F ON InfoD.FeatureID = F.FeatureID
	INNER JOIN [Lookup].[InformationTypes] InfoT ON InfoT.InformationTypeID = InfoD.InformationTypeID
	WHERE F.FeatureName = 'Utility'
		AND InfoT.InfoTypeDesc = 'Alert Recipients'
	
	--populate heading of email
	SET @body = 'The below listed databases on ' + @@SERVERNAME + ' are in violation of Liberty''s data backup standards.' + 
				CHAR(13) + CHAR(10)
	SET @body = @body + '----------------------------------------------------------------------------------------------------------' + 
				CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		
	--populate disk cleanup list
	IF OBJECT_ID('tempdb..##DiskCleanup_List') IS NOT NULL
		DROP TABLE ##DiskCleanup_List
	
	SELECT sysdbs.name AS [DatabaseName]
		, ISNULL(diskLoc.[FileExtension],'NULL') AS [FileExtension]
		, CASE ISNULL(logShip.database_name,'NULL')
			WHEN 'NULL' THEN 'False'
			ELSE 'True'
		END AS [IsLogShipped]
		, sysDBs.recovery_model_desc AS [recovery_model_desc]
	INTO ##DiskCleanup_List
	FROM master.sys.databases sysDBs
	LEFT JOIN [Configuration].[RegisteredDatabases] regDBs ON regDBs.DatabaseName = sysDBs.NAME
    LEFT JOIN [DiskCleanup].[Databases] dbs ON dbs.DatabaseID = regDBs.DatabaseID
	LEFT JOIN [DiskCleanup].[Options] opts ON opts.OptionID = dbs.OptionID
	LEFT JOIN [Configuration].[DiskLocations] diskLoc ON opts.DiskLocationID = diskLoc.DiskLocationID
	LEFT JOIN [DiskCleanup].[Configs] dskConfigs ON dbs.OptionID = dskConfigs.OptionID AND dskConfigs.IsEnabled = 1
	LEFT JOIN [Configuration].[Configs] Configs ON dskConfigs.ConfigID = Configs.ConfigID AND Configs.IsEnabled = 1
	LEFT JOIN ##log_shipped_databases logShip ON logShip.Database_Name = sysDBs.name
	WHERE sysDBs.state_desc = 'ONLINE'
		AND (regDBs.[VerifyDiskCleanup] = 1 OR regDBs.[VerifyDiskCleanup] IS NULL)
			
	DECLARE disk_cursor CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
	SELECT DatabaseName FROM ##DiskCleanup_List
	WHERE DatabaseName <> 'tempdb'
		AND DatabaseName <> 'distribution'
		
	OPEN disk_cursor
		
	FETCH NEXT FROM disk_cursor INTO @dbName
		
	WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'disk_cursor' ) = 0 
	BEGIN
		--Check for mandatory disk cleanup on .bak files
		IF NOT EXISTS (SELECT DatabaseName FROM ##DiskCleanup_List WHERE DatabaseName = @dbName AND [FileExtension] = 'BAK')
		BEGIN
			SET @body = @body + @dbName + ' --- missing .BAK disk clean-up plan.' + CHAR(13) + CHAR(10)
			SET @MissingPlanFlag = 1
		END
				
		--Check for mandatory .TRN plan
		IF NOT EXISTS (	SELECT DatabaseName 
						FROM ##DiskCleanup_List 
						WHERE DatabaseName = @dbName 
							AND (	[FileExtension] = 'TRN' 
									OR IsLogShipped = 'True' --File retention for log shipped backups is handled by log shipping.
									OR [recovery_model_desc] = 'SIMPLE' --SIMPLE recovery disallows log backups, therfore, doesn't need purging.
								)
						)
		BEGIN
			SET @body = @body + @dbName + ' --- missing .TRN disk clean-up plan.' + CHAR(13) + CHAR(10)
			SET @MissingPlanFlag = 1
		END
			
		FETCH NEXT FROM disk_cursor INTO @dbName
	END			
		
	IF @debug = 1
	BEGIN
		PRINT 'Subject: ' + @sub
		PRINT 'Recipients: ' + @recipients + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		PRINT 'Body: ' + @body
	END  

    --Only send notification if there are violations
	IF @MissingPlanFlag = 1 AND @debug = 0
	BEGIN
		--Send notification
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @MailProfile,
			@recipients = @recipients,
			@subject = @sub,
			@body = @body
	END  

	--garbage cleanup
	DROP TABLE ##log_shipped_databases
	DROP TABLE ##DiskCleanup_List
	
