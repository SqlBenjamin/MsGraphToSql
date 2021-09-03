USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceHealthScripts_getRemediationHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceHealthScripts_getRemediationHistory') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceHealthScripts_getRemediationHistory;
    PRINT 'View "v_deviceHealthScripts_getRemediationHistory" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceHealthScripts_getRemediationHistory AS
SELECT  rmh.ParentId
       ,rmh.lastModifiedDateTime
       ,jsn.theDate
       ,jsn.remediatedDeviceCount
       ,jsn.noIssueDeviceCount
  FROM dbo.deviceHealthScripts_getRemediationHistory rmh
       OUTER APPLY OPENJSON (rmh.historyData_JSON) WITH ( theDate date '$.date'
                                                         ,remediatedDeviceCount int '$.remediatedDeviceCount'
                                                         ,noIssueDeviceCount int '$.noIssueDeviceCount'
                                                         ) jsn;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceHealthScripts_getRemediationHistory') IS NOT NULL
PRINT 'View "v_deviceHealthScripts_getRemediationHistory" Created';
GO