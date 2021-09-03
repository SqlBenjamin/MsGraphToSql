USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceConfigurations

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceConfigurations') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceConfigurations;
    PRINT 'Table "deviceConfigurations" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceConfigurations ( odatatype nvarchar(256) NOT NULL
                                       ,id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                                       ,lastModifiedDateTime datetime2 NOT NULL
                                       ,createdDateTime datetime2 NOT NULL
                                       ,description nvarchar(max) NULL
                                       ,displayName nvarchar(256) NOT NULL
                                       ,version int NOT NULL
                                       ,AllData_JSON nvarchar(max) NULL
                                       ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceConfigurations') IS NOT NULL
PRINT 'Table "deviceConfigurations" Created';
GO