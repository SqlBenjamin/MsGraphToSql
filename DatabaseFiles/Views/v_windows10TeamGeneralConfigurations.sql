USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_windows10TeamGeneralConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_windows10TeamGeneralConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_windows10TeamGeneralConfigurations;
    PRINT 'View "v_windows10TeamGeneralConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_windows10TeamGeneralConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( azureOperationalInsightsBlockTelemetry bit '$.azureOperationalInsightsBlockTelemetry'
                                                     ,azureOperationalInsightsWorkspaceId nvarchar(max) '$.azureOperationalInsightsWorkspaceId'
                                                     ,azureOperationalInsightsWorkspaceKey nvarchar(max) '$.azureOperationalInsightsWorkspaceKey'
                                                     ,connectAppBlockAutoLaunch bit '$.connectAppBlockAutoLaunch'
                                                     ,maintenanceWindowBlocked bit '$.maintenanceWindowBlocked'
                                                     ,maintenanceWindowDurationInHours int '$.maintenanceWindowDurationInHours'
                                                     ,maintenanceWindowStartTime datetime2 '$.maintenanceWindowStartTime'
                                                     ,miracastChannel nvarchar(max) '$.miracastChannel'
                                                     ,miracastBlocked bit '$.miracastBlocked'
                                                     ,miracastRequirePin bit '$.miracastRequirePin'
                                                     ,settingsBlockMyMeetingsAndFiles bit '$.settingsBlockMyMeetingsAndFiles'
                                                     ,settingsBlockSessionResume bit '$.settingsBlockSessionResume'
                                                     ,settingsBlockSigninSuggestions bit '$.settingsBlockSigninSuggestions'
                                                     ,settingsDefaultVolume int '$.settingsDefaultVolume'
                                                     ,settingsScreenTimeoutInMinutes int '$.settingsScreenTimeoutInMinutes'
                                                     ,settingsSessionTimeoutInMinutes int '$.settingsSessionTimeoutInMinutes'
                                                     ,settingsSleepTimeoutInMinutes int '$.settingsSleepTimeoutInMinutes'
                                                     ,welcomeScreenBlockAutomaticWakeUp bit '$.welcomeScreenBlockAutomaticWakeUp'
                                                     ,welcomeScreenBackgroundImageUrl nvarchar(max) '$.welcomeScreenBackgroundImageUrl'
                                                     ,welcomeScreenMeetingInformation nvarchar(max) '$.welcomeScreenMeetingInformation'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.windows10TeamGeneralConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_windows10TeamGeneralConfigurations') IS NOT NULL
PRINT 'View "v_windows10TeamGeneralConfigurations" Created';
GO