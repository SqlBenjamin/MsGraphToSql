USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceHealthScripts_getRemediationHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceHealthScripts_getRemediationHistory') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceHealthScripts_getRemediationHistory;
    PRINT 'Table "deviceHealthScripts_getRemediationHistory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceHealthScripts_getRemediationHistory ( ParentId nvarchar(36) NOT NULL
                                                            ,lastModifiedDateTime datetime2 NULL
                                                            ,historyData_JSON nvarchar(max) NULL
                                                            --,[date] date NOT NULL
                                                            --,remediatedDeviceCount int NOT NULL
                                                            --,noIssueDeviceCount int NOT NULL
                                                            ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceHealthScripts_getRemediationHistory') IS NOT NULL
PRINT 'Table "deviceHealthScripts_getRemediationHistory" Created';
GO