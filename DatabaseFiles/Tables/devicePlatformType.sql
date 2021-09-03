USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.devicePlatformType

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.devicePlatformType') IS NOT NULL
BEGIN
    DROP TABLE dbo.devicePlatformType;
    PRINT 'Table "devicePlatformType" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.devicePlatformType ( Value tinyint NOT NULL PRIMARY KEY CLUSTERED
                                     ,Name nvarchar(25) NOT NULL
                                     ) ON [PRIMARY];
GO
-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.devicePlatformType') IS NOT NULL
PRINT 'Table "devicePlatformType" Created';
GO

-- Populate table:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.devicePlatformType
VALUES  (0,N'android')
       ,(1,N'androidForWork')
       ,(2,N'iOS')
       ,(3,N'macOS')
       ,(4,N'windowsPhone81')
       ,(5,N'windows81AndLater')
       ,(6,N'windows10AndLater')
       ,(7,N'androidWorkProfile');
PRINT 'Table "devicePlatformType" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error populating "devicePlatformType"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO