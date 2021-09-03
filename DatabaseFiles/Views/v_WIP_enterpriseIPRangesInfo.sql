USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_WIP_enterpriseIPRangesInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_WIP_enterpriseIPRangesInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_WIP_enterpriseIPRangesInfo;
    PRINT 'View "v_WIP_enterpriseIPRangesInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_WIP_enterpriseIPRangesInfo AS
SELECT  wip.id
       ,jsn.displayName --AS [enterpriseIPRangeDisplayName]
       --,jsn.ranges
       ,rng.*
  FROM dbo.mdmWindowsInformationProtectionPolicies wip
       OUTER APPLY OPENJSON (wip.enterpriseIPRanges_JSON) WITH ( displayName nvarchar(max) '$.displayName'
                                                                ,ranges nvarchar(max) '$.ranges' AS JSON
                                                                ) jsn
       OUTER APPLY OPENJSON (jsn.ranges) WITH (IPRange_OdataType nvarchar(512) '$."@odata.type"'
                                               ,lowerAddress nvarchar(max) '$.lowerAddress'
                                               ,upperAddress nvarchar(max) '$.upperAddress'
                                               ) rng;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_WIP_enterpriseIPRangesInfo') IS NOT NULL
PRINT 'View "v_WIP_enterpriseIPRangesInfo" Created';
GO