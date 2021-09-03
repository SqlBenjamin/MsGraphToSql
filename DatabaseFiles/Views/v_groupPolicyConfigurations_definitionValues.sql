USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_groupPolicyConfigurations_definitionValues

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurations_definitionValues') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_groupPolicyConfigurations_definitionValues;
    PRINT 'View "v_groupPolicyConfigurations_definitionValues" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_groupPolicyConfigurations_definitionValues AS
SELECT  dfv.ParentId
       ,dfv.id
       ,dfv.createdDateTime
       ,dfv.enabled
       ,dfv.configurationType
       ,dfv.lastModifiedDateTime
       ,jsn.definitionId
       ,jsn.definitionDisplayName
       ,jsn.definitionClassType
       ,jsn.definitionExplainText
       ,jsn.definitionCategoryPath
       ,jsn.definitionSupportedOn
       ,jsn.definitionPolicyType
       ,jsn.definitionLastModifiedDateTime
  FROM dbo.groupPolicyConfigurations_definitionValues dfv
       OUTER APPLY OPENJSON (dfv.definition_JSON) WITH ( definitionId nvarchar(36) '$.id'
                                                        ,definitionDisplayName nvarchar(256) '$.displayName'
                                                        ,definitionClassType nvarchar(7) '$.classType'
                                                        ,definitionExplainText nvarchar(256) '$.explainText'
                                                        ,definitionCategoryPath nvarchar(256) '$.categoryPath'
                                                        ,definitionSupportedOn nvarchar(256) '$.supportedOn'
                                                        ,definitionPolicyType nvarchar(12) '$.policyType'
                                                        ,definitionLastModifiedDateTime datetime2 '$.lastModifiedDateTime'
                                                        ) jsn;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurations_definitionValues') IS NOT NULL
PRINT 'View "v_groupPolicyConfigurations_definitionValues" Created';
GO