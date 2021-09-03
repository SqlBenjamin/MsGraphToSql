USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceManagementScripts_RunScheduleInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceManagementScripts_RunScheduleInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceManagementScripts_RunScheduleInfo;
    PRINT 'View "v_deviceManagementScripts_RunScheduleInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceManagementScripts_RunScheduleInfo AS
--This is my best guess at the shredding of this one (since I don't have an example yet)...if my little understanding of the Graph metadata is correct:
SELECT  dms.id
       ,sch.*
  FROM dbo.v_deviceManagementScripts dms
       OUTER APPLY OPENJSON (dms.runSchedule_JSON) WITH ( ScheduleOdataType nvarchar(256) '$."@odata.type"'
                                                         ,interval int '$.interval'
                                                         ) sch;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceManagementScripts_RunScheduleInfo') IS NOT NULL
PRINT 'View "v_deviceManagementScripts_RunScheduleInfo" Created';
GO