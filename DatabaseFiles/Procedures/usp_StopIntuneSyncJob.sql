USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_StopIntuneSyncJob') IS NOT NULL
BEGIN TRY
    DROP PROCEDURE dbo.usp_StopIntuneSyncJob;
    PRINT 'Sproc "usp_StopIntuneSyncJob" Deleted.';
END TRY
BEGIN CATCH
    PRINT 'Sproc "usp_StopIntuneSyncJob" NOT Deleted.';
    THROW;
END CATCH;
GO

/***************************************************************************************************************
Object: dbo.usp_StopIntuneSyncJob
Purpose: This procedure 

History:
Date          Version    Author                   Notes:
07/22/2021    0.0        Benjamin Reynolds        Created.
07/27/2021    0.0        Benjamin Reynolds        Fixed issue with sending single quotes to the notes.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_StopIntuneSyncJob
    @JobName nvarchar(512)
   ,@ReasonNotes nvarchar(max) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE  @JobId uniqueidentifier
          ,@JobStartDate datetime
          ,@BatchId int
          ,@TableId int
          ,@ReturnCode int
          ,@Status varchar(50)
          ,@AttrName nvarchar(128)
          ,@AttrValue nvarchar(128)
          ,@ErrorMessage nvarchar(max)
          ,@PrintMessage nvarchar(max)
          ,@SqlCmd nvarchar(max)
          ,@KillJobProcessesName nvarchar(512) = N'ECM_IntuneSyncToSql_KillOrphanedProcesses'
          ,@KillTime datetime;

  -- Get the job id if the job is currently running:
  SELECT  @JobId = job.job_id
         ,@JobStartDate = act.start_execution_date-GETDATE()+GETUTCDATE()
    FROM msdb.dbo.sysjobactivity act
         INNER JOIN msdb.dbo.sysjobs job
            ON act.job_id = job.job_id
         INNER JOIN (
                     SELECT MAX(session_id) AS [MaxSession]
                       FROM msdb.dbo.syssessions
                     ) ses
            ON act.session_id = ses.MaxSession
   WHERE job.name = @JobName
     AND act.start_execution_date IS NOT NULL
     AND act.stop_execution_date IS NULL;

  IF @JobId IS NOT NULL
  BEGIN
    -- The job is running so we'll continue

    -- First see if the user has the right perms!
    IF (SELECT  HAS_PERMS_BY_NAME(N'dbo.PowerShellRefreshHistory',N'OBJECT',N'UPDATE')
               +HAS_PERMS_BY_NAME(N'dbo.TableRefreshHistory',N'OBJECT',N'UPDATE')
               +HAS_PERMS_BY_NAME(N'dbo.usp_StopIntuneSyncJob',N'OBJECT',N'EXECUTE')
               +HAS_PERMS_BY_NAME(N'dbo.usp_StartJobAndWaitForCompletion',N'OBJECT',N'EXECUTE')
               +HAS_PERMS_BY_NAME(N'dbo.udf_GetSqlAgentJobStatus',N'OBJECT',N'EXECUTE')) != 5
    BEGIN
      SELECT @PrintMessage = N'User "'+SUSER_SNAME()+N'" doesn''t have sufficient permissions to successfully run this procedure. JIT to an admin or join the Power Users Group to gain sufficient permissions!';
      RAISERROR('%s',16,1,@PrintMessage) WITH NOWAIT;
      GOTO FinishError;
    END;

    -- Get the Job's BatchID
    SELECT TOP 1 @BatchId = ID
      FROM dbo.PowerShellRefreshHistory
     WHERE JobName = @JobName
       AND StartDateUTC >= @JobStartDate
     ORDER BY ID DESC;

     -- Stop the Job via traditional methods:
     EXECUTE @ReturnCode = msdb.dbo.sp_stop_job @job_name = @JobName;

     IF @ReturnCode != 0
     BEGIN
       SELECT @PrintMessage = N'The stop_job request failed to stop the job "'+@JobName+N'".';
       RAISERROR('%s',16,1,@PrintMessage) WITH NOWAIT;
       GOTO FinishError;
     END

     -- Kill the Orphaned Job Processes via the SQL Agent Job:
     SELECT @KillTime = GETDATE();
     EXECUTE dbo.usp_StartJobAndWaitForCompletion @KillJobProcessesName, DEFAULT, @Status OUTPUT;
     IF @Status = 'Running'
     BEGIN
       SELECT @PrintMessage = N'Kill Job still running for some reason...';
       RAISERROR('%s',16,1,@PrintMessage) WITH NOWAIT;
       GOTO FinishError; -- Or retry????
     END;

     -- Read and Display the information from the job:
     SELECT TOP 1 @PrintMessage = CASE WHEN CHARINDEX(N'[[',message) > 0 THEN SUBSTRING(message,CHARINDEX(N'[[',message)+2,CHARINDEX(N']]',message)-(CHARINDEX(N'[[',message)+2)) ELSE N'' END
       FROM msdb.dbo.sysjobhistory his
            INNER JOIN msdb.dbo.sysjobs job
               ON his.job_id = job.job_id
      WHERE job.name = @KillJobProcessesName
        AND his.step_id = 1
        AND his.run_date >= CONVERT(int,CONVERT(varchar(8),@KillTime,112))
        AND his.run_time >= CONVERT(int,FORMAT(@KillTime,N'HHmmss'))
      ORDER BY instance_id DESC;
     RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;

     -- Get logging variables ready:
     IF @ReasonNotes IS NULL
       SET @ReasonNotes = N'';
     IF @ReasonNotes != N''
       SET @ReasonNotes = N' Reason/Notes provided: '+@ReasonNotes;
     SELECT @ErrorMessage = N'Job Stopped by '+SUSER_SNAME()+N'.'+@ReasonNotes;

     -- Get the last table's TableId:
     SELECT TOP 1 @TableId = ID
       FROM dbo.TableRefreshHistory
      WHERE BatchID = @BatchId
      ORDER BY ID DESC;

     -- Using the TableId, get the AttrName and AttrValue needed for the ExtendedInfo stuff:
     SELECT  @AttrName = CASE WHEN LastInstance.value(N'(./SpecificURL/@UriPart)[1]',N'nvarchar(max)') IS NOT NULL THEN 'UriPart' ELSE 'ReportName' END
            ,@AttrValue = COALESCE(LastInstance.value(N'(./SpecificURL/@UriPart)[1]',N'nvarchar(max)'),LastInstance.value(N'(./SpecificURL/@ReportName)[1]',N'nvarchar(max)'))
       FROM (
             SELECT ExtendedInfo.query(N'/SpecificURLs/SpecificURL[last()]') AS [LastInstance]
               FROM dbo.TableRefreshHistory
              WHERE ID = @TableId
             ) lst;

     -- Create and Execute the logging of the stop of the table's processing:
     IF @AttrValue IS NOT NULL -- ExtendedInfo exists and we found the value we need to update the xml
     SELECT @SqlCmd = N'DECLARE @XmlInfo xml = ''<EndDateTimeUTC>''+FORMAT(GETUTCDATE(),''yyyy-MM-ddTHH:mm:ss.fff'')+''</EndDateTimeUTC><NotAllRecordsImported>True</NotAllRecordsImported><ErrorDetails>'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ErrorMessage,N'''',N''''''),N'&',N'&amp;'),N'<',N'&lt;'),N'>',N'&gt;'),N'"',N'&quot;')+N'</ErrorDetails>'';
UPDATE dbo.TableRefreshHistory
   SET  EndDateUTC = SYSUTCDATETIME()
       ,ErrorNumber = -32
       ,ErrorMessage = N'''+REPLACE(@ErrorMessage,N'''',N'''''')+N'''+CASE WHEN ErrorMessage IS NOT NULL THEN CHAR(13)+CHAR(10)+ErrorMessage ELSE N'''' END
       ,ExtendedInfo.modify(N''insert sql:variable("@XmlInfo") into (/SpecificURLs/SpecificURL[@'+@AttrName+N' = "'+REPLACE(REPLACE(@AttrValue,N'''',N''''''),N'&',N'&amp;')+N'"])[1]'')
 WHERE ID = '+CONVERT(nvarchar(20),@TableId)+N';';
     ELSE -- ExtendedInfo is null or we didn't find what we needed:
     SELECT @SqlCmd = N'UPDATE dbo.TableRefreshHistory
   SET  EndDateUTC = SYSUTCDATETIME()
       ,ErrorNumber = -32
       ,ErrorMessage = N'''+REPLACE(@ErrorMessage,N'''',N'''''')+N'''+CASE WHEN ErrorMessage IS NOT NULL THEN CHAR(13)+CHAR(10)+ErrorMessage ELSE N'''' END
 WHERE ID = '+CONVERT(nvarchar(20),@TableId)+N';';
     BEGIN TRY
       EXECUTE (@SqlCmd);
       SELECT @PrintMessage = N'TableRefreshHistory for ID "'+CONVERT(nvarchar(20),@TableId)+N'" updated with stop information.';
       RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
     END TRY
     BEGIN CATCH
       SELECT @PrintMessage = N'Error Caught trying to update TableRefreshHistory for ID "'+CONVERT(nvarchar(20),@TableId)+N'"! Command issued:';
       RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
       RAISERROR('%s',10,1,@SqlCmd) WITH NOWAIT;
       THROW;
     END CATCH;

     -- Log the stop of the job/batch:
     BEGIN TRY
       UPDATE dbo.PowerShellRefreshHistory
          SET EndDateUTC = SYSUTCDATETIME()
             ,ErrorNumber = -32
             ,ErrorMessage = @ErrorMessage
        WHERE ID = @BatchID;
       SELECT @PrintMessage = N'PowerShellRefreshHistory for ID "'+CONVERT(nvarchar(20),@BatchID)+N'" updated with stop information.';
       RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
     END TRY
     BEGIN CATCH
       SELECT @PrintMessage = N'Error Caught trying to update PowerShellRefreshHistory for ID "'+CONVERT(nvarchar(20),@BatchID)+N'"!';
       RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
       SELECT @PrintMessage = N'UPDATE dbo.PowerShellRefreshHistory
   SET EndDateUTC = '''+FORMAT(GETUTCDATE(),'yyyy-MM-ddTHH:mm:ss.fff')+N'''
      ,ErrorNumber = -32
      ,ErrorMessage = N'''+REPLACE(@ErrorMessage,N'''',N'''''')+N'''
 WHERE ID = '+CONVERT(nvarchar(20),@BatchID)+N';';
       RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
       THROW;
     END CATCH;

     -- Completed
     SELECT @PrintMessage = N'Job "'+@JobName+N'" successfully stopped!';
     RAISERROR('%s',10,1,@PrintMessage) WITH NOWAIT;
     RETURN 0;

  END;
  ELSE
  BEGIN
    SELECT @PrintMessage = N'The job "'+@JobName+N'" is not running so we can''t proceed with a stop process.';
    RAISERROR('%s',16,1,@PrintMessage) WITH NOWAIT;
    GOTO FinishError;
  END;
  
  FinishError:
  RETURN 1;

END;
GO

IF OBJECT_ID(N'dbo.usp_StopIntuneSyncJob') IS NOT NULL
  PRINT 'Sproc "usp_StopIntuneSyncJob" Created (or still Exists).';
ELSE
  PRINT 'Sproc "usp_StopIntuneSyncJob" NOT CREATED...Check for errors!';
GO
