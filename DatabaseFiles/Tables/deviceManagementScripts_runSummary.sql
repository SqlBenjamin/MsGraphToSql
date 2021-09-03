USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceManagementScripts_runSummary

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceManagementScripts_runSummary') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceManagementScripts_runSummary;
    PRINT 'Table "deviceManagementScripts_runSummary" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceManagementScripts_runSummary ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                     ,successDeviceCount int NOT NULL
                                                     ,errorDeviceCount int NOT NULL
                                                     ,compliantDeviceCount int NULL
                                                     ,notCompliantDeviceCount int NULL
                                                     ,pendingDeviceCount int NULL
                                                     ,successUserCount int NOT NULL
                                                     ,errorUserCount int NOT NULL
                                                     ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceManagementScripts_runSummary') IS NOT NULL
PRINT 'Table "deviceManagementScripts_runSummary" Created';
GO