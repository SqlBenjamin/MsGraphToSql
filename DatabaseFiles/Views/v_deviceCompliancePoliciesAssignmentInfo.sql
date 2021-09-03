USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_deviceCompliancePoliciesAssignmentInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_deviceCompliancePoliciesAssignmentInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_deviceCompliancePoliciesAssignmentInfo;
    PRINT 'View "v_deviceCompliancePoliciesAssignmentInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_deviceCompliancePoliciesAssignmentInfo AS
SELECT  pol.odatatype
       ,pol.id
       ,ass.*
  FROM dbo.deviceCompliancePolicies pol
       OUTER APPLY OPENJSON (pol.assignments_JSON) WITH ( AssignmentId nvarchar(100) '$.id'
                                                         ,TargetOdataType nvarchar(256) '$.target."@odata.type"'
                                                         ,TargetGroupId nvarchar(36) '$.target.groupId'
                                                         ) ass;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_deviceCompliancePoliciesAssignmentInfo') IS NOT NULL
PRINT 'View "v_deviceCompliancePoliciesAssignmentInfo" Created';
GO