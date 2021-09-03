USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.TableColumnMappings

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
05/19/2021    0.0        Benjamin Reynolds        Added mappings for IntuneDevices.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.TableColumnMappings') IS NOT NULL
BEGIN
    DROP TABLE dbo.TableColumnMappings;
    PRINT 'Table "TableColumnMappings" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.TableColumnMappings ( ID int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
                                      ,SchemaName sysname NOT NULL
                                      ,TableName sysname NOT NULL
                                      ,SqlColumnName sysname NOT NULL
                                      ,MappedColumnName nvarchar(256) NOT NULL
                                      ) ON [PRIMARY];
GO
-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.TableColumnMappings') IS NOT NULL
PRINT 'Table "TableColumnMappings" Created';
GO

/*******************************************************************************************
                                Backup Query for the table:
SELECT N',(N'''+SchemaName+N''',N'''+TableName+N''',N'''+SqlColumnName+N''',N'''+MappedColumnName+N''')'
  FROM dbo.TableColumnMappings
 ORDER BY ID;
*******************************************************************************************/
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.TableColumnMappings (SchemaName,TableName,SqlColumnName,MappedColumnName)
VALUES
-- DevicesWithInventory
 (N'dbo',N'DevicesWithInventory',N'DeviceId',N'Device ID')
,(N'dbo',N'DevicesWithInventory',N'DeviceName',N'Device name')
,(N'dbo',N'DevicesWithInventory',N'EnrollmentDate',N'Enrollment date')
,(N'dbo',N'DevicesWithInventory',N'LastCheckIn',N'Last check-in')
,(N'dbo',N'DevicesWithInventory',N'AzureADDeviceId',N'Azure AD Device ID')
,(N'dbo',N'DevicesWithInventory',N'OSVersion',N'OS version')
,(N'dbo',N'DevicesWithInventory',N'AzureADRegistered',N'Azure AD registered')
,(N'dbo',N'DevicesWithInventory',N'EASActivationId',N'EAS activation ID')
,(N'dbo',N'DevicesWithInventory',N'SerialNumber',N'Serial number')
,(N'dbo',N'DevicesWithInventory',N'EASActivated',N'EAS activated')
,(N'dbo',N'DevicesWithInventory',N'LastEASSyncTime',N'Last EAS sync time')
,(N'dbo',N'DevicesWithInventory',N'EAS_Reason',N'EAS reason')
,(N'dbo',N'DevicesWithInventory',N'EAS_Status',N'EAS status')
,(N'dbo',N'DevicesWithInventory',N'ComplianceGracePeriodExpiration',N'Compliance grace period expiration')
,(N'dbo',N'DevicesWithInventory',N'SecurityPatchLevel',N'Security patch level')
,(N'dbo',N'DevicesWithInventory',N'WiFiMAC',N'Wi-Fi MAC')
,(N'dbo',N'DevicesWithInventory',N'SubscriberCarrier',N'Subscriber carrier')
,(N'dbo',N'DevicesWithInventory',N'TotalStorage',N'Total storage')
,(N'dbo',N'DevicesWithInventory',N'FreeStorage',N'Free storage')
,(N'dbo',N'DevicesWithInventory',N'ManagementName',N'Management name')
,(N'dbo',N'DevicesWithInventory',N'EnrolledByUPN',N'Enrolled by user UPN')
,(N'dbo',N'DevicesWithInventory',N'EnrolledByEmail',N'Enrolled by user email address')
,(N'dbo',N'DevicesWithInventory',N'EnrolledByDisplayName',N'Enrolled by user display name')
,(N'dbo',N'DevicesWithInventory',N'ManagedBy',N'Managed by')
,(N'dbo',N'DevicesWithInventory',N'DeviceState',N'Device state')
,(N'dbo',N'DevicesWithInventory',N'IntuneRegistered',N'Intune registered')
,(N'dbo',N'DevicesWithInventory',N'PhoneNumber',N'Phone number')
-- IntuneDevices
,(N'dbo',N'IntuneDevices',N'DeviceId',N'Device ID')
,(N'dbo',N'IntuneDevices',N'DeviceName',N'Device name')
,(N'dbo',N'IntuneDevices',N'EnrollmentDate',N'Enrollment date')
,(N'dbo',N'IntuneDevices',N'LastContact',N'Last check-in')
,(N'dbo',N'IntuneDevices',N'AzureADDeviceId',N'Azure AD Device ID')
,(N'dbo',N'IntuneDevices',N'OSVersion',N'OS version')
,(N'dbo',N'IntuneDevices',N'AzureADRegistered',N'Azure AD registered')
,(N'dbo',N'IntuneDevices',N'EASActivationId',N'EAS activation ID')
,(N'dbo',N'IntuneDevices',N'SerialNumber',N'Serial number')
,(N'dbo',N'IntuneDevices',N'EASActivated',N'EAS activated')
,(N'dbo',N'IntuneDevices',N'LastEASSyncTime',N'Last EAS sync time')
,(N'dbo',N'IntuneDevices',N'EASReason',N'EAS reason')
,(N'dbo',N'IntuneDevices',N'EASStatus',N'EAS status')
,(N'dbo',N'IntuneDevices',N'ComplianceGracePeriodExpiration',N'Compliance grace period expiration')
,(N'dbo',N'IntuneDevices',N'SecurityPatchLevel',N'Security patch level')
,(N'dbo',N'IntuneDevices',N'WifiMacAddress',N'Wi-Fi MAC')
,(N'dbo',N'IntuneDevices',N'SubscriberCarrier',N'Subscriber carrier')
,(N'dbo',N'IntuneDevices',N'TotalStorage',N'Total storage')
,(N'dbo',N'IntuneDevices',N'FreeStorage',N'Free storage')
,(N'dbo',N'IntuneDevices',N'ManagementDeviceName',N'Management name')
,(N'dbo',N'IntuneDevices',N'PrimaryUserId',N'PrimaryUser')
,(N'dbo',N'IntuneDevices',N'EnrolledUPN',N'Primary user UPN')
,(N'dbo',N'IntuneDevices',N'EnrolledUserEmail',N'Primary user email address')
,(N'dbo',N'IntuneDevices',N'EnrolledUserName',N'Primary user display name')
,(N'dbo',N'IntuneDevices',N'ComplianceState',N'Compliance')
,(N'dbo',N'IntuneDevices',N'ManagedBy',N'Managed by')
,(N'dbo',N'IntuneDevices',N'DeviceState',N'Device state')
,(N'dbo',N'IntuneDevices',N'IntuneRegistered',N'Intune registered')
,(N'dbo',N'IntuneDevices',N'PhoneNumber',N'Phone number')
;
PRINT 'Table "TableColumnMappings" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error Populating "TableColumnMappings"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO
