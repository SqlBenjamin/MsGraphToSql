USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WindowsAutopilotDeploymentProfiles_assignmentsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentProfiles_assignmentsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WindowsAutopilotDeploymentProfiles_assignmentsInfo;
    PRINT 'View "v_WindowsAutopilotDeploymentProfiles_assignmentsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WindowsAutopilotDeploymentProfiles_assignmentsInfo AS
SELECT  wad.ParentOdataType AS [AutopilotDeploymentOdataType]
       ,wad.ParentId AS [AutopilotDeploymentId]
       ,wad.id AS [AssignmentId]
       --,wad.target_JSON
       ,tgt.*
  FROM dbo.WindowsAutopilotDeploymentProfiles_assignments wad
       OUTER APPLY OPENJSON (wad.target_JSON) WITH ( TargetOdataType nvarchar(256) '$."@odata.type"'
                                                    ,TargetGroupId nvarchar(36) '$.groupId'
                                                    ) tgt;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentProfiles_assignmentsInfo') IS NOT NULL
PRINT 'View "v_WindowsAutopilotDeploymentProfiles_assignmentsInfo" Created';
GO