USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.IntuneDevices

History:
Date          Version    Author                   Notes:
05/19/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.IntuneDevices') IS NOT NULL
BEGIN
    DROP TABLE dbo.IntuneDevices;
    PRINT 'Table "IntuneDevices" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.IntuneDevices ( DeviceId nvarchar(36) NULL
                                ,DeviceName nvarchar(128) NULL
                                ,DeviceType int NULL
                                ,ClientRegistrationStatus int NULL
                                ,OwnerType int NULL
                                ,EnrollmentDate datetime2 NULL
                                ,LastContact datetime2 NULL
                                ,ManagementAgents int NULL
                                ,ManagementState int NULL
                                ,AzureADDeviceId nvarchar(36) NULL
                                ,CategoryId nvarchar(36) NULL
                                ,EnrollmentType int NULL
                                ,CertExpirationDate datetime2 NULL
                                ,MDMStatus tinyint NULL
                                ,OSVersion nvarchar(32) NULL --18
                                ,AzureADRegistered bit NULL
                                ,EASActivationId nvarchar(50) NULL --40
                                ,SerialNumber nvarchar(64) NULL
                                ,EnrolledByUser nvarchar(36) NULL
                                ,Manufacturer nvarchar(64) NULL --49
                                ,Model nvarchar(128) NULL --83
                                ,IsManaged bit NULL
                                ,EASActivated bit NULL
                                ,IMEI nvarchar(25) NULL --17
                                ,LastEASSyncTime datetime2 NULL
                                ,EASReason nvarchar(64) NULL
                                ,EASStatus nvarchar(64) NULL
                                ,EncryptionStatus int NULL
                                ,SupervisedStatus int NULL
                                ,ComplianceGracePeriodExpiration datetime2 NULL
                                ,SecurityPatchLevel nvarchar(15) NULL --10
                                ,WifiMacAddress nvarchar(25) NULL --12
                                ,SCCMCoManagementFeatures int NULL
                                ,MEID nvarchar(32) NULL --16
                                ,SubscriberCarrier nvarchar(64) NULL --41
                                ,TotalStorage bigint NULL
                                ,FreeStorage bigint NULL
                                ,ManagementDeviceName nvarchar(64) NULL --64
                                ,LastLoggedOnUserUPN nvarchar(max) NULL
                                ,MDMWinsOverGPStartTime datetime2 NULL
                                ,StagedDeviceType int NULL
                                ,UserApprovedEnrollment int NULL
                                ,ExtendedProperties nvarchar(256) NULL --182
                                ,EntitySource int NULL
                                ,Category nvarchar(64) NULL
                                ,PrimaryUserId nvarchar(36) NULL
                                ,UserId nvarchar(36) NULL
                                ,EnrolledUPN nvarchar(64) NULL --62
                                ,EnrolledUserEmail nvarchar(64) NULL --43
                                ,EnrolledUserName nvarchar(128) NULL --89
                                ,RetireAfterDatetime datetime2 NULL
                                ,HasUnlockToken bit NULL
                                ,ComplianceState nvarchar(25) NULL --13
                                ,ManagedBy nvarchar(25) NULL --10
                                ,Ownership nvarchar(9) NULL --9
                                ,DeviceState nvarchar(25) NULL --13
                                ,IntuneRegistered nvarchar(25) NULL --15
                                ,Supervised bit NULL
                                ,Encrypted bit NULL
                                ,OS nvarchar(64) NULL --30
                                ,SkuFamily nvarchar(32) NULL --22
                                ,SkuNumber int NULL
                                ,JoinType nvarchar(32) NULL --22
                                ,PhoneNumber nvarchar(32) NULL --20
                                ,Jailbroken nvarchar(25) NULL --7
                                ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.IntuneDevices') IS NOT NULL
PRINT 'Table "IntuneDevices" Created';
GO