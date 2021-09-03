USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.aadGroupMembership

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.aadGroupMembership') IS NOT NULL
BEGIN
    DROP TABLE dbo.aadGroupMembership;
    PRINT 'Table "aadGroupMembership" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.aadGroupMembership ( ParentId nvarchar(36) NOT NULL
                                     --,odatatype nvarchar(256) NOT NULL
                                     ,id nvarchar(36) NOT NULL
                                     ,deviceId nvarchar(36) NULL
                                     --,displayName nvarchar(256) NULL
                                     --,givenName nvarchar(64) NULL
                                     --,mail nvarchar(128) NULL
                                     --,surname nvarchar(64) NULL
                                     --,userPrincipalName nvarchar(128) NULL
                                     );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.aadGroupMembership') IS NOT NULL
PRINT 'Table "aadGroupMembership" Created';
GO

-- Create Indexes:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
  DROP INDEX IF EXISTS IX_aadGroupMembership_ParentIdAndId ON dbo.aadGroupMembership;
  CREATE NONCLUSTERED INDEX IX_aadGroupMembership_ParentIdAndId ON dbo.aadGroupMembership (ParentId,id);
  DROP INDEX IF EXISTS IX_aadGroupMembership_ParentIdAndDeviceId ON dbo.aadGroupMembership;
  CREATE NONCLUSTERED INDEX IX_aadGroupMembership_ParentIdAndDeviceId ON dbo.aadGroupMembership (ParentId,deviceId);
  PRINT 'Indexes created on "aadGroupMembership".';
END TRY
BEGIN CATCH
  SELECT @ErrorMessage  = ERROR_MESSAGE()
        ,@ErrorNumber   = ERROR_NUMBER();
  PRINT 'Error creating indexes on "aadGroupMembership"!';
  PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
  PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO
