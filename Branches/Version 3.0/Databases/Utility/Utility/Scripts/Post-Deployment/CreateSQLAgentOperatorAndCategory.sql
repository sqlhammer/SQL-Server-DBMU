SET NOCOUNT ON;
/*Create SQL Agent Operator if one does not exist*/
USE [msdb]

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
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'OPERATOR', @type=N'LOCAL', @name=N'Database Maintenance Utility'
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

/***************************************************/

/*Create SQL Agent Job Category is one does note exist*/
USE [msdb]

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance Utility' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance Utility'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/***************************************************/
