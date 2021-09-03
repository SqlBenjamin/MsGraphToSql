USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_StartJobAndWaitForCompletion') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_StartJobAndWaitForCompletion;
    PRINT 'Sproc "usp_StartJobAndWaitForCompletion" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_StartJobAndWaitForCompletion
Purpose: This procedure 

History:
Date          Version    Author                   Notes:
07/23/2021    0.0        Benjamin Reynolds        Created.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_StartJobAndWaitForCompletion
    @JobName nvarchar(512)
   ,@MaxWaitTimeSec int = 300
   ,@Status varchar(50) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE  @RetCode tinyint
          ,@CurStatus varchar(50) = 'Running'
          ,@ErrorMessage nvarchar(2047);
  
  SELECT @CurStatus = dbo.udf_GetSqlAgentJobStatus(@JobName);
  
  IF @CurStatus IS NULL
  BEGIN
    SELECT @ErrorMessage = N'The job "'+@JobName+N'" does not exist or some other issue occurred.';
    RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT;
    SELECT @Status = @CurStatus;
    GOTO EndSproc;
  END;
  ELSE IF @CurStatus != 'Running'
    EXECUTE @RetCode = msdb.dbo.sp_start_job @job_name = @JobName;
  ELSE
  BEGIN
    SELECT @ErrorMessage = N'The job "'+@JobName+N'" is currently running and therefore can''t be started.';
    RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT;
    SELECT @Status = @CurStatus;
    GOTO EndSproc;
  END;

  IF ISNULL(@RetCode,1) != 0
  BEGIN
    SELECT @ErrorMessage = N'sp_start_job was unable to start the job "'+@JobName+N'".';
    RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT;
    GOTO EndSproc;
  END;

  SET @CurStatus = 'Running';

  WHILE @CurStatus = 'Running' AND @MaxWaitTimeSec > 0 /*@CurStatus IN ('Running','Idle')*/
  BEGIN
    WAITFOR DELAY '00:00:01';
    SELECT @CurStatus = dbo.udf_GetSqlAgentJobStatus(@JobName);
    SELECT @MaxWaitTimeSec -= 1;
  END;

  --
  IF @CurStatus = 'Running' AND @MaxWaitTimeSec = 0
  BEGIN
    SELECT @ErrorMessage = N'Job is still running but max wait time exceeded.';
    RAISERROR('%s',10,1,@ErrorMessage) WITH NOWAIT;
  END;

  SELECT @Status = @CurStatus;
  RETURN 0;

  --
  EndSproc:
  RETURN 1;

END;
GO

IF OBJECT_ID(N'dbo.usp_StartJobAndWaitForCompletion') IS NOT NULL
  PRINT 'Sproc "usp_StartJobAndWaitForCompletion" Created.';
ELSE
  PRINT 'Sproc "usp_StartJobAndWaitForCompletion" NOT CREATED...Check for errors!';
GO
