USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WiFiConfigurations

History:
Date          Version    Author                   Notes:
06/16/2021    0.0        Benjamin Reynolds        File created.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WiFiConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WiFiConfigurations;
    PRINT 'View "v_WiFiConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WiFiConfigurations AS
SELECT *
  FROM dbo.deviceConfigurations
 WHERE odatatype LIKE N'#microsoft.graph.%Wifi%Configuration%';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WiFiConfigurations') IS NOT NULL
PRINT 'View "v_WiFiConfigurations" Created';
GO