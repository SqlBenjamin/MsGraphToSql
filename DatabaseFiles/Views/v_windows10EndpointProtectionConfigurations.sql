USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windows10EndpointProtectionConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windows10EndpointProtectionConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windows10EndpointProtectionConfigurations;
    PRINT 'View "v_windows10EndpointProtectionConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windows10EndpointProtectionConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( firewallBlockStatefulFTP bit '$.firewallBlockStatefulFTP'
                                                     ,firewallIdleTimeoutForSecurityAssociationInSeconds int '$.firewallIdleTimeoutForSecurityAssociationInSeconds'
                                                     ,firewallPreSharedKeyEncodingMethod nvarchar(max) '$.firewallPreSharedKeyEncodingMethod'
                                                     ,firewallIPSecExemptionsAllowNeighborDiscovery bit '$.firewallIPSecExemptionsAllowNeighborDiscovery'
                                                     ,firewallIPSecExemptionsAllowICMP bit '$.firewallIPSecExemptionsAllowICMP'
                                                     ,firewallIPSecExemptionsAllowRouterDiscovery bit '$.firewallIPSecExemptionsAllowRouterDiscovery'
                                                     ,firewallIPSecExemptionsAllowDHCP bit '$.firewallIPSecExemptionsAllowDHCP'
                                                     ,firewallCertificateRevocationListCheckMethod nvarchar(max) '$.firewallCertificateRevocationListCheckMethod'
                                                     ,firewallMergeKeyingModuleSettings bit '$.firewallMergeKeyingModuleSettings'
                                                     ,firewallPacketQueueingMethod nvarchar(max) '$.firewallPacketQueueingMethod'
                                                     ,firewallProfileDomain_JSON nvarchar(max) '$.firewallProfileDomain' AS JSON
                                                     ,firewallProfilePublic_JSON nvarchar(max) '$.firewallProfilePublic' AS JSON
                                                     ,firewallProfilePrivate_JSON nvarchar(max) '$.firewallProfilePrivate' AS JSON
                                                     ,defenderAttackSurfaceReductionExcludedPaths_JSON nvarchar(max) '$.defenderAttackSurfaceReductionExcludedPaths' AS JSON
                                                     ,defenderGuardedFoldersAllowedAppPaths_JSON nvarchar(max) '$.defenderGuardedFoldersAllowedAppPaths' AS JSON
                                                     ,defenderAdditionalGuardedFolders_JSON nvarchar(max) '$.defenderAdditionalGuardedFolders' AS JSON
                                                     ,defenderExploitProtectionXml nvarchar(max) '$.defenderExploitProtectionXml'
                                                     ,defenderExploitProtectionXmlFileName nvarchar(max) '$.defenderExploitProtectionXmlFileName'
                                                     ,defenderSecurityCenterBlockExploitProtectionOverride bit '$.defenderSecurityCenterBlockExploitProtectionOverride'
                                                     ,appLockerApplicationControl nvarchar(max) '$.appLockerApplicationControl'
                                                     ,smartScreenEnableInShell bit '$.smartScreenEnableInShell'
                                                     ,smartScreenBlockOverrideForFiles bit '$.smartScreenBlockOverrideForFiles'
                                                     ,applicationGuardEnabled bit '$.applicationGuardEnabled'
                                                     ,applicationGuardBlockFileTransfer nvarchar(max) '$.applicationGuardBlockFileTransfer'
                                                     ,applicationGuardBlockNonEnterpriseContent bit '$.applicationGuardBlockNonEnterpriseContent'
                                                     ,applicationGuardAllowPersistence bit '$.applicationGuardAllowPersistence'
                                                     ,applicationGuardForceAuditing bit '$.applicationGuardForceAuditing'
                                                     ,applicationGuardBlockClipboardSharing nvarchar(max) '$.applicationGuardBlockClipboardSharing'
                                                     ,applicationGuardAllowPrintToPDF bit '$.applicationGuardAllowPrintToPDF'
                                                     ,applicationGuardAllowPrintToXPS bit '$.applicationGuardAllowPrintToXPS'
                                                     ,applicationGuardAllowPrintToLocalPrinters bit '$.applicationGuardAllowPrintToLocalPrinters'
                                                     ,applicationGuardAllowPrintToNetworkPrinters bit '$.applicationGuardAllowPrintToNetworkPrinters'
                                                     ,bitLockerDisableWarningForOtherDiskEncryption bit '$.bitLockerDisableWarningForOtherDiskEncryption'
                                                     ,bitLockerEnableStorageCardEncryptionOnMobile bit '$.bitLockerEnableStorageCardEncryptionOnMobile'
                                                     ,bitLockerEncryptDevice bit '$.bitLockerEncryptDevice'
                                                     ,bitLockerRemovableDrivePolicy_JSON nvarchar(max) '$.bitLockerRemovableDrivePolicy' AS JSON
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windows10EndpointProtectionConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windows10EndpointProtectionConfigurations') IS NOT NULL
PRINT 'View "v_windows10EndpointProtectionConfigurations" Created';
GO