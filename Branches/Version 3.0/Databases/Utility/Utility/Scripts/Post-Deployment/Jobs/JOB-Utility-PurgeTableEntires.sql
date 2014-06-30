SET NOCOUNT ON;

/*
Purge Log Entries Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Purge Log Entries] job
 ***Clean up from previous version 2.2.3 and below***
--------------------------------------------------------------------------------------
*/
USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Log Entries')
BEGIN
	PRINT 'Dropping Job [Utility - Purge Log Entries] - Clean up from previous version 2.2.3 and below'
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Log Entries'
	EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=1
END


/*
Purge Table Entries Job					
--------------------------------------------------------------------------------------
 This drops and creates the [Utility - Purge Table Entries] job
--------------------------------------------------------------------------------------
*/
PRINT 'Dropping and recreating Job [Utility - Purge Table Entries]'
USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Table Entries')
BEGIN
	DECLARE @jobid uniqueidentifier
	SELECT @jobid = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Utility - Purge Table Entries'
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


