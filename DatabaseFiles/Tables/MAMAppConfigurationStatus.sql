USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.MAMAppConfigurationStatus

History:
Date          Version    Author                   Notes:
05/18/2021    0.0        Benjamin Reynolds        Created. (similar to MAMAppProtectionStatus)
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.MAMAppConfigurationStatus') IS NOT NULL
BEGIN
    DROP TABLE dbo.MAMAppConfigurationStatus;
    PRINT 'Table "MAMAppConfigurationStatus" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.MAMAppConfigurationStatus ( [User] nvarchar(256) NULL
                                            ,Email nvarchar(256) NULL
                                            ,App nvarchar(256) NULL
                                            ,AppVersion nvarchar(50) NULL
                                            ,SdkVersion nvarchar(10) NULL
                                            ,AppInstanceId nvarchar(36) NULL
                                            ,DeviceName nvarchar(128) NULL
                                            ,DeviceHealth nvarchar(64) NULL
                                            ,DeviceType nvarchar(64) NULL
                                            ,DeviceManufacturer nvarchar(64) NULL
                                            ,DeviceModel nvarchar(128) NULL
                                            ,AndroidPatchVersion nvarchar(15) NULL -- bc of values like this: "0000-00-00", it can't be a date or datetime2 column. ugh
                                            ,AADDeviceID nvarchar(36) NULL
                                            ,MDMDeviceID nvarchar(36) NULL
                                            ,[Platform] nvarchar(64) NULL
                                            ,PlatformVersion nvarchar(15) NULL
                                            ,[Policy] nvarchar(128) NULL
                                            ,LastSync datetime2 NULL
                                            ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.MAMAppConfigurationStatus') IS NOT NULL
PRINT 'Table "MAMAppConfigurationStatus" Created';
GO