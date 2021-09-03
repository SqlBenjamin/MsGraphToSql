USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_macOSCustomConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_macOSCustomConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_macOSCustomConfigurations;
    PRINT 'View "v_macOSCustomConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_macOSCustomConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( payloadName nvarchar(max) '$.payloadName'
                                                     ,payloadFileName nvarchar(max) '$.payloadFileName'
                                                     ,payload nvarchar(max) '$.payload'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.macOSCustomConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_macOSCustomConfigurations') IS NOT NULL
PRINT 'View "v_macOSCustomConfigurations" Created';
GO