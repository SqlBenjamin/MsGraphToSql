USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.WiFiConfigurations_deviceStatuses

History:
Date          Version    Author                   Notes:
05/21/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.WiFiConfigurations_deviceStatuses') IS NOT NULL
BEGIN
    DROP TABLE dbo.WiFiConfigurations_deviceStatuses;
    PRINT 'Table "WiFiConfigurations_deviceStatuses" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.WiFiConfigurations_deviceStatuses ( ParentId nvarchar(36) NOT NULL
                                                    ,id nvarchar(128) NOT NULL
                                                    ,deviceDisplayName nvarchar(64) NULL --256
                                                    ,userName nvarchar(64) NULL --256
                                                    ,deviceModel nvarchar(64) NULL --128
                                                    ,[platform] int NOT NULL
                                                    ,complianceGracePeriodExpirationDateTime datetime2 NOT NULL
                                                    ,status nvarchar(13) NOT NULL
                                                    ,lastReportedDateTime datetime2 NOT NULL
                                                    ,userPrincipalName nvarchar(64) NULL --128
                                                    ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.WiFiConfigurations_deviceStatuses') IS NOT NULL
PRINT 'Table "WiFiConfigurations_deviceStatuses" Created';
GO