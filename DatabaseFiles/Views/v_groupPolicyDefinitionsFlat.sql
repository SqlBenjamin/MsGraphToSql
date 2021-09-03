USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_groupPolicyDefinitionsFlat

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_groupPolicyDefinitionsFlat') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_groupPolicyDefinitionsFlat;
    PRINT 'View "v_groupPolicyDefinitionsFlat" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_groupPolicyDefinitionsFlat AS
SELECT  gpd.id AS [GroupPolicyDefinitionId]
       ,gpd.classType
       ,gpd.displayName
       ,gpd.explainText
       ,gpd.categoryPath
       ,gpd.supportedOn
       ,gpd.policyType
       ,gpd.lastModifiedDateTime
       ,def.id AS [DefinitionFileId]
       ,def.displayName AS [DefinitionFileDisplayName]
       ,def.description AS [DefinitionFileDescription]
       ,def.languageCodes_JSON AS [DefinitionFileLanguageCodesJson]
       ,def.targetPrefix AS [DefinitionFileTargetPrefix]
       ,def.targetNamespace AS [DefinitionFileTargetNamespace]
       ,def.policyType AS [DefinitionFilePolicyType]
       ,def.revision AS [DefinitionFileRevision]
       ,def.lastModifiedDateTime AS [DefinitionFileLastModifiedDateTime]
  FROM dbo.groupPolicyDefinitions gpd
       INNER JOIN dbo.groupPolicyDefinitions_definitionFile def
          ON gpd.id = def.ParentId;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_groupPolicyDefinitionsFlat') IS NOT NULL
PRINT 'View "v_groupPolicyDefinitionsFlat" Created';
GO