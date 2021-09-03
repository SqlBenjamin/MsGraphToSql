USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory

History:
Date          Version    Author                   Notes:
07/30/2021    0.0        Benjamin Reynolds        Created.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory') IS NOT NULL
BEGIN
    DROP TABLE dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory;
    PRINT 'Table "DeviceCompliancePoliciesDeviceStatusOverviewHistory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory ( Id nvarchar(36) NOT NULL
                                                                      ,CaptureDateUTC date NOT NULL
                                                                      ,PendingCount int NOT NULL
                                                                      ,NotApplicableCount int NOT NULL
                                                                      ,SuccessCount int NOT NULL
                                                                      ,ErrorCount int NOT NULL
                                                                      ,FailedCount int NOT NULL
                                                                      ,LastUpdateDateTime datetime2 NOT NULL
                                                                      ,ConfigurationVersion int NOT NULL
                                                                      ,PRIMARY KEY CLUSTERED (Id,CaptureDateUTC)
                                                                      ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.DeviceCompliancePoliciesDeviceStatusOverviewHistory') IS NOT NULL
PRINT 'Table "DeviceCompliancePoliciesDeviceStatusOverviewHistory" Created';
GO