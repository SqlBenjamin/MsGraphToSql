USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_Autopilot_AadInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_Autopilot_AadInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_Autopilot_AadInfo;
    PRINT 'View "v_Autopilot_AadInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_Autopilot_AadInfo AS
SELECT  *
  FROM dbo.v_WindowsAutopilotDevices wad
        LEFT OUTER JOIN dbo.v_AzureAdDevices_PhysicalIds zti
          ON wad.ZtId = zti.ZTDID
        LEFT OUTER JOIN dbo.v_AzureAdDevices dvc
          ON zti.AADObjectId = dvc.AAD_ObjectId
         AND dvc.AzureAd_OperatingSystem = N'Windows'
        LEFT OUTER JOIN dbo.v_managedDevices mdv
          ON dvc.AAD_DeviceId = mdv.azureADDeviceId;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_Autopilot_AadInfo') IS NOT NULL
PRINT 'View "v_Autopilot_AadInfo" Created';
GO