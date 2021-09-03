USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DeviceRunStatesByProactiveRemediation

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DeviceRunStatesByProactiveRemediation') IS NOT NULL
BEGIN
    DROP TABLE dbo.DeviceRunStatesByProactiveRemediation;
    PRINT 'Table "DeviceRunStatesByProactiveRemediation" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DeviceRunStatesByProactiveRemediation ( PolicyId nvarchar(36) NOT NULL
                                                        ,DeviceId nvarchar(36) NOT NULL
                                                        ,UserId nvarchar(36) NOT NULL
                                                        ,InternalVersion int NULL
                                                        ,ModifiedTime datetime2 NULL
                                                        ,PostRemediationDetectionScriptError nvarchar(max) NULL
                                                        ,PostRemediationDetectionScriptOutput nvarchar(max) NULL
                                                        ,PreRemediationDetectionScriptError nvarchar(max) NULL
                                                        ,PreRemediationDetectionScriptOutput nvarchar(max) NULL
                                                        ,RemediationScriptErrorDetails nvarchar(max) NULL
                                                        ,RemediationStatus int NULL
                                                        ,DeviceName nvarchar(128) NULL -- 256
                                                        ,OSVersion nvarchar(128) NULL -- 128
                                                        ,UPN nvarchar(128) NULL -- 4000
                                                        ,UserEmail nvarchar(128) NULL -- 320
                                                        ,UserName nvarchar(128) NULL -- 4000
                                                        ,DetectionStatus int NULL
                                                        ,UniqueKustoKey nvarchar(150) NULL
                                                        ,DetectionScriptStatus nvarchar(128) NOT NULL
                                                        ,RemediationScriptStatus nvarchar(128) NOT NULL
                                                        ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DeviceRunStatesByProactiveRemediation') IS NOT NULL
PRINT 'Table "DeviceRunStatesByProactiveRemediation" Created';
GO