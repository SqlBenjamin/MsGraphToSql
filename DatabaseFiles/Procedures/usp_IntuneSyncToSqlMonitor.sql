USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_IntuneSyncToSqlMonitor') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_IntuneSyncToSqlMonitor;
    PRINT 'Sproc "usp_IntuneSyncToSqlMonitor" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_IntuneSyncToSqlMonitor
Purpose: The Purpose of this Stored Procedure is to create an email alert for any currently running jobs that
         exceed the threshold. The job should only create one alert per job run.

History:
Date          Version    Author                   Notes:
06/30/2020    0.0        Benjamin Reynolds        Created.
09/04/2020    0.0        Benjamin Reynolds        Added additional ErrorDetails check due to an additional non actionable error
                                                  message added to the process.
02/04/2021    0.0        Benjamin Reynolds        Added logic for customized thresholds and multiple alerts.

NOTE: Make sure to update the environmental variables below (far below) before running!
*****************************************************************************************************************/

CREATE PROCEDURE dbo.usp_IntuneSyncToSqlMonitor
    @ThresholdHours tinyint
AS

BEGIN
SET NOCOUNT ON;

DECLARE @TableInfo table ( ID int NOT NULL PRIMARY KEY CLUSTERED
                          ,BatchID int NOT NULL
                          ,JobName nvarchar(256) NULL
                          ,TableName sysname NOT NULL
                          ,ErrorNumber int NULL
                          ,ErrorMessage nvarchar(max) NULL
                          ,StartDateUTC datetime2 NOT NULL
                          ,EndDateUTC datetime2 NULL
                          ,Duration_HhMmSsMs varchar(25) NULL                    
                          ,TotalRecordsImported int NULL
                          ,TotalRecordsNotImported int NULL
                          ,ThresholdHours int NOT NULL
                          --,isFirstAlert bit NOT NULL
                          ,EmailPriority nvarchar(15) NOT NULL
                          ,JobStartDateUTC datetime2 NOT NULL
                          );

;WITH RunningJobs AS (
SELECT  job.job_id
       ,job.name
       --,act.start_execution_date
       --,CASE his.run_status
       --      WHEN 0 THEN 'Failed'
       --      WHEN 1 THEN 'Succeeded'
       --      WHEN 2 THEN 'Running' --'Retry'
       --      WHEN 3 THEN 'Cancelled'
       --      WHEN 4 THEN 'Running' --'In Progress'
       --      ELSE CASE WHEN act.start_execution_date IS NULL AND act.stop_execution_date IS NULL THEN 'Idle'
       --                WHEN act.start_execution_date IS NOT NULL AND act.stop_execution_date IS NULL THEN 'Running'
       --           END
       -- END AS [Status]
       ,DATEDIFF_BIG(second,act.start_execution_date,GETDATE()) AS [RunDurationSeconds]
       ,lrt.ThresholdHours
  FROM msdb.dbo.sysjobs job
       INNER JOIN msdb.dbo.sysjobactivity act
          ON job.job_id = act.job_id
       INNER JOIN (
                   SELECT MAX(session_id) AS [MaxSession]
                     FROM msdb.dbo.syssessions
                   ) ses
          ON act.session_id = ses.MaxSession
        LEFT OUTER JOIN msdb.dbo.sysjobhistory his
          ON job.job_id = his.job_id
         AND act.job_history_id = his.instance_id
        LEFT OUTER JOIN dbo.LongRunningJobThresholds lrt
          ON job.name = lrt.JobName
 WHERE (his.run_status IN (2,4)
        OR (act.start_execution_date IS NOT NULL AND act.stop_execution_date IS NULL)
        )
   AND job.name LIKE N'MsGraphSyncToSql%'
   AND job.name != N'MsGraphSyncToSql_JobMonitor'
)
,LatestJobBatchId AS (
SELECT  JobName
       ,MAX(ID) AS [BatchID]
  FROM dbo.PowerShellRefreshHistory
 GROUP BY JobName
)
,JobsOverThreshold AS (
SELECT  run.name AS [JobName]
       ,ljb.BatchID
       ,run.RunDurationSeconds
       ,ISNULL(run.ThresholdHours,ISNULL(@ThresholdHours,4)) AS [ThresholdHours]
       ,CASE WHEN run.ThresholdHours IS NOT NULL THEN 1 ELSE 0 END AS [isThresholdDefined]
       ,psh.StartDateUTC AS [JobStartDateUTC]
  FROM RunningJobs run
       INNER JOIN LatestJobBatchId ljb
          ON run.name = ljb.JobName
       INNER JOIN dbo.PowerShellRefreshHistory psh
          ON ljb.BatchID = psh.ID
 WHERE run.RunDurationSeconds >= ISNULL(run.ThresholdHours,ISNULL(@ThresholdHours,4))*3600
)
,SyncToSqlMonitor AS (
SELECT  BatchID
       ,MAX(AlertDateUTC) AS [MaxAlertDateUTC]
  FROM dbo.IntuneSyncToSqlMonitor
 GROUP BY BatchID
)
INSERT @TableInfo
SELECT  trh.ID
       ,trh.BatchID
       ,jot.JobName
       ,trh.TableName
       ,trh.ErrorNumber
       ,CONVERT(nvarchar(max),trh.ExtendedInfo.query('distinct-values(/SpecificURLs/SpecificURL[ErrorDetails != "No Records returned; Moving to next URL/table..." and ErrorDetails != "No data for the expanded column was found."]/ErrorDetails/text())')) AS [ErrorMessage]
       ,trh.StartDateUTC
       ,trh.EndDateUTC
       ,trh.Duration_HhMmSsMs
       ,trh.TotalRecordsImported
       ,trh.TotalRecordsNotImported
       ,jot.ThresholdHours
       --,CASE WHEN mon.BatchID IS NULL THEN 1 ELSE 0 END AS [isFirstAlert]
       ,CASE WHEN mon.BatchID IS NULL AND jot.isThresholdDefined = 0 THEN N'Normal' -- First Email and no custom threshold defined
             ELSE N'High'
        END AS [EmailPriority]
       ,jot.JobStartDateUTC
  FROM dbo.v_TableRefreshHistory trh
       INNER JOIN JobsOverThreshold jot
          ON trh.BatchID = jot.BatchID
        LEFT OUTER JOIN SyncToSqlMonitor mon
          ON trh.BatchID = mon.BatchID
 WHERE mon.BatchID IS NULL
    OR DATEDIFF(hour,mon.MaxAlertDateUTC,GETUTCDATE()) > CASE WHEN ThresholdHours < 48 THEN 24 ELSE 99999 END;


-- If data made it into the table then we can alert on it:
IF EXISTS (SELECT * FROM @TableInfo)
BEGIN
-- Insert into the lookup table to avoid duplicate alerts:
INSERT INTO dbo.IntuneSyncToSqlMonitor (BatchID,JobName,AlertMessage)
SELECT  DISTINCT BatchID
       ,JobName
       ,N'"' + JobName + N'" has been running for more than "' + CAST(DATEDIFF(hour,JobStartDateUTC,GETUTCDATE()) AS nvarchar(3)) + N'" hours. Please investigate.' AS [AlertMessage]
  FROM @TableInfo;

-- Create the dynamic Sql to run in order to send the alert(s):
DECLARE  @SqlCmd nvarchar(max) = N''
--------------------- UPDATE THESE VARIABLES FOR YOUR ENVIRONMENT! ----------------------------------------
        ,@email_profile nvarchar(256) = N'DBA Email' -- A valid db mail profile name
        ,@emailrecipients nvarchar(500) =  N'user@contoso.com;user2@contoso.com' -- semi-colon separated list of email addresses
        ,@emailCCrecipients nvarchar(500) = N'' -- semi-colon separated list of email addresses if desired
-----------------------------------------------------------------------------------------------------------
        ,@msgbodynontable nvarchar(max) = N'Intune Sync to SQL Data Refresh Details';

;WITH DistinctAlerts AS (
SELECT DISTINCT BatchID, JobName, JobStartDateUTC/*, isFirstAlert*/, EmailPriority FROM @TableInfo
)
SELECT @SqlCmd = @SqlCmd + N'
EXECUTE msdb.dbo.sp_send_dbmail @profile_name = N''' + @email_profile + N'''
    ,@recipients = N''' + @emailrecipients + N'''
    ,@copy_recipients = N''' + @emailCCrecipients + N'''
    ,@subject = N''"' + JobName + N'" has been running for more than "' + CAST(DATEDIFF(hour,JobStartDateUTC,GETUTCDATE()) AS nvarchar(3)) + N'" hours on "' + @@SERVERNAME + N'" server''
    ,@importance = N'''+EmailPriority+N'''
    ,@body = N''<html><body><H1>' + @msgbodynontable + '</H1>
<table border="1" style="background-color: #C0C0C0; border-collapse: collapse">               
<caption style="font-weight: bold">****** "' + JobName + N'" has been running for more than "' + CAST(DATEDIFF(hour,JobStartDateUTC,GETUTCDATE()) AS nvarchar(3)) + N'" hours, so please investigate. Below are the details." ******</caption>
<tr>           
<th style="text-decoration: underline">BatchID</th>
<th style="text-decoration: underline">ID</th>
<th style="text-decoration: underline">TableName</th>
<th style="text-decoration: underline">ErrorNumber</th>
<th style="text-decoration: underline">ErrorMessage</th>
<th style="text-decoration: underline">StartDateUTC</th>
<th style="text-decoration: underline">EndDateUTC</th>
<th style="text-decoration: underline">Duration(hh:mm:ss)</th>  
<th style="text-decoration: underline">TotalRecordsImported</th>
<th style="text-decoration: underline">TotalRecordsNotImported</th>  
</tr>' + CONVERT(nvarchar(max),(
                                SELECT  td = tbi.BatchID
                                       ,''
                                       ,td = tbi.ID
                                       ,''
                                       ,td = tbi.TableName
                                       ,''
                                       ,td = tbi.ErrorNumber
                                       ,''
                                       ,td = tbi.ErrorMessage
                                       ,''
                                       ,td = tbi.StartDateUTC
                                       ,''
                                       ,td = tbi.EndDateUTC
                                       ,''
                                       ,td = tbi.Duration_HhMmSsMs
                                       ,''
                                       ,td = tbi.TotalRecordsImported
                                       ,''
                                       ,td = tbi.TotalRecordsNotImported
                                  FROM @TableInfo tbi
                                 WHERE tbi.BatchID = dsa.BatchId
                                 ORDER BY ID
                                   FOR XML PATH('tr'),TYPE,ELEMENTS XSINIL
                                )
                 ) + N'</table></body></html>''
    ,@body_format = ''HTML'';
'
  FROM DistinctAlerts dsa;

-- Execute the dynamic Sql to create the alert(s) (Only if the db mail profile exists!):
IF EXISTS (
SELECT *
  FROM msdb.dbo.sysmail_profileaccount pra
       INNER JOIN msdb.dbo.sysmail_profile pro
          ON pra.profile_id = pro.profile_id
       INNER JOIN msdb.dbo.sysmail_account acc
          ON pra.account_id = acc.account_id
 WHERE pro.name = @email_profile
)
EXECUTE sp_ExecuteSql @SqlCmd;

END;
END;
GO

IF OBJECT_ID(N'dbo.usp_IntuneSyncToSqlMonitor') IS NOT NULL
PRINT 'Sproc "usp_IntuneSyncToSqlMonitor" Created.';
ELSE
PRINT 'Sproc "usp_IntuneSyncToSqlMonitor" NOT CREATED...Check for errors!';
GO