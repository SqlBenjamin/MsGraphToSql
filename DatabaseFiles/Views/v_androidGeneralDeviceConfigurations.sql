USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_androidGeneralDeviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_androidGeneralDeviceConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_androidGeneralDeviceConfigurations;
    PRINT 'View "v_androidGeneralDeviceConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_androidGeneralDeviceConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( appsBlockClipboardSharing bit '$.appsBlockClipboardSharing'
                                                     ,appsBlockCopyPaste bit '$.appsBlockCopyPaste'
                                                     ,appsBlockYouTube bit '$.appsBlockYouTube'
                                                     ,bluetoothBlocked bit '$.bluetoothBlocked'
                                                     ,cameraBlocked bit '$.cameraBlocked'
                                                     ,cellularBlockDataRoaming bit '$.cellularBlockDataRoaming'
                                                     ,cellularBlockMessaging bit '$.cellularBlockMessaging'
                                                     ,cellularBlockVoiceRoaming bit '$.cellularBlockVoiceRoaming'
                                                     ,cellularBlockWiFiTethering bit '$.cellularBlockWiFiTethering'
                                                     ,compliantAppsList_JSON nvarchar(max) '$.compliantAppsList' AS JSON
                                                     ,compliantAppListType nvarchar(max) '$.compliantAppListType'
                                                     ,diagnosticDataBlockSubmission bit '$.diagnosticDataBlockSubmission'
                                                     ,locationServicesBlocked bit '$.locationServicesBlocked'
                                                     ,googleAccountBlockAutoSync bit '$.googleAccountBlockAutoSync'
                                                     ,googlePlayStoreBlocked bit '$.googlePlayStoreBlocked'
                                                     ,kioskModeBlockSleepButton bit '$.kioskModeBlockSleepButton'
                                                     ,kioskModeBlockVolumeButtons bit '$.kioskModeBlockVolumeButtons'
                                                     ,kioskModeApps_JSON nvarchar(max) '$.kioskModeApps' AS JSON
                                                     ,nfcBlocked bit '$.nfcBlocked'
                                                     ,passwordBlockFingerprintUnlock bit '$.passwordBlockFingerprintUnlock'
                                                     ,passwordBlockTrustAgents bit '$.passwordBlockTrustAgents'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordSignInFailureCountBeforeFactoryReset int '$.passwordSignInFailureCountBeforeFactoryReset'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,passwordRequired bit '$.passwordRequired'
                                                     ,powerOffBlocked bit '$.powerOffBlocked'
                                                     ,factoryResetBlocked bit '$.factoryResetBlocked'
                                                     ,screenCaptureBlocked bit '$.screenCaptureBlocked'
                                                     ,deviceSharingAllowed bit '$.deviceSharingAllowed'
                                                     ,storageBlockGoogleBackup bit '$.storageBlockGoogleBackup'
                                                     ,storageBlockRemovableStorage bit '$.storageBlockRemovableStorage'
                                                     ,storageRequireDeviceEncryption bit '$.storageRequireDeviceEncryption'
                                                     ,storageRequireRemovableStorageEncryption bit '$.storageRequireRemovableStorageEncryption'
                                                     ,voiceAssistantBlocked bit '$.voiceAssistantBlocked'
                                                     ,voiceDialingBlocked bit '$.voiceDialingBlocked'
                                                     ,webBrowserBlockPopups bit '$.webBrowserBlockPopups'
                                                     ,webBrowserBlockAutofill bit '$.webBrowserBlockAutofill'
                                                     ,webBrowserBlockJavaScript bit '$.webBrowserBlockJavaScript'
                                                     ,webBrowserBlocked bit '$.webBrowserBlocked'
                                                     ,webBrowserCookieSettings nvarchar(max) '$.webBrowserCookieSettings'
                                                     ,wiFiBlocked bit '$.wiFiBlocked'
                                                     ,appsInstallAllowList_JSON nvarchar(max) '$.appsInstallAllowList' AS JSON
                                                     ,appsLaunchBlockList_JSON nvarchar(max) '$.appsLaunchBlockList' AS JSON
                                                     ,appsHideList_JSON nvarchar(max) '$.appsHideList' AS JSON
                                                     ,securityRequireVerifyApps bit '$.securityRequireVerifyApps'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.androidGeneralDeviceConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_androidGeneralDeviceConfigurations') IS NOT NULL
PRINT 'View "v_androidGeneralDeviceConfigurations" Created';
GO