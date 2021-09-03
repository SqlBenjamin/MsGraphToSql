USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mdmWindowsInformationProtectionPolicies

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mdmWindowsInformationProtectionPolicies') IS NOT NULL
BEGIN
    DROP TABLE dbo.mdmWindowsInformationProtectionPolicies;
    PRINT 'Table "mdmWindowsInformationProtectionPolicies" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mdmWindowsInformationProtectionPolicies ( id nvarchar(38) NOT NULL PRIMARY KEY CLUSTERED
                                                          ,displayName nvarchar(256) NOT NULL
                                                          ,enforcementLevel nvarchar(25) NOT NULL
                                                          ,description nvarchar(2000) NULL
                                                          ,enterpriseDomain nvarchar(256) NULL
                                                          ,enterpriseProtectedDomainNames_JSON nvarchar(max) NULL
                                                          ,createdDateTime datetime2 NOT NULL
                                                          ,lastModifiedDateTime datetime2 NOT NULL
                                                          ,protectionUnderLockConfigRequired bit NOT NULL
                                                          ,version nvarchar(50) NULL
                                                          ,dataRecoveryCertificate_JSON nvarchar(max) NULL
                                                          ,revokeOnUnenrollDisabled bit NOT NULL
                                                          ,rightsManagementServicesTemplateId uniqueidentifier NULL
                                                          ,azureRightsManagementServicesAllowed bit NOT NULL
                                                          ,iconsVisible bit NOT NULL
                                                          ,protectedApps_JSON nvarchar(max) NULL
                                                          ,exemptApps_JSON nvarchar(max) NULL
                                                          ,enterpriseNetworkDomainNames_JSON nvarchar(max) NULL
                                                          ,enterpriseProxiedDomains_JSON nvarchar(max) NULL
                                                          ,enterpriseIPRanges_JSON nvarchar(max) NULL
                                                          ,enterpriseIPRangesAreAuthoritative bit NOT NULL
                                                          ,enterpriseProxyServers_JSON nvarchar(max) NULL
                                                          ,enterpriseInternalProxyServers_JSON nvarchar(max) NULL
                                                          ,enterpriseProxyServersAreAuthoritative bit NOT NULL
                                                          ,neutralDomainResources_JSON nvarchar(max) NULL
                                                          ,indexingEncryptedStoresOrItemsBlocked bit NOT NULL
                                                          ,smbAutoEncryptedFileExtensions_JSON nvarchar(max) NULL
                                                          ,isAssigned bit NOT NULL
                                                          ,protectedAppLockerFiles_JSON nvarchar(max) NULL
                                                          ,exemptAppLockerFiles_JSON nvarchar(max) NULL
                                                          ,assignments_JSON nvarchar(max) NULL
                                                          ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mdmWindowsInformationProtectionPolicies') IS NOT NULL
PRINT 'Table "mdmWindowsInformationProtectionPolicies" Created';
GO