USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_sharedPCConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_sharedPCConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_sharedPCConfigurations;
    PRINT 'View "v_sharedPCConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_sharedPCConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( accountManagerPolicy_JSON nvarchar(max) '$.accountManagerPolicy' AS JSON
                                                     ,allowedAccounts nvarchar(max) '$.allowedAccounts'
                                                     ,allowLocalStorage bit '$.allowLocalStorage'
                                                     ,disableAccountManager bit '$.disableAccountManager'
                                                     ,disableEduPolicies bit '$.disableEduPolicies'
                                                     ,disablePowerPolicies bit '$.disablePowerPolicies'
                                                     ,disableSignInOnResume bit '$.disableSignInOnResume'
                                                     ,enabled bit '$.enabled'
                                                     ,idleTimeBeforeSleepInSeconds int '$.idleTimeBeforeSleepInSeconds'
                                                     ,kioskAppDisplayName nvarchar(max) '$.kioskAppDisplayName'
                                                     ,kioskAppUserModelId nvarchar(max) '$.kioskAppUserModelId'
                                                     ,maintenanceStartTime datetime2 '$.maintenanceStartTime'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.sharedPCConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_sharedPCConfigurations') IS NOT NULL
PRINT 'View "v_sharedPCConfigurations" Created';
GO