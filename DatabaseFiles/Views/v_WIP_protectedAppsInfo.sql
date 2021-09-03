USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WIP_protectedAppsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WIP_protectedAppsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WIP_protectedAppsInfo;
    PRINT 'View "v_WIP_protectedAppsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WIP_protectedAppsInfo AS
SELECT  wip.id
       ,jsn.*
  FROM dbo.mdmWindowsInformationProtectionPolicies wip
       OUTER APPLY OPENJSON (wip.protectedApps_JSON) WITH ( displayName nvarchar(max) '$.displayName'
                                                           ,description nvarchar(max) '$.description'
                                                           ,publisherName nvarchar(max) '$.publisherName'
                                                           ,productName nvarchar(max) '$.productName'
                                                           ,denied bit '$.denied'
                                                           ,binaryName nvarchar(max) '$.binaryName'
                                                           ,binaryVersionLow nvarchar(max) '$.binaryVersionLow'
                                                           ,binaryVersionHigh nvarchar(max) '$.binaryVersionHigh'
                                                           ) jsn;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WIP_protectedAppsInfo') IS NOT NULL
PRINT 'View "v_WIP_protectedAppsInfo" Created';
GO