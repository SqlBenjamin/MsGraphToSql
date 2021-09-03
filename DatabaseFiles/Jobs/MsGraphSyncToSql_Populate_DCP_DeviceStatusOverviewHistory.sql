USE [msdb];
GO

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'MsGraphSyncToSql_Populate_DCP_DeviceStatusOverviewHistory')
BEGIN
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'MsGraphSyncToSql_Populate_DCP_DeviceStatusOverviewHistory', @delete_unused_schedule = 1;
    PRINT 'Job "MsGraphSyncToSql_Populate_DCP_DeviceStatusOverviewHistory" Deleted.';
END;
GO

/********************************************************************************************
Object: dbo.MsGraphSyncToSql_Populate_DCP_DeviceStatusOverviewHistory
Purpose: This job populates and deletes records in DeviceCompliancePoliciesDeviceStatusOverviewHistory.

History:
Date          Version    Author                   Notes:
08/02/2021    0.0        Benjamin Reynolds        Created.

NOTE: Make sure to update the environmental variables below before running!
********************************************************************************************/

BEGIN TRANSACTION;
-- UPDATE THESE VARIABLES FOR YOUR ENVIRONMENT!
DECLARE  @DBMail_ProfileName nvarchar(1000) = N'DBA Email' -- A valid db mail profile name
        ,@DBMail_Recipients nvarchar(1000) = N'user@contoso.com;user2@contoso.com' -- semi-colon separated list of email addresses
        ,@DBMail_CopyRecipients nvarchar(1000) = N''; -- semi-colon separated list of email addresses if desired
----------------------------------------------------------------------------------------------
DECLARE  @ReturnCode int = 0
        ,@JobName sysname = N'MsGraphSyncToSql_Populate_DCP_DeviceStatusOverviewHistory'
        ,@JobCategory sysname = N'Data Collector'
        ,@FailureEmailCommand nvarchar(max)
        ,@UseDbMailItems bit;

-- See if the DB Mail Profile exists:
SELECT @UseDbMailItems = 1
  FROM msdb.dbo.sysmail_profileaccount pra
       INNER JOIN msdb.dbo.sysmail_profile pro
          ON pra.profile_id = pro.profile_id
       INNER JOIN msdb.dbo.sysmail_account acc
          ON pra.account_id = acc.account_id
 WHERE pro.name = @DBMail_ProfileName;
SELECT @UseDbMailItems = ISNULL(@UseDbMailItems,0);

-- Determine what commands to use for mail items:
IF @UseDbMailItems = 1
BEGIN
  SELECT @FailureEmailCommand = N'EXECUTE msdb.dbo.sp_send_dbmail
     @profile_name = N'''+@DBMail_ProfileName+N'''
	,@recipients = N'''+@DBMail_Recipients+N''''+
	CASE WHEN ISNULL(@DBMail_CopyRecipients,N'') != N'' THEN CHAR(13)+N'    ,@copy_recipients = N'''+@DBMail_CopyRecipients+N'''' ELSE N'' END+N'
	,@subject = N''"'+@JobName+N'" job failure Email Notification ('+@@SERVERNAME+N')''
	,@body = N''<font face="Calibri,Verdana,Arial" size=4>"'+@JobName+N'" Job has failed on "<b>'+@@SERVERNAME+N'</b>". Please look into this.</font>''
	,@body_format = N''HTML''
	,@importance = N''High'';';
END;
ELSE
BEGIN
  SELECT @FailureEmailCommand = N'PRINT ''No DB Mail setup to send dbmail out for alerting on the failure. This step will just be ignored.'';';
END;

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
        ,@description = N'This Populates/Deletes the data in DeviceCompliancePoliciesDeviceStatusOverviewHistory'
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
       ,@step_name = N'Populate or Update the DeviceCompliancePoliciesDeviceStatusOverviewHistory table with the new/updated records'
       ,@step_id = 1
       ,@cmdexec_success_code = 0
       ,@on_success_action = 3 --3 -- Go to the next step
       ,@on_success_step_id = 0
       ,@on_fail_action = 4 --4 Go to step
       ,@on_fail_step_id = 3
       ,@retry_attempts = 0
       ,@retry_interval = 0
       ,@os_run_priority = 0
       ,@subsystem = N'TSQL'
       ,@command = N'EXECUTE dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable;'
       ,@database_name = N'Intune'
       ,@flags = 0;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

-- Step Two
EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep
        @job_id = @jobId
       ,@step_name = N'Delete older records from DeviceCompliancePoliciesDeviceStatusOverviewHistory'
       ,@step_id = 2
       ,@cmdexec_success_code = 0
       ,@on_success_action = 1 -- Quit reporting success
       ,@on_success_step_id = 0
       ,@on_fail_action = 4 -- 4=Go to step
       ,@on_fail_step_id = 3
       ,@retry_attempts = 0
       ,@retry_interval = 0
       ,@os_run_priority = 0
       ,@subsystem = N'TSQL'
       ,@command = N'EXECUTE dbo.usp_DeleteDCPDeviceStatusOverviewHistoryTable @DaysToKeep = 183;'
       ,@database_name = N'Intune'
       ,@flags = 0;
IF (@@ERROR != 0 OR @ReturnCode != 0)
GOTO QuitWithRollback;

-- Step Three
EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep
        @job_id = @jobId
       ,@step_name = N'Failure - Email Notification'
       ,@step_id = 3
       ,@cmdexec_success_code = 0
       ,@on_success_action = 2
       ,@on_success_step_id = 0
       ,@on_fail_action = 2 --2=Quit the job reporting failure; 1=Quit the job reporting success
       ,@on_fail_step_id = 0
       ,@retry_attempts = 0
       ,@retry_interval = 0
       ,@os_run_priority = 0
       ,@subsystem = N'TSQL'
       ,@command =@FailureEmailCommand
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