USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WIP_neutralDomainResourcesInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WIP_neutralDomainResourcesInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WIP_neutralDomainResourcesInfo;
    PRINT 'View "v_WIP_neutralDomainResourcesInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WIP_neutralDomainResourcesInfo AS
SELECT  wip.id
       ,jsn.displayName
       ,res.resources
  FROM dbo.mdmWindowsInformationProtectionPolicies wip
       OUTER APPLY OPENJSON (wip.neutralDomainResources_JSON) WITH ( displayName nvarchar(max) '$.displayName'
                                                                    ,resources nvarchar(max) '$.resources' AS JSON
                                                                    ) jsn
       OUTER APPLY OPENJSON (jsn.resources) WITH ( resources nvarchar(max) '$'
                                                  ) res;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WIP_neutralDomainResourcesInfo') IS NOT NULL
PRINT 'View "v_WIP_neutralDomainResourcesInfo" Created';
GO