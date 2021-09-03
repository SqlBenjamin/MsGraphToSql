USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_IdsForDCPDeviceStatusOverview

History:
Date          Version    Author                   Notes:
07/16/2021    0.0        Benjamin Reynolds        Created.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_IdsForDCPDeviceStatusOverview') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_IdsForDCPDeviceStatusOverview;
    PRINT 'View "v_IdsForDCPDeviceStatusOverview" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_IdsForDCPDeviceStatusOverview AS
SELECT  id
       ,displayName
       ,N'deviceCompliancePolicies' AS [SourceTable]
  FROM dbo.deviceCompliancePolicies
UNION ALL
SELECT  id
       ,displayName
       ,N'groupPolicyConfigurations'
  FROM dbo.groupPolicyConfigurations;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_IdsForDCPDeviceStatusOverview') IS NOT NULL
PRINT 'View "v_IdsForDCPDeviceStatusOverview" Created';
GO