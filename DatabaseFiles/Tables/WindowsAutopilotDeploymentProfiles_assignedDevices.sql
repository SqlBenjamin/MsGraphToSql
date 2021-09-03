USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.WindowsAutopilotDeploymentProfiles_assignedDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.WindowsAutopilotDeploymentProfiles_assignedDevices') IS NOT NULL
BEGIN
    DROP TABLE dbo.WindowsAutopilotDeploymentProfiles_assignedDevices;
    PRINT 'Table "WindowsAutopilotDeploymentProfiles_assignedDevices" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.WindowsAutopilotDeploymentProfiles_assignedDevices ( ParentId nvarchar(36) NOT NULL
                                                                     ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                                     ,deploymentProfileAssignmentStatus nvarchar(23) NOT NULL
                                                                     ,deploymentProfileAssignedDateTime datetime2 NOT NULL
                                                                     ,orderIdentifier nvarchar(50) NULL
                                                                     ,purchaseOrderIdentifier nvarchar(50) NULL
                                                                     ,serialNumber nvarchar(50) NULL
                                                                     ,productKey nvarchar(50) NULL
                                                                     ,manufacturer nvarchar(50) NULL
                                                                     ,model nvarchar(50) NULL
                                                                     ,enrollmentState nvarchar(12) NOT NULL
                                                                     ,lastContactedDateTime datetime2 NOT NULL
                                                                     ,addressableUserName nvarchar(256) NULL
                                                                     ,userPrincipalName nvarchar(128) NULL
                                                                     ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.WindowsAutopilotDeploymentProfiles_assignedDevices') IS NOT NULL
PRINT 'Table "WindowsAutopilotDeploymentProfiles_assignedDevices" Created';
GO