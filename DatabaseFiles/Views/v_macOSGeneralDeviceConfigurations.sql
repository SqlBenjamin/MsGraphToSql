USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_macOSGeneralDeviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_macOSGeneralDeviceConfigurations') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_macOSGeneralDeviceConfigurations;
    PRINT 'View "v_macOSGeneralDeviceConfigurations" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_macOSGeneralDeviceConfigurations AS
SELECT  cnf.odatatype
       ,cnf.id
       ,lastModifiedDateTime
       ,createdDateTime
       ,description
       ,displayName
       ,version
       ,jsn.*
  FROM dbo.deviceConfigurations cnf
       OUTER APPLY OPENJSON (cnf.AllData_JSON) WITH ( compliantAppsList_JSON nvarchar(max) '$.compliantAppsList' AS JSON
                                                     ,compliantAppListType nvarchar(max) '$.compliantAppListType'
                                                     ,emailInDomainSuffixes_JSON nvarchar(max) '$.emailInDomainSuffixes' AS JSON
                                                     ,passwordBlockSimple bit '$.passwordBlockSimple'
                                                     ,passwordExpirationDays int '$.passwordExpirationDays'
                                                     ,passwordMinimumCharacterSetCount int '$.passwordMinimumCharacterSetCount'
                                                     ,passwordMinimumLength int '$.passwordMinimumLength'
                                                     ,passwordMinutesOfInactivityBeforeLock int '$.passwordMinutesOfInactivityBeforeLock'
                                                     ,passwordMinutesOfInactivityBeforeScreenTimeout int '$.passwordMinutesOfInactivityBeforeScreenTimeout'
                                                     ,passwordPreviousPasswordBlockCount int '$.passwordPreviousPasswordBlockCount'
                                                     ,passwordRequiredType nvarchar(max) '$.passwordRequiredType'
                                                     ,passwordRequired bit '$.passwordRequired'
                                                     ) jsn
 WHERE cnf.odatatype = N'#microsoft.graph.macOSGeneralDeviceConfiguration';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_macOSGeneralDeviceConfigurations') IS NOT NULL
PRINT 'View "v_macOSGeneralDeviceConfigurations" Created';
GO