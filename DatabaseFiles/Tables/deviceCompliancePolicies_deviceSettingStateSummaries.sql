USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceCompliancePolicies_deviceSettingStateSummaries

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_deviceSettingStateSummaries') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceCompliancePolicies_deviceSettingStateSummaries;
    PRINT 'Table "deviceCompliancePolicies_deviceSettingStateSummaries" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceCompliancePolicies_deviceSettingStateSummaries ( ParentId nvarchar(36) NOT NULL
                                                                       ,id nvarchar(73) NOT NULL
                                                                       ,settingName nvarchar(512) NOT NULL
                                                                       ,instancePath nvarchar(32) NULL
                                                                       ,compliantDeviceCount int NOT NULL
                                                                       ,nonCompliantDeviceCount int NOT NULL
                                                                       ,errorDeviceCount int NOT NULL
                                                                       ,notApplicableDeviceCount int NOT NULL
                                                                       ,conflictDeviceCount int NOT NULL
                                                                       ,remediatedDeviceCount int NOT NULL
                                                                       ,unknownDeviceCount int NOT NULL
                                                                       ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_deviceSettingStateSummaries') IS NOT NULL
PRINT 'Table "deviceCompliancePolicies_deviceSettingStateSummaries" Created';
GO