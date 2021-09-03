USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.groupPolicyConfigurations_presentationValues

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.groupPolicyConfigurations_presentationValues') IS NOT NULL
BEGIN
    DROP TABLE dbo.groupPolicyConfigurations_presentationValues;
    PRINT 'Table "groupPolicyConfigurations_presentationValues" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.groupPolicyConfigurations_presentationValues ( ParentParentId nvarchar(36) NOT NULL
                                                               ,ParentId nvarchar(36) NOT NULL
                                                               ,odatatype nvarchar(256) NOT NULL
                                                               ,id nvarchar(36) NOT NULL
                                                               ,lastModifiedDateTime datetime2 NOT NULL
                                                               ,createdDateTime datetime2 NOT NULL
                                                               ,value sql_variant NOT NULL
                                                               ,presentation_JSON nvarchar(max) NULL
                                                               ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.groupPolicyConfigurations_presentationValues') IS NOT NULL
PRINT 'Table "groupPolicyConfigurations_presentationValues" Created';
GO