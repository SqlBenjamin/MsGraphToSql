USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.groupPolicyDefinitions_definitionFile

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.groupPolicyDefinitions_definitionFile') IS NOT NULL
BEGIN
    DROP TABLE dbo.groupPolicyDefinitions_definitionFile;
    PRINT 'Table "groupPolicyDefinitions_definitionFile" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.groupPolicyDefinitions_definitionFile ( ParentId nvarchar(36) NOT NULL
                                                        ,id nvarchar(36) NOT NULL
                                                        ,displayName nvarchar(512) NULL
                                                        ,description nvarchar(512) NULL
                                                        ,languageCodes_JSON nvarchar(max) NULL
                                                        ,targetPrefix nvarchar(128) NULL
                                                        ,targetNamespace nvarchar(256) NULL
                                                        ,policyType nvarchar(12) NOT NULL
                                                        ,revision nvarchar(128) NULL
                                                        ,lastModifiedDateTime datetime2 NOT NULL
                                                        ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.groupPolicyDefinitions_definitionFile') IS NOT NULL
PRINT 'Table "groupPolicyDefinitions_definitionFile" Created';
GO