USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileApps_deviceStatuses

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileApps_deviceStatuses') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileApps_deviceStatuses;
    PRINT 'Table "mobileApps_deviceStatuses" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileApps_deviceStatuses ( ParentId nvarchar(36) NOT NULL
                                            ,id nvarchar(73) NOT NULL --PRIMARY KEY CLUSTERED -- appid/deviceid combo
                                            ,deviceName nvarchar(256) NULL
                                            ,deviceId nvarchar(36) NULL
                                            ,lastSyncDateTime datetime2 NOT NULL
                                            --,mobileAppInstallStatusValue nvarchar(34) NOT NULL -- this should be removed from beta at some point and is the exact same as installState so removing it
                                            ,installState nvarchar(15) NOT NULL
                                            ,installStateDetail nvarchar(34) NOT NULL
                                            ,errorCode int NOT NULL
                                            ,osVersion nvarchar(50) NULL
                                            ,osDescription nvarchar(128) NULL
                                            ,userName nvarchar(256) NULL
                                            ,userPrincipalName nvarchar(128) NULL
                                            ,displayVersion nvarchar(50) NULL
                                            ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mobileApps_deviceStatuses') IS NOT NULL
PRINT 'Table "mobileApps_deviceStatuses" Created';
GO