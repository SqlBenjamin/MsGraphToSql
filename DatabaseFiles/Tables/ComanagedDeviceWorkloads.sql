USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.ComanagedDeviceWorkloads

History:
Date          Version    Author                   Notes:
05/18/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.ComanagedDeviceWorkloads') IS NOT NULL
BEGIN
    DROP TABLE dbo.ComanagedDeviceWorkloads;
    PRINT 'Table "ComanagedDeviceWorkloads" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.ComanagedDeviceWorkloads ( DeviceId nvarchar(36) NOT NULL
                                           ,DeviceName nvarchar(128) NULL
                                           ,DeviceType tinyint NOT NULL
                                           ,ClientRegistrationStatus int NOT NULL
                                           ,LastContact datetime2 NOT NULL
                                           ,ReferenceId nvarchar(36) NOT NULL
                                           ,SCCMCoManagementFeatures int NOT NULL
                                           ,UPN nvarchar(128) NULL
                                           ,UserEmail nvarchar(256) NULL
                                           ,UserName nvarchar(256) NULL
                                           ,OS nvarchar(64) NOT NULL
                                           ,ComplianceState tinyint NOT NULL
                                           ,IsDeviceActive bit NOT NULL
                                           ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.ComanagedDeviceWorkloads') IS NOT NULL
PRINT 'Table "ComanagedDeviceWorkloads" Created';
GO