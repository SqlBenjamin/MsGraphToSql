USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WIP_assignmentsInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WIP_assignmentsInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WIP_assignmentsInfo;
    PRINT 'View "v_WIP_assignmentsInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WIP_assignmentsInfo AS
SELECT  wip.id
       ,jsn.GroupAssignmentId
       ,tgt.*
  FROM dbo.mdmWindowsInformationProtectionPolicies wip
       OUTER APPLY OPENJSON (wip.assignments_JSON) WITH ( GroupAssignmentId nvarchar(100) '$.id'
                                                         ,target nvarchar(max) '$.target' AS JSON
                                                         ) jsn
       OUTER APPLY OPENJSON (jsn.target) WITH ( Target_OdataType nvarchar(512) '$."@odata.type"'
                                               ,groupId nvarchar(36) '$.groupId'
                                               ) tgt;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WIP_assignmentsInfo') IS NOT NULL
PRINT 'View "v_WIP_assignmentsInfo" Created';
GO