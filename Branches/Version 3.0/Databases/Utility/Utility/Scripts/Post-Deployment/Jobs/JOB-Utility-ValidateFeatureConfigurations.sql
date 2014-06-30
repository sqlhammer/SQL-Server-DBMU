SET NOCOUNT ON;

/*
Validate Backup Plans Job					
--------------------------------------------------------------------------------------
 This drops the [Utility - Validate Backup Plans] job
 REMOVE IN FUTURE VERSIONS ONCE ALL JOBS BY THIS NAME HAVE BEEN DROPPED ON ALL SERVERS
--------------------------------------------------------------------------------------
*/
USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Backup Plans')
BEGIN
	PRINT 'Dropping and Creating Job [Utility - Validate Backup Plans] - Clean up from previous version 2.2.2 and below'
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Backup Plans'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END


/**************************************************************************************/

/*
Validate Feature Configurations Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Validate Feature Configurations] job
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and Creating Job [Utility - Validate Feature Configurations]'

USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Feature Configurations')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Validate Feature Configurations'
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


