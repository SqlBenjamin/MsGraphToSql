USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.groupPolicyDefinitions

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.groupPolicyDefinitions') IS NOT NULL
BEGIN
    DROP TABLE dbo.groupPolicyDefinitions;
    PRINT 'Table "groupPolicyDefinitions" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.groupPolicyDefinitions ( id nvarchar(36) NOT NULL
                                         ,classType nvarchar(7) NOT NULL
                                         ,displayName nvarchar(256) NULL
                                         ,explainText nvarchar(256) NULL
                                         ,categoryPath nvarchar(256) NULL
                                         ,supportedOn nvarchar(256) NULL
                                         ,policyType nvarchar(12) NOT NULL
                                         ,lastModifiedDateTime datetime2 NOT NULL
                                         ,definitionFile_JSON nvarchar(max) NULL
                                         ,AllData_JSON nvarchar(max) NULL
                                         ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.groupPolicyDefinitions') IS NOT NULL
PRINT 'Table "groupPolicyDefinitions" Created';
GO