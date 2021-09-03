USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileAppConfigurations_deviceStatusSummary

History:
Date          Version    Author                   Notes:
03/11/2021    0.0        Dhanraj Rajendraodayar   Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileAppConfigurations_deviceStatusSummary') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileAppConfigurations_deviceStatusSummary;
    PRINT 'Table "mobileAppConfigurations_deviceStatusSummary" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileAppConfigurations_deviceStatusSummary ( id nvarchar(73) NULL
                                                              ,configurationVersion int NOT NULL
                                                              ,conflictCount int NOT NULL
                                                              ,errorCount int NOT NULL
                                                              ,failedCount int NOT NULL
                                                              ,lastUpdateDateTime datetime2(7) NOT NULL
                                                              ,notApplicableCount int NOT NULL
                                                              ,notApplicablePlatformCount int NOT NULL
                                                              ,pendingCount int NOT NULL
                                                              ,successCount int NOT NULL
                                                              );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mobileAppConfigurations_deviceStatusSummary') IS NOT NULL
PRINT 'Table "mobileAppConfigurations_deviceStatusSummary" Created';
GO