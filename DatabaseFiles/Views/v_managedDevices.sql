USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_managedDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_managedDevices') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_managedDevices;
    PRINT 'View "v_managedDevices" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_managedDevices AS
SELECT  id AS [IntuneDeviceId]
       ,userId
       ,deviceName
       ,managedDeviceOwnerType
       ,deviceActionResults_JSON
       ,enrolledDateTime
       ,lastSyncDateTime
       ,operatingSystem
       ,complianceState
       ,jailBroken
       ,managementAgent
       ,osVersion
       ,easActivated
       ,easDeviceId
       ,easActivationDateTime
       ,azureADRegistered
       ,deviceEnrollmentType
       ,activationLockBypassCode
       ,emailAddress
       ,azureADDeviceId
       ,deviceRegistrationState
       ,deviceCategoryDisplayName
       ,isSupervised
       ,exchangeLastSuccessfulSyncDateTime
       ,exchangeAccessState
       ,exchangeAccessStateReason
       ,remoteAssistanceSessionUrl
       ,remoteAssistanceSessionErrorDetails
       ,isEncrypted
       ,userPrincipalName
       ,model
       ,manufacturer
       ,imei
       ,complianceGracePeriodExpirationDateTime
       ,serialNumber
       ,phoneNumber
       ,androidSecurityPatchLevel
       ,userDisplayName
       ,configurationManagerClientEnabledFeatures_JSON
       ,wiFiMacAddress
       ,deviceHealthAttestationState_JSON
       ,subscriberCarrier
       ,meid
       ,totalStorageSpaceInBytes
       ,freeStorageSpaceInBytes
       ,managedDeviceName
       ,partnerReportedThreatState
       ,configurationManagerClientHealthState_JSON
       ,udid
       ,autopilotEnrolled
       ,chassisType
       ,deviceType
  FROM dbo.managedDevices;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_managedDevices') IS NOT NULL
PRINT 'View "v_managedDevices" Created';
GO