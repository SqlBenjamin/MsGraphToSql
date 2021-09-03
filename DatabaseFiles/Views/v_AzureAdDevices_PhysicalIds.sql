USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_AzureAdDevices_PhysicalIds

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
05/19/2021    0.0        Benjamin Reynolds        Found differences in production missing in the definition file so adding here.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.
06/16/2021    0.0        Benjamin Reynolds        Changed "UserId" to "AADUserId" to avoid a conflict in another view dependent on this one.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_AzureAdDevices_PhysicalIds') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_AzureAdDevices_PhysicalIds;
    PRINT 'View "v_AzureAdDevices_PhysicalIds" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_AzureAdDevices_PhysicalIds AS
SELECT  id AS [AADObjectId]
       ,deviceId
       ,TRIM(COALESCE(SUBSTRING(USER_GID,1,CHARINDEX(':',USER_GID)-1),SUBSTRING(USER_HWID,1,CHARINDEX(':',USER_HWID)-1))) AS [AADUserId]
       ,GID
       ,HWID
       ,OrderId
       ,PurchaseOrderId
       ,ZTDID
       ,AzureResourceId
       ,SHA256_GID
       ,SHA256_HWID
       ,SHA256_USER_GID
       ,SHA256_USER_HWID
       ,USER_GID
       ,USER_HWID
  FROM dbo.devices_physicalIds;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_AzureAdDevices_PhysicalIds') IS NOT NULL
PRINT 'View "v_AzureAdDevices_PhysicalIds" Created';
GO