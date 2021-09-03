USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WindowsAutopilotDeploymentProfiles_assignedDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentProfiles_assignedDevices') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WindowsAutopilotDeploymentProfiles_assignedDevices;
    PRINT 'View "v_WindowsAutopilotDeploymentProfiles_assignedDevices" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WindowsAutopilotDeploymentProfiles_assignedDevices AS
SELECT  ParentId AS [WindowsAutopilotDeploymentProfileId]
       ,id
       ,deploymentProfileAssignmentStatus
       ,deploymentProfileAssignedDateTime
       ,orderIdentifier
       ,purchaseOrderIdentifier
       ,serialNumber
       ,productKey
       ,manufacturer
       ,model
       ,enrollmentState
       ,lastContactedDateTime
       ,addressableUserName
       ,userPrincipalName
  FROM dbo.WindowsAutopilotDeploymentProfiles_assignedDevices;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDeploymentProfiles_assignedDevices') IS NOT NULL
PRINT 'View "v_WindowsAutopilotDeploymentProfiles_assignedDevices" Created';
GO