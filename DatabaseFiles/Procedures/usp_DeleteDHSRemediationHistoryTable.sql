USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_DeleteDHSRemediationHistoryTable') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_DeleteDHSRemediationHistoryTable;
    PRINT 'Sproc "usp_DeleteDHSRemediationHistoryTable" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_DeleteDHSRemediationHistoryTable
Purpose: This procedure deletes the records older than the provided "DaysToKeep" from DeviceHealthScriptsRemediationHistory.

History:
Date          Version    Author                   Notes:
09/14/2020    0.0        Benjamin Reynolds        Created.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_DeleteDHSRemediationHistoryTable
    @DaysToKeep int
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE  @RowsDeleted int
          ,@Message nvarchar(2047)
          ,@StartTimeUtc datetime
          ,@EndTimeUtc datetime;

  SELECT @StartTimeUtc = GETUTCDATE();
  SET @Message = N'Script Starting: ' + CONVERT(nvarchar,@StartTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
  
  DELETE dbo.DeviceHealthScriptsRemediationHistory
   WHERE TheDate < DATEADD(day,-@DaysToKeep,CONVERT(date,GETUTCDATE()));

  SELECT @RowsDeleted = @@ROWCOUNT;
  SET @Message = CONVERT(nvarchar(25),@RowsDeleted) + N' rows deleted.';
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @EndTimeUtc = GETUTCDATE();
  SET @Message = N'Script Completed: ' + CONVERT(nvarchar,@EndTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @Message = N'Duration: ' + dbo.udf_MsToHrMinSecMs(DATEDIFF_BIG(millisecond,@StartTimeUtc,@EndTimeUtc));
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
END;
GO

IF OBJECT_ID(N'dbo.usp_DeleteDHSRemediationHistoryTable') IS NOT NULL
PRINT 'Sproc "usp_DeleteDHSRemediationHistoryTable" Created.';
ELSE
PRINT 'Sproc "usp_DeleteDHSRemediationHistoryTable" NOT CREATED...Check for errors!';
GO