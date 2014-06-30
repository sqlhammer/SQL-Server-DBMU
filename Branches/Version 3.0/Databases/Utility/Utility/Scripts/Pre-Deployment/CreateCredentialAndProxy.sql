SET NOCOUNT ON;
--Create credential and proxy
USE [msdb];


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


