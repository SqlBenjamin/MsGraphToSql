USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_androidWorkProfileGeneralDeviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_androidWorkProfileGeneralDeviceConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_androidWorkProfileGeneralDeviceConfigurations;
    PRINT 'View "v_androidWorkProfileGeneralDeviceConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_androidWorkProfileGeneralDeviceConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( passwordBlockFingerprintUnlock bit '$.passwordBlockFingerprintUnlock'
                                                     ,passwordBlockTrustAgents bit '$.passwordBlockTrustAgents'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordSignInFailureCountBeforeFactoryReset int '$.passwordSignInFailureCountBeforeFactoryReset'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,workProfileDataSharingType nvarchar(max) '$.workProfileDataSharingType'
                                                     ,workProfileBlockNotificationsWhileDeviceLocked bit '$.workProfileBlockNotificationsWhileDeviceLocked'
                                                     ,workProfileBlockAddingAccounts bit '$.workProfileBlockAddingAccounts'
                                                     ,workProfileBluetoothEnableContactSharing bit '$.workProfileBluetoothEnableContactSharing'
                                                     ,workProfileBlockScreenCapture bit '$.workProfileBlockScreenCapture'
                                                     ,workProfileBlockCrossProfileCallerId bit '$.workProfileBlockCrossProfileCallerId'
                                                     ,workProfileBlockCamera bit '$.workProfileBlockCamera'
                                                     ,workProfileBlockCrossProfileContactsSearch bit '$.workProfileBlockCrossProfileContactsSearch'
                                                     ,workProfileBlockCrossProfileCopyPaste bit '$.workProfileBlockCrossProfileCopyPaste'
                                                     ,workProfileDefaultAppPermissionPolicy nvarchar(max) '$.workProfileDefaultAppPermissionPolicy'
                                                     ,workProfilePasswordBlockFingerprintUnlock bit '$.workProfilePasswordBlockFingerprintUnlock'
                                                     ,workProfilePasswordBlockTrustAgents bit '$.workProfilePasswordBlockTrustAgents'
                                                     ,workProfilePasswordExpirationDays int '$.workProfilePasswordExpirationDays'
                                                     ,workProfilePasswordMinimumLength int '$.workProfilePasswordMinimumLength'
                                                     ,workProfilePasswordMinNumericCharacters int '$.workProfilePasswordMinNumericCharacters'
                                                     ,workProfilePasswordMinNonLetterCharacters int '$.workProfilePasswordMinNonLetterCharacters'
                                                     ,workProfilePasswordMinLetterCharacters int '$.workProfilePasswordMinLetterCharacters'
                                                     ,workProfilePasswordMinLowerCaseCharacters int '$.workProfilePasswordMinLowerCaseCharacters'
                                                     ,workProfilePasswordMinUpperCaseCharacters int '$.workProfilePasswordMinUpperCaseCharacters'
                                                     ,workProfilePasswordMinSymbolCharacters int '$.workProfilePasswordMinSymbolCharacters'
                                                     ,workProfilePasswordMinutesOfInactivityBeforeScreenTimeout int '$.workProfilePasswordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,workProfilePasswordPreviousPasswordBlockCount int '$.workProfilePasswordPreviousPasswordBlockCount'
                                                     ,workProfilePasswordSignInFailureCountBeforeFactoryReset int '$.workProfilePasswordSignInFailureCountBeforeFactoryReset'
                                                     ,workProfilePasswordRequiredType nvarchar(max) '$.workProfilePasswordRequiredType'
                                                     ,workProfileRequirePassword bit '$.workProfileRequirePassword'
                                                     ,securityRequireVerifyApps bit '$.securityRequireVerifyApps'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.androidWorkProfileGeneralDeviceConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_androidWorkProfileGeneralDeviceConfigurations') IS NOT NULL
PRINT 'View "v_androidWorkProfileGeneralDeviceConfigurations" Created';
GO