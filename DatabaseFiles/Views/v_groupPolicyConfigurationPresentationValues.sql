USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_groupPolicyConfigurationPresentationValues

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurationPresentationValues') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_groupPolicyConfigurationPresentationValues;
    PRINT 'View "v_groupPolicyConfigurationPresentationValues" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_groupPolicyConfigurationPresentationValues AS
SELECT  prs.ParentParentId AS [groupPolicyConfigurationId]
       ,prs.ParentId AS [groupPolicyConfigurationDefinitionValueId]
       --,prs.odatatype
       ,prs.id
       ,prs.lastModifiedDateTime
       ,prs.createdDateTime
       ,prs.value
       ,prs.presentation_JSON
       ,jsn.*
       ,itm.*
  FROM dbo.groupPolicyConfigurations_presentationValues prs
       OUTER APPLY OPENJSON (prs.presentation_JSON) WITH ( presentation_odatatype nvarchar(256) '$."@odata.type"'
                                                          ,label nvarchar(512) '$.label'
                                                          ,presentationId nvarchar(36) '$.id'
                                                          ,presentationLastModifiedDateTime datetime2 '$.lastModifiedDateTime'
                                                          ,defaultValue nvarchar(512) '$.defaultValue'
                                                          ,required bit '$.required'
                                                          ,maxLength int '$.maxLength'
                                                          ,defaultItem_displayName nvarchar(512) '$.defaultItem.displayName'
                                                          ,defaultItem_value nvarchar(512) '$.defaultItem.value'
                                                          ,defaultItem_JSON nvarchar(max) '$.defaultItem' AS JSON
                                                          ,items_JSON nvarchar(max) '$.items' AS JSON
                                                          ) jsn
       OUTER APPLY OPENJSON (jsn.items_JSON) WITH ( itemDisplayName nvarchar(512) '$.displayName'
                                                   ,itemValue nvarchar(512) '$.value'
                                                   ) itm;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_groupPolicyConfigurationPresentationValues') IS NOT NULL
PRINT 'View "v_groupPolicyConfigurationPresentationValues" Created';
GO