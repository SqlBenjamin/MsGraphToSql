USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windowsPhone81GeneralConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windowsPhone81GeneralConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windowsPhone81GeneralConfigurations;
    PRINT 'View "v_windowsPhone81GeneralConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windowsPhone81GeneralConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( applyOnlyToWindowsPhone81 bit '$.applyOnlyToWindowsPhone81'
                                                     ,appsBlockCopyPaste bit '$.appsBlockCopyPaste'
                                                     ,bluetoothBlocked bit '$.bluetoothBlocked'
                                                     ,cameraBlocked bit '$.cameraBlocked'
                                                     ,cellularBlockWifiTethering bit '$.cellularBlockWifiTethering'
                                                     ,compliantAppsList_JSON nvarchar(max) '$.compliantAppsList' AS JSON
                                                     ,compliantAppListType nvarchar(max) '$.compliantAppListType'
                                                     ,diagnosticDataBlockSubmission bit '$.diagnosticDataBlockSubmission'
                                                     ,emailBlockAddingAccounts bit '$.emailBlockAddingAccounts'
                                                     ,locationServicesBlocked bit '$.locationServicesBlocked'
                                                     ,microsoftAccountBlocked bit '$.microsoftAccountBlocked'
                                                     ,nfcBlocked bit '$.nfcBlocked'
                                                     ,passwordBlockSimple bit '$.passwordBlockSimple'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordMinimumCharacterSetCount int '$.passwordMinimumCharacterSetCount'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordSignInFailureCountBeforeFactoryReset int '$.passwordSignInFailureCountBeforeFactoryReset'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,passwordRequired bit '$.passwordRequired'
                                                     ,screenCaptureBlocked bit '$.screenCaptureBlocked'
                                                     ,storageBlockRemovableStorage bit '$.storageBlockRemovableStorage'
                                                     ,storageRequireEncryption bit '$.storageRequireEncryption'
                                                     ,webBrowserBlocked bit '$.webBrowserBlocked'
                                                     ,wifiBlocked bit '$.wifiBlocked'
                                                     ,wifiBlockAutomaticConnectHotspots bit '$.wifiBlockAutomaticConnectHotspots'
                                                     ,wifiBlockHotspotReporting bit '$.wifiBlockHotspotReporting'
                                                     ,windowsStoreBlocked bit '$.windowsStoreBlocked'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windowsPhone81GeneralConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windowsPhone81GeneralConfigurations') IS NOT NULL
PRINT 'View "v_windowsPhone81GeneralConfigurations" Created';
GO