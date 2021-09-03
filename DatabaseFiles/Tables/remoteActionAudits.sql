USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.remoteActionAudits

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.remoteActionAudits') IS NOT NULL
BEGIN
    DROP TABLE dbo.remoteActionAudits;
    PRINT 'Table "remoteActionAudits" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.remoteActionAudits ( id nvarchar(36) NOT NULL
                                     ,action nvarchar(33) NOT NULL
                                     ,actionState nvarchar(12) NOT NULL
                                     ,deviceDisplayName nvarchar(64) NULL
                                     ,deviceIMEI nvarchar(25) NULL
                                     ,deviceOwnerUserPrincipalName nvarchar(64) NULL
                                     ,initiatedByUserPrincipalName nvarchar(64) NULL
                                     ,managedDeviceId nvarchar(36) NULL
                                     ,requestDateTime datetime2(7) NOT NULL
                                     ,userName nvarchar(64) NULL
                                     ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.remoteActionAudits') IS NOT NULL
PRINT 'Table "remoteActionAudits" Created';
GO