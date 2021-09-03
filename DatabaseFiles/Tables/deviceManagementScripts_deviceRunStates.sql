USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceManagementScripts_deviceRunStates

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceManagementScripts_deviceRunStates') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceManagementScripts_deviceRunStates;
    PRINT 'Table "deviceManagementScripts_deviceRunStates" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceManagementScripts_deviceRunStates ( ParentId nvarchar(36) NOT NULL
                                                          ,id nvarchar(73) NOT NULL --PRIMARY KEY CLUSTERED
                                                          ,runState nvarchar(11) NOT NULL
                                                          ,resultMessage nvarchar(max) NULL
                                                          ,lastStateUpdateDateTime datetime2 NOT NULL
                                                          ,errorCode int NOT NULL
                                                          ,errorDescription nvarchar(512) NULL
                                                          ,lastSyncDateTime datetime2 NOT NULL
                                                          ,preRemediationDetectionScriptOutput nvarchar(max) NULL
                                                          ,remediationScriptError nvarchar(max) NULL
                                                          ,postRemediationDetectionScriptOutput nvarchar(max) NULL
                                                          ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceManagementScripts_deviceRunStates') IS NOT NULL
PRINT 'Table "deviceManagementScripts_deviceRunStates" Created';
GO