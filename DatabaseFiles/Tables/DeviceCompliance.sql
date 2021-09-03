USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DeviceCompliance

History:
Date          Version    Author                   Notes:
05/18/2021    0.0        Benjamin Reynolds        Created; same as DeviceNonCompliance.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DeviceCompliance') IS NOT NULL
BEGIN
    DROP TABLE dbo.DeviceCompliance;
    PRINT 'Table "DeviceCompliance" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DeviceCompliance ( DeviceId nvarchar(36) NOT NULL
                                   ,IntuneDeviceId nvarchar(36) NOT NULL
                                   ,AadDeviceId nvarchar(36) NOT NULL
                                   ,PartnerDeviceId nvarchar(128) NULL -- 36??
                                   ,DeviceName nvarchar(128) NULL
                                   ,DeviceType tinyint NOT NULL
                                   ,OSDescription nvarchar(128) NULL
                                   ,OSVersion nvarchar(50) NULL
                                   ,OwnerType tinyint NOT NULL
                                   ,OwnerType_loc nvarchar(64) NOT NULL
                                   ,LastContact datetime2 NOT NULL
                                   ,InGracePeriodUntil datetime2 NOT NULL
                                   ,IMEI nvarchar(128) NULL
                                   ,SerialNumber nvarchar(128) NULL
                                   ,PrimaryUser nvarchar(36) NULL
                                   ,UserId nvarchar(36) NULL
                                   ,UPN nvarchar(128) NULL
                                   ,UserEmail nvarchar(256) NULL
                                   ,UserName nvarchar(256) NULL
                                   ,DeviceHealthThreatLevel tinyint NULL
                                   ,DeviceHealthThreatLevel_loc nvarchar(64) NOT NULL
                                   ,RetireAfterDatetime datetime2 NULL
                                   ,ComplianceState tinyint NOT NULL
                                   ,ComplianceState_loc nvarchar(64) NOT NULL
                                   ,OS nvarchar(64) NOT NULL
                                   ,OS_loc nvarchar(64) NOT NULL
                                   ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DeviceCompliance') IS NOT NULL
PRINT 'Table "DeviceCompliance" Created';
GO