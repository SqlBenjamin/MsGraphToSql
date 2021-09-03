USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo;
    PRINT 'View "v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo AS
SELECT  ato.id
       ,ato.displayName
       --,ato.outOfBoxExperienceSettings_JSON
       ,oob.*
       --,ato.assignments_JSON
       ,ass.*
       --,ato.enrollmentStatusScreenSettings_JSON
       --,ess.*
  FROM dbo.WindowsAutopilotDeploymentProfiles ato
       OUTER APPLY OPENJSON (ato.outOfBoxExperienceSettings_JSON) WITH ( hidePrivacySettings nvarchar(100) '$.hidePrivacySettings'
                                                                        ,hideEULA nvarchar(256) '$.hideEULA'
                                                                        ,userType nvarchar(36) '$.userType'
                                                                        ,deviceUsageType nvarchar(36) '$.deviceUsageType'
                                                                        ,skipKeyboardSelectionPage nvarchar(36) '$.skipKeyboardSelectionPage'
                                                                        ,hideEscapeLink nvarchar(36) '$.hideEscapeLink'
                                                                        ) oob
       OUTER APPLY OPENJSON (ato.assignments_JSON) WITH ( AssignmentId nvarchar(100) '$.id'
                                                         ,TargetOdataType nvarchar(256) '$.target."@odata.type"'
                                                         ,TargetGroupId nvarchar(36) '$.target.groupId'
                                                         ) ass;
       --OUTER APPLY OPENJSON (ato.enrollmentStatusScreenSettings_JSON) WITH ( /*Currently have no data to see the schema*/) ess
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo') IS NOT NULL
PRINT 'View "v_WindowsAutopilotDeploymentSettingsAndAssignmentsInfo" Created';
GO