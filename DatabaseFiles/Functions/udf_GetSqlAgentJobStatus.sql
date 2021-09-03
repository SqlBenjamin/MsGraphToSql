USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

--Could do: IF blah IS NULL ... EXECUTE (N'CREATE FUNCTION dbo.udf_GetSqlAgentJobStatus() RETURNS varchar(25) BEGIN RETURN ''''; END;');
IF OBJECT_ID(N'dbo.udf_GetSqlAgentJobStatus') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.udf_GetSqlAgentJobStatus;
    PRINT 'Function "udf_GetSqlAgentJobStatus" Deleted.';
END;
GO

/***************************************************************************************************************************
Object: dbo.udf_GetSqlAgentJobStatus
Purpose: This function returns the current status of a SQL Agent Job.

History:
Date          Version    Author                   Notes:
07/23/2021    0.0        Benjamin Reynolds        Created.

***************************************************************************************************************************/


CREATE FUNCTION dbo.udf_GetSqlAgentJobStatus (@JobName nvarchar(512))
RETURNS varchar(50)
AS
BEGIN
  DECLARE @Status varchar(50);
  SELECT @Status =
         CASE his.run_status
              WHEN 0 THEN 'Failed'
              WHEN 1 THEN 'Succeeded'
              WHEN 2 THEN 'Running' --'Retry'
              WHEN 3 THEN 'Cancelled'
              WHEN 4 THEN 'Running' --'In Progress'
              ELSE CASE WHEN act.start_execution_date IS NULL AND act.stop_execution_date IS NULL THEN 'Idle'
                        WHEN act.start_execution_date IS NOT NULL AND act.stop_execution_date IS NULL THEN 'Running'
                   END
         END
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
   WHERE job.name = @JobName;
   RETURN @Status;
END;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.udf_GetSqlAgentJobStatus') IS NOT NULL
PRINT 'Function "udf_GetSqlAgentJobStatus" Created.';
ELSE
PRINT 'Function "udf_GetSqlAgentJobStatus" NOT CREATED...Check for errors!';
GO
