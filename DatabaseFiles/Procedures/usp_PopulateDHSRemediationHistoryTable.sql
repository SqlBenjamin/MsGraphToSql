USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_PopulateDHSRemediationHistoryTable') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_PopulateDHSRemediationHistoryTable;
    PRINT 'Sproc "usp_PopulateDHSRemediationHistoryTable" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_PopulateDHSRemediationHistoryTable
Purpose: This procedure inserts new records into DeviceHealthScriptsRemediationHistory from deviceHealthScripts_getRemediationHistory.

History:
Date          Version    Author                   Notes:
09/14/2020    0.0        Benjamin Reynolds        Created.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_PopulateDHSRemediationHistoryTable
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE  @RowsInserted int
          ,@Message nvarchar(2047)
          ,@StartTimeUtc datetime
          ,@EndTimeUtc datetime;

  SELECT @StartTimeUtc = GETUTCDATE();
  SET @Message = N'Script Starting: ' + CONVERT(nvarchar,@StartTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  INSERT dbo.DeviceHealthScriptsRemediationHistory
  SELECT  rmh.ParentId AS [Id]
         ,rmh.theDate
         ,rmh.remediatedDeviceCount
         ,rmh.noIssueDeviceCount
    FROM dbo.v_deviceHealthScripts_getRemediationHistory rmh
          LEFT OUTER JOIN dbo.DeviceHealthScriptsRemediationHistory drh
            ON rmh.ParentId = drh.Id
           AND rmh.theDate = drh.TheDate
   WHERE drh.Id IS NULL
     AND rmh.theDate IS NOT NULL
   ORDER BY rmh.ParentId,rmh.theDate;

  SELECT @RowsInserted = @@ROWCOUNT;
  SET @Message = CONVERT(nvarchar(25),@RowsInserted) + N' new rows inserted into table.';
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @EndTimeUtc = GETUTCDATE();
  SET @Message = N'Script Completed: ' + CONVERT(nvarchar,@EndTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @Message = N'Duration: ' + dbo.udf_MsToHrMinSecMs(DATEDIFF_BIG(millisecond,@StartTimeUtc,@EndTimeUtc));
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
END;
GO

IF OBJECT_ID(N'dbo.usp_PopulateDHSRemediationHistoryTable') IS NOT NULL
PRINT 'Sproc "usp_PopulateDHSRemediationHistoryTable" Created.';
ELSE
PRINT 'Sproc "usp_PopulateDHSRemediationHistoryTable" NOT CREATED...Check for errors!';
GO


/*********************************************************************************************
----  DeviceHealthScriptsRemediationHistory First time backfill
--INSERT dbo.DeviceHealthScriptsRemediationHistory
--SELECT  ParentId AS [id]
--       --,lastModifiedDateTime
--       ,theDate
--       ,remediatedDeviceCount
--       ,noIssueDeviceCount
--  FROM dbo.v_deviceHealthScripts_getRemediationHistory
-- ORDER BY ParentId,theDate;
*********************************************************************************************/