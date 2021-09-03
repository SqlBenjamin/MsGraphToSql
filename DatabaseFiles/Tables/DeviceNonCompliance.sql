USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DeviceNonCompliance

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DeviceNonCompliance') IS NOT NULL
BEGIN
    DROP TABLE dbo.DeviceNonCompliance;
    PRINT 'Table "DeviceNonCompliance" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DeviceNonCompliance ( DeviceId nvarchar(36) NOT NULL
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
PRINT 'Table "DeviceNonCompliance" Created';
GO