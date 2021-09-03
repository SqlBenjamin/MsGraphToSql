USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileApps_userStatuses

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileApps_userStatuses') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileApps_userStatuses;
    PRINT 'Table "mobileApps_userStatuses" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileApps_userStatuses ( ParentId nvarchar(36) NOT NULL
                                          ,id nvarchar(73) NOT NULL PRIMARY KEY CLUSTERED -- appid/userid combo
                                          ,userName nvarchar(256) NULL
                                          ,userPrincipalName nvarchar(128) NULL
                                          ,installedDeviceCount int NOT NULL
                                          ,failedDeviceCount int NOT NULL
                                          ,notInstalledDeviceCount int NOT NULL
                                          ) ON [PRIMARY];
GO
PRINT 'Table "mobileApps_userStatuses" Created';
GO