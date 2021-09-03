USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.Windows10CompliancePolicy_deviceStatuses

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.Windows10CompliancePolicy_deviceStatuses') IS NOT NULL
BEGIN
    DROP TABLE dbo.Windows10CompliancePolicy_deviceStatuses;
    PRINT 'Table "Windows10CompliancePolicy_deviceStatuses" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.Windows10CompliancePolicy_deviceStatuses ( ParentOdataType nvarchar(max) NOT NULL
                                                           ,ParentId nvarchar(max) NOT NULL
                                                           ,id nvarchar(max) NOT NULL
                                                           ,deviceDisplayName nvarchar(max) NULL
                                                           ,userName nvarchar(max) NULL
                                                           ,deviceModel nvarchar(max) NULL
                                                           ,platform int NOT NULL
                                                           ,complianceGracePeriodExpirationDateTime datetime2(7) NOT NULL
                                                           ,STATUS nvarchar(13) NOT NULL
                                                           ,lastReportedDateTime datetime2(7) NOT NULL
                                                           ,userPrincipalName nvarchar(max) NULL
                                                           ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.Windows10CompliancePolicy_deviceStatuses') IS NOT NULL
PRINT 'Table "Windows10CompliancePolicy_deviceStatuses" Created';
GO