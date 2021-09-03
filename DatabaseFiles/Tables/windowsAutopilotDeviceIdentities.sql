USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.windowsAutopilotDeviceIdentities

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.windowsAutopilotDeviceIdentities') IS NOT NULL
BEGIN
    DROP TABLE dbo.windowsAutopilotDeviceIdentities;
    PRINT 'Table "windowsAutopilotDeviceIdentities" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.windowsAutopilotDeviceIdentities ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                   ,deploymentProfileAssignmentStatus nvarchar(128) NOT NULL
                                                   ,deploymentProfileAssignmentDetailedStatus nvarchar(128) NOT NULL
                                                   ,deploymentProfileAssignedDateTime datetime2 NOT NULL
                                                   ,enrollmentState nvarchar(12) NOT NULL
                                                   ,lastContactedDateTime datetime2 NOT NULL
                                                   ,orderIdentifier nvarchar(128) NULL
                                                   ,purchaseOrderIdentifier nvarchar(128) NULL
                                                   ,managedDeviceId nvarchar(36) NULL
                                                   ,azureActiveDirectoryDeviceId nvarchar(36) NULL
                                                   ,addressableUserName nvarchar(256) NULL
                                                   ,userPrincipalName nvarchar(128) NULL
                                                   ,displayName nvarchar(128) NULL
                                                   ,serialNumber nvarchar(128) NULL
                                                   ,productKey nvarchar(50) NULL
                                                   ,manufacturer nvarchar(128) NULL
                                                   ,model nvarchar(128) NULL
                                                   ,groupTag nvarchar(128) NULL
                                                   ,resourceName nvarchar(128) NULL
                                                   ,skuNumber nvarchar(64) NULL
                                                   ,systemFamily nvarchar(64) NULL
                                                   ,deploymentProfile_JSON nvarchar(max) NULL
                                                   ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.windowsAutopilotDeviceIdentities') IS NOT NULL
PRINT 'Table "windowsAutopilotDeviceIdentities" Created';
GO