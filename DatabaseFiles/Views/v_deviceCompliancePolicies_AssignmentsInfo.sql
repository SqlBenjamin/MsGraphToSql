USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceCompliancePolicies_AssignmentsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceCompliancePolicies_AssignmentsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceCompliancePolicies_AssignmentsInfo;
    PRINT 'View "v_deviceCompliancePolicies_AssignmentsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceCompliancePolicies_AssignmentsInfo AS
SELECT  cpa.ParentOdataType AS [CompliancePolicyOdataType]
       ,cpa.ParentId AS [CompliancePolicyId]
       ,cpa.id AS [AssignmentId]
       ,tgt.*
  FROM dbo.deviceCompliancePolicies_assignments cpa
       OUTER APPLY OPENJSON (cpa.target_JSON) WITH ( TargetOdataType nvarchar(256) '$."@odata.type"'
                                                    ,TargetGroupId nvarchar(36) '$.groupId'
                                                    ) tgt;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceCompliancePolicies_AssignmentsInfo') IS NOT NULL
PRINT 'View "v_deviceCompliancePolicies_AssignmentsInfo" Created';
GO