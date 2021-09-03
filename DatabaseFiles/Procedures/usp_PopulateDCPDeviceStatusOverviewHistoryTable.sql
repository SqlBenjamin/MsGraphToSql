USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable;
    PRINT 'Sproc "usp_PopulateDCPDeviceStatusOverviewHistoryTable" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable
Purpose: This procedure inserts new records into DeviceCompliancePoliciesDeviceStatusOverviewHistory from deviceCompliancePolicies_deviceStatusOverview.

History:
Date          Version    Author                   Notes:
07/30/2021    0.0        Benjamin Reynolds        Created. Using this for a specific Id currently so not using a MERGE.
08/04/2021    0.0        Benjamin Reynolds        Removing specific IDs for external sharing - Merge may be better but hasn't been tested.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE  @RowsInserted int
          ,@RowsUpdated int
          ,@Message nvarchar(2047)
          ,@StartTimeUtc datetime
          ,@EndTimeUtc datetime
          ,@CaptureDateUtc date;

  SELECT @StartTimeUtc = GETUTCDATE();
  SET @Message = N'Script Starting: ' + CONVERT(nvarchar,@StartTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @CaptureDateUtc = GETUTCDATE();

  -- Update Existing Records if the job reruns on the same day:
  UPDATE his
     SET  his.PendingCount = dso.pendingCount
         ,his.NotApplicableCount = dso.notApplicableCount
         ,his.SuccessCount = dso.successCount
         ,his.ErrorCount = dso.errorCount
         ,his.FailedCount = dso.failedCount
         ,his.LastUpdateDateTime = dso.lastUpdateDateTime
         ,his.ConfigurationVersion = dso.configurationVersion
    FROM dbo.deviceCompliancePolicies_deviceStatusOverview dso
          LEFT OUTER JOIN dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory his
            ON dso.ParentId = his.Id
           AND his.CaptureDateUTC = @CaptureDateUtc
   --WHERE dso.ParentId = N''; -- can give a specific Id or list; MERGE should be considered in this scenario

  SELECT @RowsUpdated = @@ROWCOUNT;
  IF @RowsUpdated > 0
  BEGIN
    SET @Message = CONVERT(nvarchar(25),@RowsUpdated) + N' rows updated in the table.';
    RAISERROR('%s',10,1,@Message) WITH NOWAIT;
  END;

  -- Insert New Records:
  INSERT dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory
  SELECT  dso.ParentId AS [Id]
         ,@CaptureDateUtc
         ,dso.pendingCount
         ,dso.notApplicableCount
         ,dso.successCount
         ,dso.errorCount
         ,dso.failedCount
         ,dso.lastUpdateDateTime
         ,dso.configurationVersion
    FROM dbo.deviceCompliancePolicies_deviceStatusOverview dso
          LEFT OUTER JOIN dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory his
            ON dso.ParentId = his.Id
           AND his.CaptureDateUTC = @CaptureDateUtc
   WHERE /*dso.ParentId = N'' -- can give a specific Id or list; MERGE should be considered in this scenario
     AND */his.Id IS NULL;

  SELECT @RowsInserted = @@ROWCOUNT;
  IF @RowsInserted > 0
  BEGIN
    SET @Message = CONVERT(nvarchar(25),@RowsInserted) + N' rows inserted in the table.';
    RAISERROR('%s',10,1,@Message) WITH NOWAIT;
  END;

  SELECT @EndTimeUtc = GETUTCDATE();
  SET @Message = N'Script Completed: ' + CONVERT(nvarchar,@EndTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @Message = N'Duration: ' + dbo.udf_MsToHrMinSecMs(DATEDIFF_BIG(millisecond,@StartTimeUtc,@EndTimeUtc));
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
END;
GO

IF OBJECT_ID(N'dbo.usp_PopulateDCPDeviceStatusOverviewHistoryTable') IS NOT NULL
PRINT 'Sproc "usp_PopulateDCPDeviceStatusOverviewHistoryTable" Created.';
ELSE
PRINT 'Sproc "usp_PopulateDCPDeviceStatusOverviewHistoryTable" NOT CREATED...Check for errors!';
GO
