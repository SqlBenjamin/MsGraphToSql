USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.devices

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.devices') IS NOT NULL
BEGIN
    DROP TABLE dbo.devices;
    PRINT 'Table "devices" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.devices ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                          ,deletedDateTime datetime2 NULL
                          ,accountEnabled bit NULL
                          ,alternativeSecurityIds_JSON nvarchar(max) NOT NULL
                          ,approximateLastSignInDateTime datetime2 NULL
                          ,complianceExpirationDateTime datetime2 NULL
                          ,deviceId nvarchar(36) NULL
                          ,deviceMetadata nvarchar(max) NULL
                          ,deviceVersion int NULL
                          ,displayName nvarchar(512) NULL
                          ,isCompliant bit NULL
                          ,isManaged bit NULL
                          ,mdmAppId nvarchar(max) NULL
                          ,onPremisesLastSyncDateTime datetime2 NULL
                          ,onPremisesSyncEnabled bit NULL
                          ,operatingSystem nvarchar(256) NULL
                          ,operatingSystemVersion nvarchar(128) NULL
                          ,physicalIds_JSON nvarchar(max) NOT NULL
                          ,profileType nvarchar(256) NOT NULL
                          ,systemLabels_JSON nvarchar(max) NOT NULL
                          ,trustType nvarchar(256) NULL
                          --,memberOf_JSON nvarchar(max) NULL -- NavigationProperty
                          --,registeredOwners_JSON nvarchar(max) NULL -- NavigationProperty
                          --,registeredUsers_JSON nvarchar(max) NULL -- NavigationProperty
                          --,transitiveMemberOf_JSON nvarchar(max) NULL -- NavigationProperty
                          --,extensions_JSON nvarchar(max) NULL -- NavigationProperty
                          ----,registeredOwners_JSON nvarchar(max) NULL -- NavigationPropertyBinding
                          ----,registeredUsers_JSON nvarchar(max) NULL -- NavigationPropertyBinding
                          ----,transitiveMemberOf_JSON nvarchar(max) NULL -- NavigationPropertyBinding
                          );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.devices') IS NOT NULL
PRINT 'Table "devices" Created';
GO

-- Create Indexes:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
DROP INDEX IF EXISTS IX_devices_operatingSystem
  ON dbo.devices;
CREATE NONCLUSTERED INDEX IX_devices_operatingSystem
    ON dbo.devices (operatingSystem)
--INCLUDE (deviceId, accountEnabled, approximateLastSignInDateTime, isCompliant, isManaged, mdmAppId, trustType)
;
PRINT 'Indexes created on "devices".';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error creating indexes on "devices"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO