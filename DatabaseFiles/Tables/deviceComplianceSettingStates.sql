USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceComplianceSettingStates

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceComplianceSettingStates') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceComplianceSettingStates;
    PRINT 'Table "deviceComplianceSettingStates" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceComplianceSettingStates ( id nvarchar(128) NOT NULL
                                                ,complianceGracePeriodExpirationDateTime datetime2 NOT NULL
                                                ,deviceId nvarchar(36) NULL
                                                ,deviceModel nvarchar(64) NULL
                                                ,deviceName nvarchar(64) NULL
                                                ,platformType nvarchar(17) NOT NULL
                                                ,setting nvarchar(128) NULL
                                                ,settingName nvarchar(128) NULL
                                                ,state nvarchar(13) NOT NULL
                                                ,userEmail nvarchar(128) NULL
                                                ,userId nvarchar(36) NULL
                                                ,userName nvarchar(128) NULL
                                                ,userPrincipalName nvarchar(64) NULL
                                                ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceComplianceSettingStates') IS NOT NULL
PRINT 'Table "deviceComplianceSettingStates" Created';
GO