USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceCompliancePolicies

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceCompliancePolicies;
    PRINT 'Table "deviceCompliancePolicies" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceCompliancePolicies ( odatatype nvarchar(256) NOT NULL
                                           ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                           ,createdDateTime datetime2 NOT NULL
                                           ,description nvarchar(max) NULL
                                           ,lastModifiedDateTime datetime2 NOT NULL
                                           ,displayName nvarchar(256) NOT NULL
                                           ,version int NOT NULL
                                           ,assignments_JSON nvarchar(max) NULL
                                           ,AllData_JSON nvarchar(max) NULL
                                           ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceCompliancePolicies') IS NOT NULL
PRINT 'Table "deviceCompliancePolicies" Created';
GO