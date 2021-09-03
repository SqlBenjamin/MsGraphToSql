USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_mobileApps

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_mobileApps') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_mobileApps;
    PRINT 'View "v_mobileApps" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_mobileApps AS
SELECT  app.id AS [ApplicationId]
       ,app.odatatype
       ,app.displayName
       ,app.description
       ,app.publisher
       ,app.largeIcon_JSON
       ,app.createdDateTime
       ,app.lastModifiedDateTime
       ,app.isFeatured
       ,app.privacyInformationUrl
       ,app.informationUrl
       ,app.owner
       ,app.developer
       ,app.notes
       ,app.publishingState
       ,app.assignments_JSON
       ,app.expirationDateTime
       ,COALESCE(app.productVersion,app.identityVersion,app.version) AS [ApplicationVersion]
  FROM dbo.mobileApps app;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_mobileApps') IS NOT NULL
PRINT 'View "v_mobileApps" Created';
GO