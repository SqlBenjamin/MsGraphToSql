USE [msdb];
GO

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'MsGraphSyncToSql_JobMonitor')
BEGIN
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'MsGraphSyncToSql_JobMonitor', @delete_unused_schedule = 1;
    PRINT 'Job "MsGraphSyncToSql_JobMonitor" Deleted.';
END;
GO

/********************************************************************************************
Object: dbo.MsGraphSyncToSql_JobMonitor
Purpose: This job runs a PowerShell script to sync data from Graph to SQL.

History:
Date          Version    Author                   Notes:
06/30/2020    0.0        Benjamin Reynolds        Created.
********************************************************************************************/

BEGIN TRANSACTION;
DECLARE  @ReturnCode int = 0
        ,@JobName sysname = N'MsGraphSyncToSql_JobMonitor'
        ,@JobCategory sysname = N'Ops Monitor';

/********************************************************************************************
    Create the Job Category if it doesn't exist
********************************************************************************************/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = @JobCategory AND category_class = 1)
BEGIN
    EXECUTE @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB', @type = N'LOCAL', @name = @JobCategory;
    IF (@@ERROR != 0 OR @ReturnCode != 0)
    GOTO QuitWithRollback;
END;

/********************************************************************************************
    Create the Job and pick up the job_id
********************************************************************************************/
DECLARE @jobId binary(16);
EXECUTE  @ReturnCode = msdb.dbo.sp_add_job 
         @job_name = @JobName
        ,@enabled = 1
        ,@notify_level_eventlog = 2
        ,@notify_level_email = 0
        ,@notify_level_netsend = 0
        ,@notify_level_page = 0
        ,@delete_level = 0
        ,@description = N'This job monitors the "MsGraphSyncToSql%" jobs and triggers an email alert for each job running longer than the threshold.'
        ,@category_name = @JobCategory
        ,@owner_login_name = N'sa'
        ,@job_id = @jobId OUTPUT;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

/********************************************************************************************
    Create the steps for the Job
********************************************************************************************/
-- Step One
EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep
        @job_id = @jobId
       ,@step_name = N'Check any IntuneSyncToSql job against the threshold and alert if necessary'
       ,@step_id = 1
       ,@cmdexec_success_code = 0
       ,@on_success_action = 1 -- quit the job reporting success
       ,@on_success_step_id = 0
       ,@on_fail_action = 2 --2=Quit the job reporting failure; 1=Quit the job reporting success
       ,@on_fail_step_id = 0
       ,@retry_attempts = 3
       ,@retry_interval = 5
       ,@os_run_priority = 0
       ,@subsystem = N'TSQL'
       ,@command = N'EXECUTE dbo.usp_IntuneSyncToSqlMonitor 2;'
       ,@database_name = N'Intune'
       ,@flags = 0;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

/********************************************************************************************
    Update the Job to create settings
********************************************************************************************/
-- Set the start step
EXECUTE @ReturnCode = msdb.dbo.sp_update_job
        @job_id = @jobId
       ,@start_step_id = 1;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

-- Create/set the schedule
EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id = @jobId
       ,@name = N'Every 1 hour'
       ,@enabled = 1
       ,@freq_type = 4 -- Daily
       ,@freq_interval = 1 -- daily
       ,@freq_subday_type = 8 -- hours
       ,@freq_subday_interval = 1
       ,@freq_relative_interval = 0
       ,@freq_recurrence_factor = 0
       ,@active_start_date = 20081026
       ,@active_end_date = 99991231
       ,@active_start_time = 0 -- midnight (HHMMSS)
       ,@active_end_time = 235959;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

-- Set the server to run as the local server
EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver
        @job_id = @jobId
       ,@server_name = N'(local)';
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

COMMIT TRANSACTION;
PRINT 'Job "'+@JobName+'" Created.';
GOTO EndSave;

QuitWithRollback:
IF (@@TRANCOUNT > 0)
ROLLBACK TRANSACTION;
PRINT 'Job "'+@JobName+'" NOT CREATED; Transaction Rolledback.';

EndSave:
-- End of script
GO