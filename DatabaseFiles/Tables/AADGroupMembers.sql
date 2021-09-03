USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.AADGroupMembers

History:
Date          Version    Author                   Notes:
05/19/2021    0.0        Benjamin Reynolds        Created.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.AADGroupMembers') IS NOT NULL
BEGIN
    DROP TABLE dbo.AADGroupMembers;
    PRINT 'Table "AADGroupMembers" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.AADGroupMembers ( ParentId nvarchar(36) NOT NULL
                                  ,id nvarchar(36) NOT NULL
                                  ,displayName nvarchar(256) NULL
                                  ,accountEnabled nvarchar(10) NULL
                                  ,mail nvarchar(320) NULL
                                  ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.AADGroupMembers') IS NOT NULL
PRINT 'Table "AADGroupMembers" Created';
GO