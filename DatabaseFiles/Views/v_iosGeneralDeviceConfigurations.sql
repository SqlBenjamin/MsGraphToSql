USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_iosGeneralDeviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_iosGeneralDeviceConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_iosGeneralDeviceConfigurations;
    PRINT 'View "v_iosGeneralDeviceConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_iosGeneralDeviceConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( accountBlockModification bit '$.accountBlockModification'
                                                     ,activationLockAllowWhenSupervised bit '$.activationLockAllowWhenSupervised'
                                                     ,airDropBlocked bit '$.airDropBlocked'
                                                     ,airDropForceUnmanagedDropTarget bit '$.airDropForceUnmanagedDropTarget'
                                                     ,airPlayForcePairingPasswordForOutgoingRequests bit '$.airPlayForcePairingPasswordForOutgoingRequests'
                                                     ,appleWatchBlockPairing bit '$.appleWatchBlockPairing'
                                                     ,appleWatchForceWristDetection bit '$.appleWatchForceWristDetection'
                                                     ,appleNewsBlocked bit '$.appleNewsBlocked'
                                                     ,appsSingleAppModeList_JSON nvarchar(max) '$.appsSingleAppModeList' AS JSON
                                                     ,appsVisibilityList_JSON nvarchar(max) '$.appsVisibilityList' AS JSON
                                                     ,appsVisibilityListType nvarchar(max) '$.appsVisibilityListType'
                                                     ,appStoreBlockAutomaticDownloads bit '$.appStoreBlockAutomaticDownloads'
                                                     ,appStoreBlocked bit '$.appStoreBlocked'
                                                     ,appStoreBlockInAppPurchases bit '$.appStoreBlockInAppPurchases'
                                                     ,appStoreBlockUIAppInstallation bit '$.appStoreBlockUIAppInstallation'
                                                     ,appStoreRequirePassword bit '$.appStoreRequirePassword'
                                                     ,bluetoothBlockModification bit '$.bluetoothBlockModification'
                                                     ,cameraBlocked bit '$.cameraBlocked'
                                                     ,cellularBlockDataRoaming bit '$.cellularBlockDataRoaming'
                                                     ,cellularBlockGlobalBackgroundFetchWhileRoaming bit '$.cellularBlockGlobalBackgroundFetchWhileRoaming'
                                                     ,cellularBlockPerAppDataModification bit '$.cellularBlockPerAppDataModification'
                                                     ,cellularBlockPersonalHotspot bit '$.cellularBlockPersonalHotspot'
                                                     ,cellularBlockVoiceRoaming bit '$.cellularBlockVoiceRoaming'
                                                     ,certificatesBlockUntrustedTlsCertificates bit '$.certificatesBlockUntrustedTlsCertificates'
                                                     ,classroomAppBlockRemoteScreenObservation bit '$.classroomAppBlockRemoteScreenObservation'
                                                     ,classroomAppForceUnpromptedScreenObservation bit '$.classroomAppForceUnpromptedScreenObservation'
                                                     ,compliantAppsList_JSON nvarchar(max) '$.compliantAppsList' AS JSON
                                                     ,compliantAppListType nvarchar(max) '$.compliantAppListType'
                                                     ,configurationProfileBlockChanges bit '$.configurationProfileBlockChanges'
                                                     ,definitionLookupBlocked bit '$.definitionLookupBlocked'
                                                     ,deviceBlockEnableRestrictions bit '$.deviceBlockEnableRestrictions'
                                                     ,deviceBlockEraseContentAndSettings bit '$.deviceBlockEraseContentAndSettings'
                                                     ,deviceBlockNameModification bit '$.deviceBlockNameModification'
                                                     ,diagnosticDataBlockSubmission bit '$.diagnosticDataBlockSubmission'
                                                     ,diagnosticDataBlockSubmissionModification bit '$.diagnosticDataBlockSubmissionModification'
                                                     ,documentsBlockManagedDocumentsInUnmanagedApps bit '$.documentsBlockManagedDocumentsInUnmanagedApps'
                                                     ,documentsBlockUnmanagedDocumentsInManagedApps bit '$.documentsBlockUnmanagedDocumentsInManagedApps'
                                                     ,emailInDomainSuffixes_JSON nvarchar(max) '$.emailInDomainSuffixes' AS JSON
                                                     ,enterpriseAppBlockTrust bit '$.enterpriseAppBlockTrust'
                                                     ,enterpriseAppBlockTrustModification bit '$.enterpriseAppBlockTrustModification'
                                                     ,faceTimeBlocked bit '$.faceTimeBlocked'
                                                     ,findMyFriendsBlocked bit '$.findMyFriendsBlocked'
                                                     ,gamingBlockGameCenterFriends bit '$.gamingBlockGameCenterFriends'
                                                     ,gamingBlockMultiplayer bit '$.gamingBlockMultiplayer'
                                                     ,gameCenterBlocked bit '$.gameCenterBlocked'
                                                     ,hostPairingBlocked bit '$.hostPairingBlocked'
                                                     ,iBooksStoreBlocked bit '$.iBooksStoreBlocked'
                                                     ,iBooksStoreBlockErotica bit '$.iBooksStoreBlockErotica'
                                                     ,iCloudBlockActivityContinuation bit '$.iCloudBlockActivityContinuation'
                                                     ,iCloudBlockBackup bit '$.iCloudBlockBackup'
                                                     ,iCloudBlockDocumentSync bit '$.iCloudBlockDocumentSync'
                                                     ,iCloudBlockManagedAppsSync bit '$.iCloudBlockManagedAppsSync'
                                                     ,iCloudBlockPhotoLibrary bit '$.iCloudBlockPhotoLibrary'
                                                     ,iCloudBlockPhotoStreamSync bit '$.iCloudBlockPhotoStreamSync'
                                                     ,iCloudBlockSharedPhotoStream bit '$.iCloudBlockSharedPhotoStream'
                                                     ,iCloudRequireEncryptedBackup bit '$.iCloudRequireEncryptedBackup'
                                                     ,iTunesBlockExplicitContent bit '$.iTunesBlockExplicitContent'
                                                     ,iTunesBlockMusicService bit '$.iTunesBlockMusicService'
                                                     ,iTunesBlockRadio bit '$.iTunesBlockRadio'
                                                     ,keyboardBlockAutoCorrect bit '$.keyboardBlockAutoCorrect'
                                                     ,keyboardBlockDictation bit '$.keyboardBlockDictation'
                                                     ,keyboardBlockPredictive bit '$.keyboardBlockPredictive'
                                                     ,keyboardBlockShortcuts bit '$.keyboardBlockShortcuts'
                                                     ,keyboardBlockSpellCheck bit '$.keyboardBlockSpellCheck'
                                                     ,kioskModeAllowAssistiveSpeak bit '$.kioskModeAllowAssistiveSpeak'
                                                     ,kioskModeAllowAssistiveTouchSettings bit '$.kioskModeAllowAssistiveTouchSettings'
                                                     ,kioskModeAllowAutoLock bit '$.kioskModeAllowAutoLock'
                                                     ,kioskModeAllowColorInversionSettings bit '$.kioskModeAllowColorInversionSettings'
                                                     ,kioskModeAllowRingerSwitch bit '$.kioskModeAllowRingerSwitch'
                                                     ,kioskModeAllowScreenRotation bit '$.kioskModeAllowScreenRotation'
                                                     ,kioskModeAllowSleepButton bit '$.kioskModeAllowSleepButton'
                                                     ,kioskModeAllowTouchscreen bit '$.kioskModeAllowTouchscreen'
                                                     ,kioskModeAllowVoiceOverSettings bit '$.kioskModeAllowVoiceOverSettings'
                                                     ,kioskModeAllowVolumeButtons bit '$.kioskModeAllowVolumeButtons'
                                                     ,kioskModeAllowZoomSettings bit '$.kioskModeAllowZoomSettings'
                                                     ,kioskModeAppStoreUrl nvarchar(max) '$.kioskModeAppStoreUrl'
                                                     ,kioskModeBuiltInAppId nvarchar(max) '$.kioskModeBuiltInAppId'
                                                     ,kioskModeRequireAssistiveTouch bit '$.kioskModeRequireAssistiveTouch'
                                                     ,kioskModeRequireColorInversion bit '$.kioskModeRequireColorInversion'
                                                     ,kioskModeRequireMonoAudio bit '$.kioskModeRequireMonoAudio'
                                                     ,kioskModeRequireVoiceOver bit '$.kioskModeRequireVoiceOver'
                                                     ,kioskModeRequireZoom bit '$.kioskModeRequireZoom'
                                                     ,kioskModeManagedAppId nvarchar(max) '$.kioskModeManagedAppId'
                                                     ,lockScreenBlockControlCenter bit '$.lockScreenBlockControlCenter'
                                                     ,lockScreenBlockNotificationView bit '$.lockScreenBlockNotificationView'
                                                     ,lockScreenBlockPassbook bit '$.lockScreenBlockPassbook'
                                                     ,lockScreenBlockTodayView bit '$.lockScreenBlockTodayView'
                                                     ,mediaContentRatingAustralia_JSON nvarchar(max) '$.mediaContentRatingAustralia' AS JSON
                                                     ,mediaContentRatingCanada_JSON nvarchar(max) '$.mediaContentRatingCanada' AS JSON
                                                     ,mediaContentRatingFrance_JSON nvarchar(max) '$.mediaContentRatingFrance' AS JSON
                                                     ,mediaContentRatingGermany_JSON nvarchar(max) '$.mediaContentRatingGermany' AS JSON
                                                     ,mediaContentRatingIreland_JSON nvarchar(max) '$.mediaContentRatingIreland' AS JSON
                                                     ,mediaContentRatingJapan_JSON nvarchar(max) '$.mediaContentRatingJapan' AS JSON
                                                     ,mediaContentRatingNewZealand_JSON nvarchar(max) '$.mediaContentRatingNewZealand' AS JSON
                                                     ,mediaContentRatingUnitedKingdom_JSON nvarchar(max) '$.mediaContentRatingUnitedKingdom' AS JSON
                                                     ,mediaContentRatingUnitedStates_JSON nvarchar(max) '$.mediaContentRatingUnitedStates' AS JSON
                                                     ,networkUsageRules_JSON nvarchar(max) '$.networkUsageRules' AS JSON
                                                     ,mediaContentRatingApps nvarchar(max) '$.mediaContentRatingApps'
                                                     ,messagesBlocked bit '$.messagesBlocked'
                                                     ,notificationsBlockSettingsModification bit '$.notificationsBlockSettingsModification'
                                                     ,passcodeBlockFingerprintUnlock bit '$.passcodeBlockFingerprintUnlock'
                                                     ,passcodeBlockFingerprintModification bit '$.passcodeBlockFingerprintModification'
                                                     ,passcodeBlockModification bit '$.passcodeBlockModification'
                                                     ,passcodeBlockSimple bit '$.passcodeBlockSimple'
                                                     ,passcodeExpirationDays int '$.passcodeExpirationDays'
                                                     ,passcodeMinimumLength int '$.passcodeMinimumLength'
                                                     ,passcodeMinutesOfInactivityBeforeLock int '$.passcodeMinutesOfInactivityBeforeLock'
                                                     ,passcodeMinutesOfInactivityBeforeScreenTimeout int '$.passcodeMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passcodeMinimumCharacterSetCount int '$.passcodeMinimumCharacterSetCount'
                                                     ,passcodePreviousPasscodeBlockCount int '$.passcodePreviousPasscodeBlockCount'
                                                     ,passcodeSignInFailureCountBeforeWipe int '$.passcodeSignInFailureCountBeforeWipe'
                                                     ,passcodeRequiredType nvarchar(max) '$.passcodeRequiredType'
                                                     ,passcodeRequired bit '$.passcodeRequired'
                                                     ,podcastsBlocked bit '$.podcastsBlocked'
                                                     ,safariBlockAutofill bit '$.safariBlockAutofill'
                                                     ,safariBlockJavaScript bit '$.safariBlockJavaScript'
                                                     ,safariBlockPopups bit '$.safariBlockPopups'
                                                     ,safariBlocked bit '$.safariBlocked'
                                                     ,safariCookieSettings nvarchar(max) '$.safariCookieSettings'
                                                     ,safariManagedDomains_JSON nvarchar(max) '$.safariManagedDomains' AS JSON
                                                     ,safariPasswordAutoFillDomains_JSON nvarchar(max) '$.safariPasswordAutoFillDomains' AS JSON
                                                     ,safariRequireFraudWarning bit '$.safariRequireFraudWarning'
                                                     ,screenCaptureBlocked bit '$.screenCaptureBlocked'
                                                     ,siriBlocked bit '$.siriBlocked'
                                                     ,siriBlockedWhenLocked bit '$.siriBlockedWhenLocked'
                                                     ,siriBlockUserGeneratedContent bit '$.siriBlockUserGeneratedContent'
                                                     ,siriRequireProfanityFilter bit '$.siriRequireProfanityFilter'
                                                     ,spotlightBlockInternetResults bit '$.spotlightBlockInternetResults'
                                                     ,voiceDialingBlocked bit '$.voiceDialingBlocked'
                                                     ,wallpaperBlockModification bit '$.wallpaperBlockModification'
                                                     ,wiFiConnectOnlyToConfiguredNetworks bit '$.wiFiConnectOnlyToConfiguredNetworks'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.iosGeneralDeviceConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_iosGeneralDeviceConfigurations') IS NOT NULL
PRINT 'View "v_iosGeneralDeviceConfigurations" Created';
GO