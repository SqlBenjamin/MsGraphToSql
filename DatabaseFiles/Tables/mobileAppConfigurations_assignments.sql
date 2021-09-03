USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.mobileAppConfigurations_assignments

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.mobileAppConfigurations_assignments') IS NOT NULL
BEGIN
    DROP TABLE dbo.mobileAppConfigurations_assignments;
    PRINT 'Table "mobileAppConfigurations_assignments" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.mobileAppConfigurations_assignments ( ParentId nvarchar(36) NOT NULL 
                                                      ,id nvarchar(73) NOT NULL
                                                      ,target_JSON nvarchar(max) NULL
                                                      ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.mobileAppConfigurations_assignments') IS NOT NULL
PRINT 'Table "mobileAppConfigurations_assignments" Created';
GO