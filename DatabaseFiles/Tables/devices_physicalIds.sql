USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.devices_physicalIds

Note: This table isn't populated by the Sync Script but rather by a procedure shredding data from devices:

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.devices_physicalIds') IS NOT NULL
BEGIN
    DROP TABLE dbo.devices_physicalIds;
    PRINT 'Table "devices_physicalIds" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.devices_physicalIds ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                      ,deviceId nvarchar(36) NOT NULL
                                      ,GID nvarchar(18) NULL
                                      ,HWID nvarchar(18) NULL
                                      ,OrderId nvarchar(25) NULL
                                      ,PurchaseOrderId nvarchar(100) NULL
                                      ,ZTDID nvarchar(36) NULL
                                      ,AzureResourceId nvarchar(256) NULL
                                      ,SHA256_GID nvarchar(64) NULL
                                      ,SHA256_HWID nvarchar(64) NULL
                                      ,SHA256_USER_GID nvarchar(64) NULL
                                      ,SHA256_USER_HWID nvarchar(64) NULL
                                      ,USER_GID nvarchar(53) NULL
                                      ,USER_HWID nvarchar(53) NULL
                                      );
GO
-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.devices_physicalIds') IS NOT NULL
PRINT 'Table "devices_physicalIds" Created';
GO

-- Create Indexes:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
DROP INDEX IF EXISTS IX_devices_physicalIds_ZtId
  ON dbo.devices_physicalIds;
CREATE NONCLUSTERED INDEX IX_devices_physicalIds_ZtId
    ON dbo.devices_physicalIds (ZTDID)
INCLUDE (GID,HWID,OrderId,PurchaseOrderId);
PRINT 'Indexes created on "devices_physicalIds"';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error creating indexes on "devices_physicalIds"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO