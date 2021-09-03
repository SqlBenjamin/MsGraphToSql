USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileApps_installSummary

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileApps_installSummary') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileApps_installSummary;
    PRINT 'Table "mobileApps_installSummary" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileApps_installSummary ( ParentId nvarchar(36) NOT NULL -- This is the same thing and should be removed...but need to look at logic in the script first
                                            ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                            ,installedDeviceCount int NOT NULL
                                            ,failedDeviceCount int NOT NULL
                                            ,notApplicableDeviceCount int NOT NULL
                                            ,notInstalledDeviceCount int NOT NULL
                                            ,pendingInstallDeviceCount int NOT NULL
                                            ,installedUserCount int NOT NULL
                                            ,failedUserCount int NOT NULL
                                            ,notApplicableUserCount int NOT NULL
                                            ,notInstalledUserCount int NOT NULL
                                            ,pendingInstallUserCount int NOT NULL
                                            ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mobileApps_installSummary') IS NOT NULL
PRINT 'Table "mobileApps_installSummary" Created';
GO