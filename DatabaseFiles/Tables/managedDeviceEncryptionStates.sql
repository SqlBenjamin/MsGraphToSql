USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.managedDeviceEncryptionStates

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.managedDeviceEncryptionStates') IS NOT NULL
BEGIN
    DROP TABLE dbo.managedDeviceEncryptionStates;
    PRINT 'Table "managedDeviceEncryptionStates" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.managedDeviceEncryptionStates ( id nvarchar(36) NOT NULL
                                                ,userPrincipalName nvarchar(128) NULL
                                                ,deviceType nvarchar(17) NOT NULL
                                                ,osVersion nvarchar(128) NULL
                                                ,tpmSpecificationVersion nvarchar(10) NULL
                                                ,deviceName nvarchar(256) NULL
                                                ,encryptionReadinessState nvarchar(8) NOT NULL
                                                ,encryptionState nvarchar(12) NOT NULL
                                                ,encryptionPolicySettingState nvarchar(13) NOT NULL
                                                ,advancedBitLockerStates nvarchar(512) NULL --39
                                                ,policyDetails_JSON nvarchar(max) NULL
                                                ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.managedDeviceEncryptionStates') IS NOT NULL
PRINT 'Table "managedDeviceEncryptionStates" Created';
GO