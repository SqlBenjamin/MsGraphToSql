USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.managedDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.managedDevices') IS NOT NULL
BEGIN
    DROP TABLE dbo.managedDevices;
    PRINT 'Table "managedDevices" Dropped.';
END;
GO

-- Create Table: (if you add a column we need to add it to the view as well)
CREATE TABLE dbo.managedDevices ( id nvarchar(36) NOT NULL
                                 ,userId nvarchar(36) NULL
                                 ,deviceName nvarchar(256) NULL
                                 ,managedDeviceOwnerType nvarchar(15) NULL
                                 ,deviceActionResults_JSON nvarchar(max) NULL
                                 ,enrolledDateTime datetime2 NOT NULL
                                 ,lastSyncDateTime datetime2 NOT NULL
                                 ,operatingSystem nvarchar(64) NULL
                                 ,complianceState nvarchar(13) NOT NULL
                                 ,jailBroken nvarchar(10) NULL
                                 ,managementAgent nvarchar(35) NOT NULL
                                 ,osVersion nvarchar(128) NULL
                                 ,easActivated bit NOT NULL
                                 ,easDeviceId nvarchar(256) NULL
                                 ,easActivationDateTime datetime2 NOT NULL
                                 ,azureADRegistered bit NULL
                                 ,deviceEnrollmentType nvarchar(37) NOT NULL
                                 ,activationLockBypassCode nvarchar(128) NULL
                                 ,emailAddress nvarchar(320) NULL
                                 ,azureADDeviceId nvarchar(36) NULL
                                 ,deviceRegistrationState nvarchar(30) NOT NULL
                                 ,deviceCategoryDisplayName nvarchar(25) NULL
                                 ,isSupervised bit NOT NULL
                                 ,exchangeLastSuccessfulSyncDateTime datetime2 NOT NULL
                                 ,exchangeAccessState nvarchar(11) NOT NULL
                                 ,exchangeAccessStateReason nvarchar(29) NOT NULL
                                 ,remoteAssistanceSessionUrl nvarchar(256) NULL
                                 ,remoteAssistanceSessionErrorDetails nvarchar(64) NULL
                                 ,isEncrypted bit NOT NULL
                                 ,userPrincipalName nvarchar(128) NULL
                                 ,model nvarchar(256) NULL
                                 ,manufacturer nvarchar(256) NULL
                                 ,imei nvarchar(64) NULL
                                 ,complianceGracePeriodExpirationDateTime datetime2 NOT NULL
                                 ,serialNumber nvarchar(128) NULL
                                 ,phoneNumber nvarchar(64) NULL
                                 ,androidSecurityPatchLevel nvarchar(64) NULL
                                 ,userDisplayName nvarchar(256) NULL
                                 ,configurationManagerClientEnabledFeatures_JSON nvarchar(max) NULL
                                 ,wiFiMacAddress nvarchar(64) NULL
                                 ,deviceHealthAttestationState_JSON nvarchar(max) NULL
                                 ,subscriberCarrier nvarchar(50) NULL
                                 ,meid nvarchar(256) NULL
                                 ,totalStorageSpaceInBytes bigint NOT NULL
                                 ,freeStorageSpaceInBytes bigint NOT NULL
                                 ,managedDeviceName nvarchar(256) NULL
                                 ,partnerReportedThreatState nvarchar(14) NOT NULL
                                 ---- only in beta:
                                 ,configurationManagerClientHealthState_JSON nvarchar(max) NULL
                                 ,udid nvarchar(36) NULL
                                 ,autopilotEnrolled bit NOT NULL
								 ,chassisType nvarchar(20) NOT NULL
                                 ,deviceType nvarchar(25) NOT NULL
                                 ,managementState nvarchar(14) NOT NULL
                                 ,joinType nvarchar(20) NOT NULL
                                 ,skuFamily nvarchar(128) NULL
                                 ,skuNumber int NOT NULL
                                 ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.managedDevices') IS NOT NULL
PRINT 'Table "managedDevices" Created';
GO