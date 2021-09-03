USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceCompliancePolicies_userStatusOverview

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_userStatusOverview') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceCompliancePolicies_userStatusOverview;
    PRINT 'Table "deviceCompliancePolicies_userStatusOverview" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceCompliancePolicies_userStatusOverview ( ParentId nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                                              ,id nvarchar(73) NOT NULL
                                                              ,pendingCount int NOT NULL
                                                              ,notApplicableCount int NOT NULL
                                                              ,successCount int NOT NULL
                                                              ,errorCount int NOT NULL
                                                              ,failedCount int NOT NULL
                                                              ,lastUpdateDateTime datetime2 NOT NULL
                                                              ,configurationVersion int NOT NULL
                                                              ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies_userStatusOverview') IS NOT NULL
PRINT 'Table "deviceCompliancePolicies_userStatusOverview" Created';
GO