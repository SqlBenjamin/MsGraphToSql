USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WindowsAutopilotDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDevices') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WindowsAutopilotDevices;
    PRINT 'View "v_WindowsAutopilotDevices" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WindowsAutopilotDevices AS
SELECT  id AS [ZtId]
       ,deploymentProfileAssignmentStatus
       ,deploymentProfileAssignedDateTime
       ,orderIdentifier
       ,purchaseOrderIdentifier
       ,serialNumber AS [Autopilot_SerialNumber]
       ,productKey
       ,manufacturer AS [Autopilot_Manufacturer]
       ,model AS [Autopilot_Model]
       ,enrollmentState
       ,lastContactedDateTime
       ,addressableUserName
       ,userPrincipalName AS [Autopilot_UserPrincipalName]
  FROM dbo.WindowsAutopilotDeviceIdentities;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WindowsAutopilotDevices') IS NOT NULL
PRINT 'View "v_WindowsAutopilotDevices" Created';
GO