USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windows81GeneralConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windows81GeneralConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windows81GeneralConfigurations;
    PRINT 'View "v_windows81GeneralConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windows81GeneralConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( accountsBlockAddingNonMicrosoftAccountEmail bit '$.accountsBlockAddingNonMicrosoftAccountEmail'
                                                     ,applyOnlyToWindows81 bit '$.applyOnlyToWindows81'
                                                     ,browserBlockAutofill bit '$.browserBlockAutofill'
                                                     ,browserBlockAutomaticDetectionOfIntranetSites bit '$.browserBlockAutomaticDetectionOfIntranetSites'
                                                     ,browserBlockEnterpriseModeAccess bit '$.browserBlockEnterpriseModeAccess'
                                                     ,browserBlockJavaScript bit '$.browserBlockJavaScript'
                                                     ,browserBlockPlugins bit '$.browserBlockPlugins'
                                                     ,browserBlockPopups bit '$.browserBlockPopups'
                                                     ,browserBlockSendingDoNotTrackHeader bit '$.browserBlockSendingDoNotTrackHeader'
                                                     ,browserBlockSingleWordEntryOnIntranetSites bit '$.browserBlockSingleWordEntryOnIntranetSites'
                                                     ,browserRequireSmartScreen bit '$.browserRequireSmartScreen'
                                                     ,browserEnterpriseModeSiteListLocation nvarchar(max) '$.browserEnterpriseModeSiteListLocation'
                                                     ,browserInternetSecurityLevel nvarchar(max) '$.browserInternetSecurityLevel'
                                                     ,browserIntranetSecurityLevel nvarchar(max) '$.browserIntranetSecurityLevel'
                                                     ,browserLoggingReportLocation nvarchar(max) '$.browserLoggingReportLocation'
                                                     ,browserRequireHighSecurityForRestrictedSites bit '$.browserRequireHighSecurityForRestrictedSites'
                                                     ,browserRequireFirewall bit '$.browserRequireFirewall'
                                                     ,browserRequireFraudWarning bit '$.browserRequireFraudWarning'
                                                     ,browserTrustedSitesSecurityLevel nvarchar(max) '$.browserTrustedSitesSecurityLevel'
                                                     ,cellularBlockDataRoaming bit '$.cellularBlockDataRoaming'
                                                     ,diagnosticsBlockDataSubmission bit '$.diagnosticsBlockDataSubmission'
                                                     ,passwordBlockPicturePasswordAndPin bit '$.passwordBlockPicturePasswordAndPin'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordMinimumCharacterSetCount int '$.passwordMinimumCharacterSetCount'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,passwordSignInFailureCountBeforeFactoryReset int '$.passwordSignInFailureCountBeforeFactoryReset'
                                                     ,storageRequireDeviceEncryption bit '$.storageRequireDeviceEncryption'
                                                     ,updatesRequireAutomaticUpdates bit '$.updatesRequireAutomaticUpdates'
                                                     ,userAccountControlSettings nvarchar(max) '$.userAccountControlSettings'
                                                     ,workFoldersUrl nvarchar(max) '$.workFoldersUrl'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windows81GeneralConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windows81GeneralConfigurations') IS NOT NULL
PRINT 'View "v_windows81GeneralConfigurations" Created';
GO