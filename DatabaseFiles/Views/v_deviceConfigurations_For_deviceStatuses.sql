USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceConfigurations_For_deviceStatuses

History:
Date          Version    Author                   Notes:
09/02/2021    0.0        Benjamin Reynolds        Created for external sharing.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceConfigurations_For_deviceStatuses') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceConfigurations_For_deviceStatuses;
    PRINT 'View "v_deviceConfigurations_For_deviceStatuses" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceConfigurations_For_deviceStatuses AS
SELECT  *
  FROM dbo.deviceConfigurations
 WHERE id IN ( N'00000000-0000-0000-0000-000000000000' -- Add ids desired here
              ,N'00000000-0000-0000-0000-000000000001'
              );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceConfigurations_For_deviceStatuses') IS NOT NULL
PRINT 'View "v_deviceConfigurations_For_deviceStatuses" Created';
GO