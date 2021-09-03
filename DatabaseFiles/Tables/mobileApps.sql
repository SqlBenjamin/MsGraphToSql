USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileApps

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileApps') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileApps;
    PRINT 'Table "mobileApps" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileApps ( odatatype nvarchar(256) NOT NULL
                             ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                             ,displayName nvarchar(256) NULL
                             ,description nvarchar(max) NULL
                             ,publisher nvarchar(256) NULL
                             ,largeIcon_JSON nvarchar(max) NULL
                             ,createdDateTime datetime2 NOT NULL
                             ,lastModifiedDateTime datetime2 NOT NULL
                             ,isFeatured bit NOT NULL
                             ,privacyInformationUrl nvarchar(512) NULL
                             ,informationUrl nvarchar(512) NULL
                             ,owner nvarchar(128) NULL
                             ,developer nvarchar(256) NULL
                             ,notes nvarchar(512) NULL
                             ,publishingState nvarchar(50) NOT NULL
                             --,categories_JSON nvarchar(max) NULL
                             ,assignments_JSON nvarchar(max) NULL
                             ,expirationDateTime datetime2 NULL
                             ,version nvarchar(25) NULL -- derived from managedApp
                             ,identityVersion nvarchar(25) NULL -- derived from managedMobileLobApp
                             ,productVersion nvarchar(25) NULL -- derived from managedMobileLobApp
                             ,commandLine nvarchar(max) NULL -- derived from windowsMobileMSI type apps
                             ,AllData_JSON nvarchar(max) NULL
                             ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mobileApps') IS NOT NULL
PRINT 'Table "mobileApps" Created';
GO