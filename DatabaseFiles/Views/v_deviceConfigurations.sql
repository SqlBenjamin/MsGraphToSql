USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceConfigurations;
    PRINT 'View "v_deviceConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceConfigurations AS
SELECT  odatatype
       ,id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,CASE WHEN odatatype IN (N'#microsoft.graph.windows10EndpointProtectionConfiguration',N'#microsoft.graph.windowsDefenderAdvancedThreatProtectionConfiguration') THEN 'EndPointProtection'
             WHEN odatatype = N'#microsoft.graph.windows10CustomConfiguration' THEN 'DeviceConfiguration'
             WHEN odatatype = N'#microsoft.graph.windowsUpdateForBusinessConfiguration' THEN 'WUFB'
             WHEN odatatype IN (N'#microsoft.graph.windows81TrustedRootCertificate',N'#microsoft.graph.windows81WifiImportConfiguration',N'#microsoft.graph.windows81SCEPCertificateProfile',N'#microsoft.graph.windows10VpnConfiguration' ) THEN 'ResourceAccess'
             WHEN odatatype LIKE N'#microsoft.graph.ios%' THEN 'iOS Policies'
             WHEN odatatype LIKE N'#microsoft.graph.android%' THEN 'Android Policies'
             WHEN odatatype LIKE N'#microsoft.graph.macOS%' THEN 'MAC Policies'
             WHEN odatatype LIKE N'#microsoft.graph.windowsPhone81%' THEN 'WindowsPhone Policies'
             WHEN odatatype = N'#microsoft.graph.windows10TeamGeneralConfiguration' THEN 'Surface Hub Policies'
             WHEN odatatype = N'#microsoft.graph.editionUpgradeConfiguration' THEN 'HOLOLens Policies'
             ELSE 'Combination of configuration and EP'
        END AS [WorkloadType]
       ,AllData_JSON
  FROM dbo.deviceConfigurations;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceConfigurations') IS NOT NULL
PRINT 'View "v_deviceConfigurations" Created';
GO