USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.PolicyNonComplianceAgg

History:
Date          Version    Author                   Notes:
05/18/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.PolicyNonComplianceAgg') IS NOT NULL
BEGIN
    DROP TABLE dbo.PolicyNonComplianceAgg;
    PRINT 'Table "PolicyNonComplianceAgg" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.PolicyNonComplianceAgg ( PolicyId nvarchar(36) NOT NULL
                                         ,PolicyName nvarchar(512) NOT NULL
                                         ,PolicyType int NOT NULL
                                         ,UnifiedPolicyType nvarchar(128) NOT NULL
                                         ,UnifiedPolicyType_loc nvarchar(128) NOT NULL
                                         ,PolicyBaseTypeName nvarchar(128) NOT NULL
                                         ,PolicyPlatformType int NOT NULL
                                         ,NumberOfNotApplicableDevices int NOT NULL
                                         ,NumberOfCompliantDevices int NOT NULL
                                         ,NumberOfNonCompliantDevices int NOT NULL
                                         ,NumberOfErrorDevices int NOT NULL
                                         ,NumberOfConflictDevices int NOT NULL
                                         ,NumberOfNonCompliantOrErrorDevices int NOT NULL
                                         ,UnifiedPolicyPlatformType nvarchar(128) NOT NULL
                                         ,UnifiedPolicyPlatformType_loc nvarchar(128) NOT NULL
                                         ,TemplateVersion int NOT NULL
                                         ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.PolicyNonComplianceAgg') IS NOT NULL
PRINT 'Table "PolicyNonComplianceAgg" Created';
GO