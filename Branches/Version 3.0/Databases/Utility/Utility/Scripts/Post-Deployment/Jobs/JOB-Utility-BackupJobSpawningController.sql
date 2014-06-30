SET NOCOUNT ON;
/*
Backup Job Spawning Controller					
--------------------------------------------------------------------------------------
 This drops and creates the Backup Job Spawning Controller job 
 which has an added step to run the [usp_RefreshRegisteredDatabases] proc
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Backup Job Spawning Controller]'

USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Backup Job Spawning Controller')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Backup Job Spawning Controller'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END



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
IF '$(Environment)' = 'QA' OR '$(Environment)' = 'PROD'
BEGIN
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
		@command=N'EXEC [Configuration].[usp_RefreshRegisteredDatabases]', 
		@database_name=N'Utility', 
		@flags=0
END   
ELSE
BEGIN
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
END
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


