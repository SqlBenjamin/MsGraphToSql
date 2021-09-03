USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceCompliancePolicies_For_deviceSettingStateSummaries

History:
Date          Version    Author                   Notes:
09/02/2021    0.0        Benjamin Reynolds        Created for external sharing.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceCompliancePolicies_For_deviceSettingStateSummaries') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceCompliancePolicies_For_deviceSettingStateSummaries;
    PRINT 'View "v_deviceCompliancePolicies_For_deviceSettingStateSummaries" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceCompliancePolicies_For_deviceSettingStateSummaries AS
SELECT  *
  FROM dbo.deviceCompliancePolicies
 WHERE id IN ( N'00000000-0000-0000-0000-000000000000' -- Add ids desired here
              ,N'00000000-0000-0000-0000-000000000001'
              );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceCompliancePolicies_For_deviceSettingStateSummaries') IS NOT NULL
PRINT 'View "v_deviceCompliancePolicies_For_deviceSettingStateSummaries" Created';
GO