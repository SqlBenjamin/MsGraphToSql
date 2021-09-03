USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windows10GeneralConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windows10GeneralConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windows10GeneralConfigurations;
    PRINT 'View "v_windows10GeneralConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windows10GeneralConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( enterpriseCloudPrintDiscoveryEndPoint nvarchar(max) '$.enterpriseCloudPrintDiscoveryEndPoint'
                                                     ,enterpriseCloudPrintOAuthAuthority nvarchar(max) '$.enterpriseCloudPrintOAuthAuthority'
                                                     ,enterpriseCloudPrintOAuthClientIdentifier nvarchar(max) '$.enterpriseCloudPrintOAuthClientIdentifier'
                                                     ,enterpriseCloudPrintResourceIdentifier nvarchar(max) '$.enterpriseCloudPrintResourceIdentifier'
                                                     ,enterpriseCloudPrintDiscoveryMaxLimit int '$.enterpriseCloudPrintDiscoveryMaxLimit'
                                                     ,enterpriseCloudPrintMopriaDiscoveryResourceIdentifier nvarchar(max) '$.enterpriseCloudPrintMopriaDiscoveryResourceIdentifier'
                                                     ,searchBlockDiacritics bit '$.searchBlockDiacritics'
                                                     ,searchDisableAutoLanguageDetection bit '$.searchDisableAutoLanguageDetection'
                                                     ,searchDisableIndexingEncryptedItems bit '$.searchDisableIndexingEncryptedItems'
                                                     ,searchEnableRemoteQueries bit '$.searchEnableRemoteQueries'
                                                     ,searchDisableIndexerBackoff bit '$.searchDisableIndexerBackoff'
                                                     ,searchDisableIndexingRemovableDrive bit '$.searchDisableIndexingRemovableDrive'
                                                     ,searchEnableAutomaticIndexSizeManangement bit '$.searchEnableAutomaticIndexSizeManangement'
                                                     ,diagnosticsDataSubmissionMode nvarchar(max) '$.diagnosticsDataSubmissionMode'
                                                     ,oneDriveDisableFileSync bit '$.oneDriveDisableFileSync'
                                                     ,smartScreenEnableAppInstallControl bit '$.smartScreenEnableAppInstallControl'
                                                     ,personalizationDesktopImageUrl nvarchar(max) '$.personalizationDesktopImageUrl'
                                                     ,personalizationLockScreenImageUrl nvarchar(max) '$.personalizationLockScreenImageUrl'
                                                     ,bluetoothAllowedServices_JSON nvarchar(max) '$.bluetoothAllowedServices' AS JSON
                                                     ,bluetoothBlockAdvertising bit '$.bluetoothBlockAdvertising'
                                                     ,bluetoothBlockDiscoverableMode bit '$.bluetoothBlockDiscoverableMode'
                                                     ,bluetoothBlockPrePairing bit '$.bluetoothBlockPrePairing'
                                                     ,edgeBlockAutofill bit '$.edgeBlockAutofill'
                                                     ,edgeBlocked bit '$.edgeBlocked'
                                                     ,edgeCookiePolicy nvarchar(max) '$.edgeCookiePolicy'
                                                     ,edgeBlockDeveloperTools bit '$.edgeBlockDeveloperTools'
                                                     ,edgeBlockSendingDoNotTrackHeader bit '$.edgeBlockSendingDoNotTrackHeader'
                                                     ,edgeBlockExtensions bit '$.edgeBlockExtensions'
                                                     ,edgeBlockInPrivateBrowsing bit '$.edgeBlockInPrivateBrowsing'
                                                     ,edgeBlockJavaScript bit '$.edgeBlockJavaScript'
                                                     ,edgeBlockPasswordManager bit '$.edgeBlockPasswordManager'
                                                     ,edgeBlockAddressBarDropdown bit '$.edgeBlockAddressBarDropdown'
                                                     ,edgeBlockCompatibilityList bit '$.edgeBlockCompatibilityList'
                                                     ,edgeClearBrowsingDataOnExit bit '$.edgeClearBrowsingDataOnExit'
                                                     ,edgeAllowStartPagesModification bit '$.edgeAllowStartPagesModification'
                                                     ,edgeDisableFirstRunPage bit '$.edgeDisableFirstRunPage'
                                                     ,edgeBlockLiveTileDataCollection bit '$.edgeBlockLiveTileDataCollection'
                                                     ,edgeSyncFavoritesWithInternetExplorer bit '$.edgeSyncFavoritesWithInternetExplorer'
                                                     ,cellularBlockDataWhenRoaming bit '$.cellularBlockDataWhenRoaming'
                                                     ,cellularBlockVpn bit '$.cellularBlockVpn'
                                                     ,cellularBlockVpnWhenRoaming bit '$.cellularBlockVpnWhenRoaming'
                                                     ,defenderBlockEndUserAccess bit '$.defenderBlockEndUserAccess'
                                                     ,defenderDaysBeforeDeletingQuarantinedMalware int '$.defenderDaysBeforeDeletingQuarantinedMalware'
                                                     ,defenderDetectedMalwareActions_JSON nvarchar(max) '$.defenderDetectedMalwareActions' AS JSON
                                                     ,defenderSystemScanSchedule nvarchar(max) '$.defenderSystemScanSchedule'
                                                     ,defenderFilesAndFoldersToExclude_JSON nvarchar(max) '$.defenderFilesAndFoldersToExclude' AS JSON
                                                     ,defenderFileExtensionsToExclude_JSON nvarchar(max) '$.defenderFileExtensionsToExclude' AS JSON
                                                     ,defenderScanMaxCpu int '$.defenderScanMaxCpu'
                                                     ,defenderMonitorFileActivity nvarchar(max) '$.defenderMonitorFileActivity'
                                                     ,defenderProcessesToExclude_JSON nvarchar(max) '$.defenderProcessesToExclude' AS JSON
                                                     ,defenderPromptForSampleSubmission nvarchar(max) '$.defenderPromptForSampleSubmission'
                                                     ,defenderRequireBehaviorMonitoring bit '$.defenderRequireBehaviorMonitoring'
                                                     ,defenderRequireCloudProtection bit '$.defenderRequireCloudProtection'
                                                     ,defenderRequireNetworkInspectionSystem bit '$.defenderRequireNetworkInspectionSystem'
                                                     ,defenderRequireRealTimeMonitoring bit '$.defenderRequireRealTimeMonitoring'
                                                     ,defenderScanArchiveFiles bit '$.defenderScanArchiveFiles'
                                                     ,defenderScanDownloads bit '$.defenderScanDownloads'
                                                     ,defenderScanNetworkFiles bit '$.defenderScanNetworkFiles'
                                                     ,defenderScanIncomingMail bit '$.defenderScanIncomingMail'
                                                     ,defenderScanMappedNetworkDrivesDuringFullScan bit '$.defenderScanMappedNetworkDrivesDuringFullScan'
                                                     ,defenderScanRemovableDrivesDuringFullScan bit '$.defenderScanRemovableDrivesDuringFullScan'
                                                     ,defenderScanScriptsLoadedInInternetExplorer bit '$.defenderScanScriptsLoadedInInternetExplorer'
                                                     ,defenderSignatureUpdateIntervalInHours int '$.defenderSignatureUpdateIntervalInHours'
                                                     ,defenderScanType nvarchar(max) '$.defenderScanType'
                                                     ,defenderScheduledScanTime datetime2 '$.defenderScheduledScanTime'
                                                     ,defenderScheduledQuickScanTime datetime2 '$.defenderScheduledQuickScanTime'
                                                     ,defenderCloudBlockLevel nvarchar(max) '$.defenderCloudBlockLevel'
                                                     ,lockScreenAllowTimeoutConfiguration bit '$.lockScreenAllowTimeoutConfiguration'
                                                     ,lockScreenBlockActionCenterNotifications bit '$.lockScreenBlockActionCenterNotifications'
                                                     ,lockScreenBlockCortana bit '$.lockScreenBlockCortana'
                                                     ,lockScreenBlockToastNotifications bit '$.lockScreenBlockToastNotifications'
                                                     ,lockScreenTimeoutInSeconds int '$.lockScreenTimeoutInSeconds'
                                                     ,passwordBlockSimple bit '$.passwordBlockSimple'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordMinimumCharacterSetCount int '$.passwordMinimumCharacterSetCount'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordRequired bit '$.passwordRequired'
                                                     ,passwordRequireWhenResumeFromIdleState bit '$.passwordRequireWhenResumeFromIdleState'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,passwordSignInFailureCountBeforeFactoryReset int '$.passwordSignInFailureCountBeforeFactoryReset'
                                                     ,privacyAdvertisingId nvarchar(max) '$.privacyAdvertisingId'
                                                     ,privacyAutoAcceptPairingAndConsentPrompts bit '$.privacyAutoAcceptPairingAndConsentPrompts'
                                                     ,privacyBlockInputPersonalization bit '$.privacyBlockInputPersonalization'
                                                     ,startBlockUnpinningAppsFromTaskbar bit '$.startBlockUnpinningAppsFromTaskbar'
                                                     ,startMenuAppListVisibility nvarchar(max) '$.startMenuAppListVisibility'
                                                     ,startMenuHideChangeAccountSettings bit '$.startMenuHideChangeAccountSettings'
                                                     ,startMenuHideFrequentlyUsedApps bit '$.startMenuHideFrequentlyUsedApps'
                                                     ,startMenuHideHibernate bit '$.startMenuHideHibernate'
                                                     ,startMenuHideLock bit '$.startMenuHideLock'
                                                     ,startMenuHidePowerButton bit '$.startMenuHidePowerButton'
                                                     ,startMenuHideRecentJumpLists bit '$.startMenuHideRecentJumpLists'
                                                     ,startMenuHideRecentlyAddedApps bit '$.startMenuHideRecentlyAddedApps'
                                                     ,startMenuHideRestartOptions bit '$.startMenuHideRestartOptions'
                                                     ,startMenuHideShutDown bit '$.startMenuHideShutDown'
                                                     ,startMenuHideSignOut bit '$.startMenuHideSignOut'
                                                     ,startMenuHideSleep bit '$.startMenuHideSleep'
                                                     ,startMenuHideSwitchAccount bit '$.startMenuHideSwitchAccount'
                                                     ,startMenuHideUserTile bit '$.startMenuHideUserTile'
                                                     ,startMenuLayoutEdgeAssetsXml nvarchar(max) '$.startMenuLayoutEdgeAssetsXml'
                                                     ,startMenuLayoutXml nvarchar(max) '$.startMenuLayoutXml'
                                                     ,startMenuMode nvarchar(max) '$.startMenuMode'
                                                     ,startMenuPinnedFolderDocuments nvarchar(max) '$.startMenuPinnedFolderDocuments'
                                                     ,startMenuPinnedFolderDownloads nvarchar(max) '$.startMenuPinnedFolderDownloads'
                                                     ,startMenuPinnedFolderFileExplorer nvarchar(max) '$.startMenuPinnedFolderFileExplorer'
                                                     ,startMenuPinnedFolderHomeGroup nvarchar(max) '$.startMenuPinnedFolderHomeGroup'
                                                     ,startMenuPinnedFolderMusic nvarchar(max) '$.startMenuPinnedFolderMusic'
                                                     ,startMenuPinnedFolderNetwork nvarchar(max) '$.startMenuPinnedFolderNetwork'
                                                     ,startMenuPinnedFolderPersonalFolder nvarchar(max) '$.startMenuPinnedFolderPersonalFolder'
                                                     ,startMenuPinnedFolderPictures nvarchar(max) '$.startMenuPinnedFolderPictures'
                                                     ,startMenuPinnedFolderSettings nvarchar(max) '$.startMenuPinnedFolderSettings'
                                                     ,startMenuPinnedFolderVideos nvarchar(max) '$.startMenuPinnedFolderVideos'
                                                     ,settingsBlockSettingsApp bit '$.settingsBlockSettingsApp'
                                                     ,settingsBlockSystemPage bit '$.settingsBlockSystemPage'
                                                     ,settingsBlockDevicesPage bit '$.settingsBlockDevicesPage'
                                                     ,settingsBlockNetworkInternetPage bit '$.settingsBlockNetworkInternetPage'
                                                     ,settingsBlockPersonalizationPage bit '$.settingsBlockPersonalizationPage'
                                                     ,settingsBlockAccountsPage bit '$.settingsBlockAccountsPage'
                                                     ,settingsBlockTimeLanguagePage bit '$.settingsBlockTimeLanguagePage'
                                                     ,settingsBlockEaseOfAccessPage bit '$.settingsBlockEaseOfAccessPage'
                                                     ,settingsBlockPrivacyPage bit '$.settingsBlockPrivacyPage'
                                                     ,settingsBlockUpdateSecurityPage bit '$.settingsBlockUpdateSecurityPage'
                                                     ,settingsBlockAppsPage bit '$.settingsBlockAppsPage'
                                                     ,settingsBlockGamingPage bit '$.settingsBlockGamingPage'
                                                     ,windowsSpotlightBlockConsumerSpecificFeatures bit '$.windowsSpotlightBlockConsumerSpecificFeatures'
                                                     ,windowsSpotlightBlocked bit '$.windowsSpotlightBlocked'
                                                     ,windowsSpotlightBlockOnActionCenter bit '$.windowsSpotlightBlockOnActionCenter'
                                                     ,windowsSpotlightBlockTailoredExperiences bit '$.windowsSpotlightBlockTailoredExperiences'
                                                     ,windowsSpotlightBlockThirdPartyNotifications bit '$.windowsSpotlightBlockThirdPartyNotifications'
                                                     ,windowsSpotlightBlockWelcomeExperience bit '$.windowsSpotlightBlockWelcomeExperience'
                                                     ,windowsSpotlightBlockWindowsTips bit '$.windowsSpotlightBlockWindowsTips'
                                                     ,windowsSpotlightConfigureOnLockScreen nvarchar(max) '$.windowsSpotlightConfigureOnLockScreen'
                                                     ,networkProxyApplySettingsDeviceWide bit '$.networkProxyApplySettingsDeviceWide'
                                                     ,networkProxyDisableAutoDetect bit '$.networkProxyDisableAutoDetect'
                                                     ,networkProxyAutomaticConfigurationUrl nvarchar(max) '$.networkProxyAutomaticConfigurationUrl'
                                                     ,networkProxyServer_JSON nvarchar(max) '$.networkProxyServer' AS JSON
                                                     ,accountsBlockAddingNonMicrosoftAccountEmail bit '$.accountsBlockAddingNonMicrosoftAccountEmail'
                                                     ,antiTheftModeBlocked bit '$.antiTheftModeBlocked'
                                                     ,bluetoothBlocked bit '$.bluetoothBlocked'
                                                     ,cameraBlocked bit '$.cameraBlocked'
                                                     ,connectedDevicesServiceBlocked bit '$.connectedDevicesServiceBlocked'
                                                     ,certificatesBlockManualRootCertificateInstallation bit '$.certificatesBlockManualRootCertificateInstallation'
                                                     ,copyPasteBlocked bit '$.copyPasteBlocked'
                                                     ,cortanaBlocked bit '$.cortanaBlocked'
                                                     ,deviceManagementBlockFactoryResetOnMobile bit '$.deviceManagementBlockFactoryResetOnMobile'
                                                     ,deviceManagementBlockManualUnenroll bit '$.deviceManagementBlockManualUnenroll'
                                                     ,safeSearchFilter nvarchar(max) '$.safeSearchFilter'
                                                     ,edgeBlockPopups bit '$.edgeBlockPopups'
                                                     ,edgeBlockSearchSuggestions bit '$.edgeBlockSearchSuggestions'
                                                     ,edgeBlockSendingIntranetTrafficToInternetExplorer bit '$.edgeBlockSendingIntranetTrafficToInternetExplorer'
                                                     ,edgeRequireSmartScreen bit '$.edgeRequireSmartScreen'
                                                     ,edgeEnterpriseModeSiteListLocation nvarchar(max) '$.edgeEnterpriseModeSiteListLocation'
                                                     ,edgeFirstRunUrl nvarchar(max) '$.edgeFirstRunUrl'
                                                     ,edgeSearchEngine_JSON nvarchar(max) '$.edgeSearchEngine' AS JSON
                                                     ,edgeHomepageUrls_JSON nvarchar(max) '$.edgeHomepageUrls' AS JSON
                                                     ,edgeBlockAccessToAboutFlags bit '$.edgeBlockAccessToAboutFlags'
                                                     ,smartScreenBlockPromptOverride bit '$.smartScreenBlockPromptOverride'
                                                     ,smartScreenBlockPromptOverrideForFiles bit '$.smartScreenBlockPromptOverrideForFiles'
                                                     ,webRtcBlockLocalhostIpAddress bit '$.webRtcBlockLocalhostIpAddress'
                                                     ,internetSharingBlocked bit '$.internetSharingBlocked'
                                                     ,settingsBlockAddProvisioningPackage bit '$.settingsBlockAddProvisioningPackage'
                                                     ,settingsBlockRemoveProvisioningPackage bit '$.settingsBlockRemoveProvisioningPackage'
                                                     ,settingsBlockChangeSystemTime bit '$.settingsBlockChangeSystemTime'
                                                     ,settingsBlockEditDeviceName bit '$.settingsBlockEditDeviceName'
                                                     ,settingsBlockChangeRegion bit '$.settingsBlockChangeRegion'
                                                     ,settingsBlockChangeLanguage bit '$.settingsBlockChangeLanguage'
                                                     ,settingsBlockChangePowerSleep bit '$.settingsBlockChangePowerSleep'
                                                     ,locationServicesBlocked bit '$.locationServicesBlocked'
                                                     ,microsoftAccountBlocked bit '$.microsoftAccountBlocked'
                                                     ,microsoftAccountBlockSettingsSync bit '$.microsoftAccountBlockSettingsSync'
                                                     ,nfcBlocked bit '$.nfcBlocked'
                                                     ,resetProtectionModeBlocked bit '$.resetProtectionModeBlocked'
                                                     ,screenCaptureBlocked bit '$.screenCaptureBlocked'
                                                     ,storageBlockRemovableStorage bit '$.storageBlockRemovableStorage'
                                                     ,storageRequireMobileDeviceEncryption bit '$.storageRequireMobileDeviceEncryption'
                                                     ,usbBlocked bit '$.usbBlocked'
                                                     ,voiceRecordingBlocked bit '$.voiceRecordingBlocked'
                                                     ,wiFiBlockAutomaticConnectHotspots bit '$.wiFiBlockAutomaticConnectHotspots'
                                                     ,wiFiBlocked bit '$.wiFiBlocked'
                                                     ,wiFiBlockManualConfiguration bit '$.wiFiBlockManualConfiguration'
                                                     ,wiFiScanInterval int '$.wiFiScanInterval'
                                                     ,wirelessDisplayBlockProjectionToThisDevice bit '$.wirelessDisplayBlockProjectionToThisDevice'
                                                     ,wirelessDisplayBlockUserInputFromReceiver bit '$.wirelessDisplayBlockUserInputFromReceiver'
                                                     ,wirelessDisplayRequirePinForPairing bit '$.wirelessDisplayRequirePinForPairing'
                                                     ,windowsStoreBlocked bit '$.windowsStoreBlocked'
                                                     ,appsAllowTrustedAppsSideloading nvarchar(max) '$.appsAllowTrustedAppsSideloading'
                                                     ,windowsStoreBlockAutoUpdate bit '$.windowsStoreBlockAutoUpdate'
                                                     ,developerUnlockSetting nvarchar(max) '$.developerUnlockSetting'
                                                     ,sharedUserAppDataAllowed bit '$.sharedUserAppDataAllowed'
                                                     ,appsBlockWindowsStoreOriginatedApps bit '$.appsBlockWindowsStoreOriginatedApps'
                                                     ,windowsStoreEnablePrivateStoreOnly bit '$.windowsStoreEnablePrivateStoreOnly'
                                                     ,storageRestrictAppDataToSystemVolume bit '$.storageRestrictAppDataToSystemVolume'
                                                     ,storageRestrictAppInstallToSystemVolume bit '$.storageRestrictAppInstallToSystemVolume'
                                                     ,gameDvrBlocked bit '$.gameDvrBlocked'
                                                     ,experienceBlockDeviceDiscovery bit '$.experienceBlockDeviceDiscovery'
                                                     ,experienceBlockErrorDialogWhenNoSIM bit '$.experienceBlockErrorDialogWhenNoSIM'
                                                     ,experienceBlockTaskSwitcher bit '$.experienceBlockTaskSwitcher'
                                                     ,logonBlockFastUserSwitching bit '$.logonBlockFastUserSwitching'
                                                     ,tenantLockdownRequireNetworkDuringOutOfBoxExperience bit '$.tenantLockdownRequireNetworkDuringOutOfBoxExperience'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windows10GeneralConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windows10GeneralConfigurations') IS NOT NULL
PRINT 'View "v_windows10GeneralConfigurations" Created';
GO