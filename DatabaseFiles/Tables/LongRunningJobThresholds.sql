USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.LongRunningJobThresholds

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.LongRunningJobThresholds') IS NOT NULL
BEGIN
    DROP TABLE dbo.LongRunningJobThresholds;
    PRINT 'Table "LongRunningJobThresholds" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.LongRunningJobThresholds ( JobName nvarchar(128) NOT NULL PRIMARY KEY CLUSTERED
                                           ,ThresholdHours tinyint NOT NULL
                                           );
GO
-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.LongRunningJobThresholds') IS NOT NULL
PRINT 'Table "LongRunningJobThresholds" Created';
GO

-- Populate the table:
DECLARE  @ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int;
BEGIN TRY
INSERT dbo.LongRunningJobThresholds
VALUES  (N'MsGraphSyncToSql_AAD',5)
       --,(N'MsGraphSyncToSql_Autopilot',23)
       --,(N'MsGraphSyncToSql_DetectedApps',10)
       ,(N'MsGraphSyncToSql_Devices',3)
       ,(N'MsGraphSyncToSql_MobileApps',4)
       --,(N'MsGraphSyncToSql_ReportExports',)
       ,(N'MsGraphSyncToSql_Various',4)
       --,(N'MsGraphSyncToSql_WIP_DHS',)
       ;
PRINT 'Table "LongRunningJobThresholds" Populated';
END TRY
BEGIN CATCH
SELECT @ErrorMessage  = ERROR_MESSAGE()
      ,@ErrorNumber   = ERROR_NUMBER();
PRINT 'Error populating "LongRunningJobThresholds"!';
PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
PRINT N' *** Error Message: '+@ErrorMessage;
END CATCH;
GO