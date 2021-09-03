USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.AadGroups

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

NOTE: UPDATE Ids and Names below before actually using!
***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.AadGroups') IS NOT NULL
BEGIN
    DROP TABLE dbo.AadGroups;
    PRINT 'Table "AadGroups" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.AadGroups ( id nvarchar(36) NOT NULL PRIMARY KEY CLUSTERED
                            ,AadGroupName nvarchar(128) NOT NULL
                            ,IsUserGroup bit NOT NULL
                            );
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.AadGroups') IS NOT NULL
PRINT 'Table "AadGroups" Created';
GO

-- Populate Table:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.AadGroups
VALUES  (N'Insert Id Here 1', N'Insert Name Here - User based Group', 1)
       ,(N'Insert Id Here 2', N'Insert Name Here - User based Group', 1)
       ,(N'Insert Id Here 3', N'Insert Name Here - Device based Group', 0)
       ,(N'Insert Id Here 4', N'Insert Name Here - Device based Group', 0);
PRINT 'Table "AadGroups" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error populating "AadGroups"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO