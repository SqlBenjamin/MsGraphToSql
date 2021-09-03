USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_groupPolicyConfigurations_PresentationInformation

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurations_PresentationInformation') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_groupPolicyConfigurations_PresentationInformation;
    PRINT 'View "v_groupPolicyConfigurations_PresentationInformation" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_groupPolicyConfigurations_PresentationInformation AS
SELECT  gpc.id AS [groupPolicyConfigurationId]
       ,gpc.displayName
       ,gpc.description
       ,gpc.createdDateTime
       ,gpc.lastModifiedDateTime
       ,pdv.id AS [definitionValueId]
       ,pdv.configurationType AS [definitionValue_configurationType]
       ,pdv.enabled AS [definitionValue_enabled]
       ,pdv.createdDateTime AS [definitionValue_createdDateTime]
       ,pdv.lastModifiedDateTime AS [definitionValue_lastModifiedDateTime]
       ,pdv.definitionId
       ,pdv.definitionDisplayName
       ,pdv.definitionClassType
       ,pdv.definitionExplainText
       ,pdv.definitionCategoryPath
       ,pdv.definitionSupportedOn
       ,pdv.definitionPolicyType
       ,pdv.definitionLastModifiedDateTime
       ,pvs.id AS [presentationValueId]
       ,pvs.lastModifiedDateTime AS [presentationValue_lastModifiedDateTime]
       ,pvs.createdDateTime AS [presentationValue_createdDateTime]
       ,pvs.value AS [presentationValue_value]
       ,pvs.presentationId
       ,pvs.presentation_odatatype
       ,pvs.label AS [presentation_label]
       ,pvs.presentationLastModifiedDateTime
       ,pvs.defaultValue AS [presentation_defaultValue]
       ,pvs.required AS [presentation_required]
       ,pvs.maxLength AS [presentation_maxLength]
       ,pvs.defaultItem_displayName
       ,pvs.defaultItem_value
       ,pvs.itemDisplayName
       ,pvs.itemValue
       ,pvs.presentation_JSON
       ,pvs.defaultItem_JSON
       ,pvs.items_JSON
       ,gpd.classType AS [GroupPolicyDefinitionClassType]
       ,gpd.displayName AS [GroupPolicyDefinitionDisplayName]
       ,gpd.explainText AS [GroupPolicyDefinitionExplainText]
       ,gpd.categoryPath AS [GroupPolicyDefinitionCategoryPath]
       ,gpd.supportedOn AS [GroupPolicyDefinitionSupportedOn]
       ,gpd.policyType AS [GroupPolicyDefinitionPolicyType]
       ,gpd.lastModifiedDateTime AS [GroupPolicyDefinitionLastModifiedDateTime]
       ,gpd.DefinitionFileId
       ,gpd.DefinitionFileDisplayName
       ,gpd.DefinitionFileDescription
       ,gpd.DefinitionFileTargetPrefix
       ,gpd.DefinitionFileTargetNamespace
       ,gpd.DefinitionFilePolicyType
       ,gpd.DefinitionFileRevision
       ,gpd.DefinitionFileLastModifiedDateTime
       ,gpd.DefinitionFileLanguageCodesJson
  FROM dbo.groupPolicyConfigurations gpc
        LEFT OUTER JOIN dbo.v_groupPolicyConfigurations_definitionValues pdv
          ON gpc.id = pdv.ParentId
        LEFT OUTER JOIN dbo.v_groupPolicyConfigurationPresentationValues pvs
          ON gpc.id = pvs.groupPolicyConfigurationId
         AND pdv.id = pvs.groupPolicyConfigurationDefinitionValueId
        LEFT OUTER JOIN dbo.v_groupPolicyDefinitionsFlat gpd
          ON pdv.definitionId = gpd.GroupPolicyDefinitionId;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurations_PresentationInformation') IS NOT NULL
PRINT 'View "v_groupPolicyConfigurations_PresentationInformation" Created';
GO