USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceConfigurations_userStatusOverview

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceConfigurations_userStatusOverview') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceConfigurations_userStatusOverview;
    PRINT 'Table "deviceConfigurations_userStatusOverview" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceConfigurations_userStatusOverview ( ParentId nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                          ,id nvarchar(73) NOT NULL
                                                          ,pendingCount int NOT NULL
                                                          ,notApplicableCount int NOT NULL
                                                          ,successCount int NOT NULL
                                                          ,errorCount int NOT NULL
                                                          ,failedCount int NOT NULL
                                                          ,conflictCount int NOT NULL
                                                          ,lastUpdateDateTime datetime2 NOT NULL
                                                          ,configurationVersion int NOT NULL
                                                          );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceConfigurations_userStatusOverview') IS NOT NULL
PRINT 'Table "deviceConfigurations_userStatusOverview" Created';
GO