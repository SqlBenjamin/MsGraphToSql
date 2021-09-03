USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.autopilotEvents

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.autopilotEvents') IS NOT NULL
BEGIN
    DROP TABLE dbo.autopilotEvents;
    PRINT 'Table "autopilotEvents" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.autopilotEvents ( id nvarchar(46) NOT NULL --was 36 but they added "autopilot_" to each GUID (facepalm)
                                  ,deviceId nvarchar(36) NULL
                                  ,eventDateTime datetime2 NOT NULL
                                  ,deviceRegisteredDateTime datetime2 NOT NULL
                                  ,enrollmentStartDateTime datetime2 NOT NULL
                                  ,enrollmentType nvarchar(51) NOT NULL
                                  ,deviceSerialNumber nvarchar(64) NULL
                                  ,managedDeviceName nvarchar(256) NULL
                                  ,userPrincipalName nvarchar(256) NULL
                                  ,windowsAutopilotDeploymentProfileDisplayName nvarchar(256) NULL
                                  ,enrollmentState nvarchar(12) NOT NULL
                                  ,windows10EnrollmentCompletionPageConfigurationDisplayName nvarchar(256) NULL
                                  ,deploymentState nvarchar(18) NOT NULL
                                  ,osVersion nvarchar(40) NULL
                                  ,deploymentDuration nvarchar(25) NOT NULL
                                  ,deploymentTotalDuration nvarchar(25) NOT NULL
                                  ,devicePreparationDuration nvarchar(25) NOT NULL
                                  ,deviceSetupDuration nvarchar(25) NOT NULL
                                  ,accountSetupDuration nvarchar(25) NOT NULL
                                  ,deploymentStartDateTime datetime2 NOT NULL
                                  ,deploymentEndDateTime datetime2 NOT NULL
                                  ,targetedAppCount int NOT NULL
                                  ,targetedPolicyCount int NOT NULL
                                  ,enrollmentFailureDetails nvarchar(256) NULL
                                  ,policyStatusDetails_JSON nvarchar(max) NULL
                                  ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.autopilotEvents') IS NOT NULL
PRINT 'Table "autopilotEvents" Created';
GO