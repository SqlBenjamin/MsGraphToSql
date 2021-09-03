USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.managedAppPolicies

History:
Date          Version    Author                   Notes:
05/19/2021    0.0        Benjamin Reynolds        Created. (definition from v-dhraj)
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.managedAppPolicies') IS NOT NULL
BEGIN
    DROP TABLE dbo.managedAppPolicies;
    PRINT 'Table "managedAppPolicies" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.managedAppPolicies( odatatype nvarchar(256) NOT NULL
                                    ,id nvarchar(73) NOT NULL
                                    ,displayName nvarchar(256) NOT NULL
                                    ,description nvarchar(2000) NULL
                                    ,createdDateTime datetime2(7) NOT NULL
                                    ,lastModifiedDateTime datetime2(7) NOT NULL
                                    ,version nvarchar(50) NULL
                                    ,enforcementLevel nvarchar(25) NULL
                                    ,enterpriseDomain nvarchar(256) NULL
                                    ,protectionUnderLockConfigRequired bit NULL
                                    ,revokeOnUnenrollDisabled bit NULL
                                    ,rightsManagementServicesTemplateId uniqueidentifier NULL
                                    ,azureRightsManagementServicesAllowed bit NULL
                                    ,iconsVisible bit NULL
                                    ,enterpriseIPRangesAreAuthoritative bit NULL
                                    ,enterpriseProxyServersAreAuthoritative bit NULL
                                    ,indexingEncryptedStoresOrItemsBlocked bit NULL
                                    ,isAssigned bit NULL
                                    ,enterpriseProtectedDomainNames_JSON nvarchar(max) NULL
                                    ,dataRecoveryCertificate_JSON nvarchar(max) NULL
                                    ,protectedApps_JSON nvarchar(max) NULL
                                    ,exemptApps_JSON nvarchar(max) NULL
                                    ,enterpriseNetworkDomainNames_JSON nvarchar(max) NULL
                                    ,enterpriseProxiedDomains_JSON nvarchar(max) NULL
                                    ,enterpriseIPRanges_JSON nvarchar(max) NULL
                                    ,enterpriseProxyServers_JSON nvarchar(max) NULL
                                    ,enterpriseInternalProxyServers_JSON nvarchar(max) NULL
                                    ,neutralDomainResources_JSON nvarchar(max) NULL
                                    ,smbAutoEncryptedFileExtensions_JSON nvarchar(max) NULL
                                    ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.managedAppPolicies') IS NOT NULL
PRINT 'Table "managedAppPolicies" Created';
GO