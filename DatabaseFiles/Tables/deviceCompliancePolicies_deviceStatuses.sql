USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceCompliancePolicies_deviceStatuses

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_deviceStatuses') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceCompliancePolicies_deviceStatuses;
    PRINT 'Table "deviceCompliancePolicies_deviceStatuses" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceCompliancePolicies_deviceStatuses ( ParentId nvarchar(36) NOT NULL
                                                          ,id nvarchar(128) NOT NULL --PRIMARY KEY CLUSTERED??
                                                          ,deviceDisplayName nvarchar(256) NULL
                                                          ,userName nvarchar(256) NULL
                                                          ,deviceModel nvarchar(128) NULL
                                                          ,[platform] int NOT NULL
                                                          ,complianceGracePeriodExpirationDateTime datetime2 NOT NULL
                                                          ,status nvarchar(13) NOT NULL
                                                          ,lastReportedDateTime datetime2 NOT NULL
                                                          ,userPrincipalName nvarchar(128) NULL
                                                          ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_deviceStatuses') IS NOT NULL
PRINT 'Table "deviceCompliancePolicies_deviceStatuses" Created';
GO