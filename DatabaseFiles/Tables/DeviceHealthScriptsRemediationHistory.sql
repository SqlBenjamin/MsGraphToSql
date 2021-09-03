USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DeviceHealthScriptsRemediationHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DeviceHealthScriptsRemediationHistory') IS NOT NULL
BEGIN
    DROP TABLE dbo.DeviceHealthScriptsRemediationHistory;
    PRINT 'Table "DeviceHealthScriptsRemediationHistory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DeviceHealthScriptsRemediationHistory ( Id nvarchar(36) NOT NULL
                                                        --,DisplayName nvarchar(256) NULL
                                                        --,lastModifiedDateTime datetime2 NULL
                                                        ,TheDate date NOT NULL
                                                        ,RemediatedDeviceCount int NOT NULL
                                                        ,NoIssueDeviceCount int NOT NULL
                                                        ,PRIMARY KEY CLUSTERED (Id,TheDate)
                                                        ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DeviceHealthScriptsRemediationHistory') IS NOT NULL
PRINT 'Table "DeviceHealthScriptsRemediationHistory" Created';
GO