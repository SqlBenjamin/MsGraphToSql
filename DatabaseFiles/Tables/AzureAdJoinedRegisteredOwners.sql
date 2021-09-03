USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.AzureAdJoinedRegisteredOwners

History:
Date          Version    Author                   Notes:
06/10/2021    0.0        Benjamin Reynolds        Created.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.AzureAdJoinedRegisteredOwners') IS NOT NULL
BEGIN
    DROP TABLE dbo.AzureAdJoinedRegisteredOwners;
    PRINT 'Table "AzureAdJoinedRegisteredOwners" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.AzureAdJoinedRegisteredOwners ( id nvarchar(36) NOT NULL
                                                ,deviceId nvarchar(36) NOT NULL
                                                ,registeredOwners_JSON nvarchar(max) NULL
                                                ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.AzureAdJoinedRegisteredOwners') IS NOT NULL
PRINT 'Table "AzureAdJoinedRegisteredOwners" Created';
GO