USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_IntuneHybridAadjOwners

History:
Date          Version    Author                   Notes:
06/10/2021    0.0        Benjamin Reynolds        Created for Kubilay. Temporary view?

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_IntuneHybridAadjOwners') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_IntuneHybridAadjOwners;
    PRINT 'View "v_IntuneHybridAadjOwners" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_IntuneHybridAadjOwners AS
SELECT *
  FROM managedDevices
 WHERE joinType = N'hybridAzureADJoined'
   AND userId IS NOT NULL
   AND lastSyncDateTime > DATEADD(day,-20, GETDATE());
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_IntuneHybridAadjOwners') IS NOT NULL
PRINT 'View "v_IntuneHybridAadjOwners" Created';
GO