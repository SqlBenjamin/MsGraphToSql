USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_mobileApps_AssignmentsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_mobileApps_AssignmentsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_mobileApps_AssignmentsInfo;
    PRINT 'View "v_mobileApps_AssignmentsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_mobileApps_AssignmentsInfo AS
SELECT  maa.ParentOdataType AS [ApplicationOdataType]
       ,maa.ParentId AS [ApplicationId]
       ,maa.id AS [AssignmentId]
       ,maa.intent
       ,tgt.*
       ,maa.settings_JSON
  FROM dbo.mobileApps_assignments maa
       OUTER APPLY OPENJSON (maa.target_JSON) WITH ( TargetOdataType nvarchar(256) '$."@odata.type"'
                                                    ,TargetGroupId nvarchar(36) '$.groupId'
                                                    ) tgt;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_mobileApps_AssignmentsInfo') IS NOT NULL
PRINT 'View "v_mobileApps_AssignmentsInfo" Created';
GO