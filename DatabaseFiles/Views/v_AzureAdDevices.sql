USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_AzureAdDevices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_AzureAdDevices') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_AzureAdDevices;
    PRINT 'View "v_AzureAdDevices" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_AzureAdDevices AS
SELECT  id AS [AAD_ObjectId]
       ,deletedDateTime
       ,accountEnabled
       ,alternativeSecurityIds_JSON
       ,approximateLastSignInDateTime
       ,complianceExpirationDateTime
       ,deviceId AS [AAD_DeviceId]
       ,deviceMetadata
       ,deviceVersion
       ,displayName
       ,isCompliant
       ,isManaged
       ,mdmAppId
       ,onPremisesLastSyncDateTime
       ,onPremisesSyncEnabled
       ,operatingSystem AS [AzureAd_OperatingSystem]
       ,operatingSystemVersion
       ,physicalIds_JSON
       ,profileType
       ,systemLabels_JSON
       ,trustType
  FROM dbo.devices;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_AzureAdDevices') IS NOT NULL
PRINT 'View "v_AzureAdDevices" Created';
GO