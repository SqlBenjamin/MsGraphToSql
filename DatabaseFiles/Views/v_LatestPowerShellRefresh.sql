USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_LatestPowerShellRefresh

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_LatestPowerShellRefresh') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_LatestPowerShellRefresh;
    PRINT 'View "v_LatestPowerShellRefresh" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_LatestPowerShellRefresh AS
SELECT  ID AS [BatchID]
       ,StartDateUTC
       ,EndDateUTC
       ,dbo.udf_MsToHrMinSecMs(DATEDIFF(millisecond,StartDateUTC,EndDateUTC)) AS [Duration_HhMmSsMs]
       ,ErrorNumber
       ,ErrorMessage
       ,RunBy_User
       ,JobName
  FROM dbo.PowerShellRefreshHistory
 WHERE ID = (SELECT MAX(ID) FROM dbo.PowerShellRefreshHistory);
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_LatestPowerShellRefresh') IS NOT NULL
PRINT 'View "v_LatestPowerShellRefresh" Created';
GO