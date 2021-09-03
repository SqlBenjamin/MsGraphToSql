USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.deviceEnrollmentTypes

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.deviceEnrollmentTypes') IS NOT NULL
BEGIN
    DROP TABLE dbo.deviceEnrollmentTypes;
    PRINT 'Table "deviceEnrollmentTypes" Dropped';
END;
GO

-- Create Table:
CREATE TABLE dbo.deviceEnrollmentTypes ( enrollmentTypeId int PRIMARY KEY CLUSTERED NOT NULL
                                        ,enrollmentType nvarchar(26) NOT NULL
                                        ,enrollmentTypeDescription nvarchar(2000) NOT NULL
                                        ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.deviceEnrollmentTypes') IS NOT NULL
PRINT 'Table "deviceEnrollmentTypes" Created';
GO

-- Populate Table:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.deviceEnrollmentTypes VALUES  (0,N'unknown',N'Default value, enrollment type was not collected.')
                                        ,(1,N'userEnrollment',N'User driven enrollment through normal user through Company Portal.')
                                        ,(2,N'deviceEnrollmentManager',N'User enrollment with a device enrollment manager account.')
                                        ,(3,N'appleBulkWithUser',N'Apple bulk enrollment with user authentication. (DEP, Apple Configurator)')
                                        ,(4,N'appleBulkWithoutUser',N'Apple bulk enrollment without user authentication. (DEP, Apple Configurator, Mobile Config)')
                                        ,(5,N'windowsAzureADJoin',N'Windows 10 Azure AD Join unified enrollment.')
                                        ,(6,N'windowsBulkUserless',N'Windows 10 Bulk enrollment through ICD with certificate.')
                                        ,(7,N'windowsAutoEnrollment',N'Windows 10 WPJ unified enrollment. (Add work account)')
                                        ,(8,N'windowsBulkAzureDomainJoin',N'Windows 10 bulk provision package to Azure AD Join and unified enrollment.')
                                        ,(9,N'windowsCoManagement',N'Windows 10 Co-Management triggered by AutoPilot or Group Policy.');
PRINT 'Table "deviceEnrollmentTypes" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error populating "deviceEnrollmentTypes"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO