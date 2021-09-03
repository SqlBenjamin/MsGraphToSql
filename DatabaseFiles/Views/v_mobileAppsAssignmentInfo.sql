USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_mobileAppsAssignmentInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_mobileAppsAssignmentInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_mobileAppsAssignmentInfo;
    PRINT 'View "v_mobileAppsAssignmentInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_mobileAppsAssignmentInfo AS
SELECT  app.id AS [ApplicationId]
       ,app.displayName AS [ApplicationDisplayName]
       ,ass.*
  FROM dbo.mobileApps app
       OUTER APPLY OPENJSON (app.assignments_JSON) WITH ( AssignmentId nvarchar(100) '$.id'
                                                         ,Intent nvarchar(25) '$.intent'
                                                         ,Settings nvarchar(max) '$.settings' AS JSON
                                                         ,TargetOdataType nvarchar(256) '$.target."@odata.type"'
                                                         ,TargetGroupId nvarchar(36) '$.target.groupId'
                                                         ) ass;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_mobileAppsAssignmentInfo') IS NOT NULL
PRINT 'View "v_mobileAppsAssignmentInfo" Created';
GO