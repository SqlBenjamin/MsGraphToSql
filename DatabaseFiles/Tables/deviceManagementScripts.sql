USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceManagementScripts

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceManagementScripts') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceManagementScripts;
    PRINT 'Table "deviceManagementScripts" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceManagementScripts ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                          ,displayName nvarchar(256) NULL
                                          ,description nvarchar(2000) NULL
                                          ,runSchedule_JSON nvarchar(max) NULL
                                          ,scriptContent nvarchar(max) NULL
                                          ,createdDateTime datetime2 NOT NULL
                                          ,lastModifiedDateTime datetime2 NOT NULL
                                          ,runAsAccount nvarchar(6) NOT NULL
                                          ,enforceSignatureCheck bit NOT NULL
                                          ,fileName nvarchar(256) NULL
                                          ,roleScopeTagIds_JSON nvarchar(max) NULL
                                          ,runAs32Bit bit NOT NULL
                                          --,assignments_JSON nvarchar(max) NULL
                                          ,AllData_JSON nvarchar(max) NULL
                                          ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceManagementScripts') IS NOT NULL
PRINT 'Table "deviceManagementScripts" Created';
GO