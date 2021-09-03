USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windowsUpdateForBusinessConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windowsUpdateForBusinessConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windowsUpdateForBusinessConfigurations;
    PRINT 'View "v_windowsUpdateForBusinessConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windowsUpdateForBusinessConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( deliveryOptimizationMode nvarchar(max) '$.deliveryOptimizationMode'
                                                     ,prereleaseFeatures nvarchar(max) '$.prereleaseFeatures'
                                                     ,automaticUpdateMode nvarchar(max) '$.automaticUpdateMode'
                                                     ,microsoftUpdateServiceAllowed bit '$.microsoftUpdateServiceAllowed'
                                                     ,driversExcluded bit '$.driversExcluded'
                                                     ,installationSchedule_JSON nvarchar(max) '$.installationSchedule' AS JSON
                                                     ,qualityUpdatesDeferralPeriodInDays int '$.qualityUpdatesDeferralPeriodInDays'
                                                     ,featureUpdatesDeferralPeriodInDays int '$.featureUpdatesDeferralPeriodInDays'
                                                     ,qualityUpdatesPaused bit '$.qualityUpdatesPaused'
                                                     ,featureUpdatesPaused bit '$.featureUpdatesPaused'
                                                     ,qualityUpdatesPauseExpiryDateTime datetime2 '$.qualityUpdatesPauseExpiryDateTime'
                                                     ,featureUpdatesPauseExpiryDateTime datetime2 '$.featureUpdatesPauseExpiryDateTime'
                                                     ,businessReadyUpdatesOnly nvarchar(max) '$.businessReadyUpdatesOnly'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windowsUpdateForBusinessConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windowsUpdateForBusinessConfigurations') IS NOT NULL
PRINT 'View "v_windowsUpdateForBusinessConfigurations" Created';
GO