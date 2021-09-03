USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.WindowsAutopilotDeploymentProfiles

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.WindowsAutopilotDeploymentProfiles') IS NOT NULL
BEGIN
    DROP TABLE dbo.WindowsAutopilotDeploymentProfiles;
    PRINT 'Table "WindowsAutopilotDeploymentProfiles" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.WindowsAutopilotDeploymentProfiles ( odatatype nvarchar(256) NOT NULL
                                                     ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                     ,displayName nvarchar(256) NULL
                                                     ,description nvarchar(512) NULL
                                                     ,language nvarchar(50) NULL
                                                     ,createdDateTime datetime2 NOT NULL
                                                     ,lastModifiedDateTime datetime2 NOT NULL
                                                     ,outOfBoxExperienceSettings_JSON nvarchar(max) NULL
                                                     ,enrollmentStatusScreenSettings_JSON nvarchar(max) NULL
                                                     ,extractHardwareHash bit NOT NULL
                                                     ,deviceNameTemplate nvarchar(256) NULL
                                                     ,assignments_JSON nvarchar(max) NULL
                                                     ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.WindowsAutopilotDeploymentProfiles') IS NOT NULL
PRINT 'Table "WindowsAutopilotDeploymentProfiles" Created';
GO