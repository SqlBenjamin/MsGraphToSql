USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DetectedAppsAggregate

History:
Date          Version    Author                   Notes:
05/18/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DetectedAppsAggregate') IS NOT NULL
BEGIN
    DROP TABLE dbo.DetectedAppsAggregate;
    PRINT 'Table "DetectedAppsAggregate" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DetectedAppsAggregate ( ApplicationKey nvarchar(64) NOT NULL
                                        ,ApplicationName nvarchar(256) NULL
                                        ,ApplicationVersion nvarchar(64) NULL
                                        ,DeviceCount int NULL
                                        ,BundleSize bigint NULL
                                        ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DetectedAppsAggregate') IS NOT NULL
PRINT 'Table "DetectedAppsAggregate" Created';
GO