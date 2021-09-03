USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DevicesWithInventory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DevicesWithInventory') IS NOT NULL
BEGIN
    DROP TABLE dbo.DevicesWithInventory;
    PRINT 'Table "DevicesWithInventory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DevicesWithInventory ( DeviceId nvarchar(36) NOT NULL --[Device ID] nvarchar(36) NOT NULL
                                       ,DeviceName nvarchar(128) NOT NULL --,[Device name] nvarchar(128) NOT NULL
                                       ,EnrollmentDate datetime2 NULL --,[Enrollment date] datetime2 NULL
                                       ,LastCheckIn datetime2 NULL --,[Last check-in] datetime2 NULL
                                       ,AzureADDeviceId nvarchar(36) NULL --,[Azure AD Device ID] nvarchar(36) NULL
                                       ,OSVersion nvarchar(32) NULL --,[OS version] nvarchar(128) NULL
                                       ,AzureADRegistered bit NULL --,[Azure AD registered] bit NULL
                                       ,EASActivationId nvarchar(64) NULL --,[EAS activation ID] nvarchar(36) NULL
                                       ,SerialNumber nvarchar(64) NULL --,[Serial number] nvarchar(128) NULL
                                       ,Manufacturer nvarchar(64) NULL
                                       ,Model nvarchar(128) NULL
                                       ,EASActivated bit NULL --,[EAS activated] bit NULL
                                       ,IMEI nvarchar(32) NULL
                                       ,LastEASSyncTime datetime2 NULL --,[Last EAS sync time] datetime2 NULL
                                       ,EAS_Reason nvarchar(64) NULL --,[EAS reason] nvarchar(64) NULL
                                       ,EAS_Status nvarchar(64) NULL --,[EAS status] nvarchar(64) NULL
                                       ,ComplianceGracePeriodExpiration datetime2 NULL --,[Compliance grace period expiration] datetime2 NULL
                                       ,SecurityPatchLevel nvarchar(32) NULL --,[Security patch level] nvarchar(64) NULL
                                       ,WiFiMAC nvarchar(32) NULL --,[Wi-Fi MAC] nvarchar(36) NULL
                                       ,MEID nvarchar(32) NULL
                                       ,SubscriberCarrier nvarchar(64) NULL --,[Subscriber carrier] nvarchar(64) NULL
                                       ,TotalStorage int NULL --,[Total storage] int NULL
                                       ,FreeStorage int NULL --,[Free storage] int NULL
                                       ,ManagementName nvarchar(64) NULL --,[Management name] nvarchar(64) NULL
                                       ,Category nvarchar(64) NULL
                                       ,UserId nvarchar(36) NULL
                                       ,EnrolledByUPN nvarchar(128) NULL --,[Enrolled by user UPN] nvarchar(128) NULL
                                       ,EnrolledByEmail nvarchar(128) NULL --,[Enrolled by user email address] nvarchar(128) NULL
                                       ,EnrolledByDisplayName nvarchar(128) NULL --,[Enrolled by user display name] nvarchar(128) NULL
                                       ,WiFiIPv4Address nvarchar(128) NULL
                                       ,WiFiSubnetID nvarchar(32) NULL
                                       ,Compliance nvarchar(32) NULL
                                       ,ManagedBy nvarchar(64) NULL --,[Managed by] nvarchar(64) NULL
                                       ,Ownership nvarchar(32) NULL
                                       ,DeviceState nvarchar(32) NULL --,[Device state] nvarchar(64) NULL
                                       ,IntuneRegistered nvarchar(32) NULL --,[Intune registered] nvarchar(64) NULL
                                       ,Supervised bit NULL
                                       ,Encrypted bit NULL
                                       ,OS nvarchar(64) NULL
                                       ,SkuFamily nvarchar(32) NULL
                                       ,JoinType nvarchar(32) NULL
                                       ,PhoneNumber nvarchar(32) NULL --,[Phone number] nvarchar(64) NULL
                                       ,Jailbroken nvarchar(32) NULL
                                       ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DevicesWithInventory') IS NOT NULL
PRINT 'Table "DevicesWithInventory" Created';
GO