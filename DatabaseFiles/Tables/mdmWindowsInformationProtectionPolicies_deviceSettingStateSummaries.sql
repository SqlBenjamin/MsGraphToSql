USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries') IS NOT NULL
BEGIN
    DROP TABLE dbo.mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries;
    PRINT 'Table "mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries ( ParentId nvarchar(38) NOT NULL
                                                                                      ,id nvarchar(73) NOT NULL
                                                                                      ,settingName nvarchar(256) NULL
                                                                                      ,instancePath nvarchar(512) NULL
                                                                                      ,unknownDeviceCount int NOT NULL
                                                                                      ,notApplicableDeviceCount int NOT NULL
                                                                                      ,compliantDeviceCount int NOT NULL
                                                                                      ,remediatedDeviceCount int NOT NULL
                                                                                      ,nonCompliantDeviceCount int NOT NULL
                                                                                      ,errorDeviceCount int NOT NULL
                                                                                      ,conflictDeviceCount int NOT NULL
                                                                                      ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries') IS NOT NULL
PRINT 'Table "mdmWindowsInformationProtectionPolicies_deviceSettingStateSummaries" Created';
GO