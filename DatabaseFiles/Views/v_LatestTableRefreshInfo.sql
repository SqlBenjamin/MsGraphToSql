USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_LatestTableRefreshInfo

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_LatestTableRefreshInfo') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_LatestTableRefreshInfo;
    PRINT 'View "v_LatestTableRefreshInfo" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_LatestTableRefreshInfo AS
WITH LatestTable AS (
SELECT  TableName
       ,MAX(ID) AS [MaxID]
  FROM dbo.TableRefreshHistory
 GROUP BY TableName
)
SELECT  his.ID
       ,his.BatchID
       ,his.TableName
       ,his.StartDateUTC
       ,his.EndDateUTC
       ,dbo.udf_MsToHrMinSecMs(DATEDIFF(millisecond,his.StartDateUTC,his.EndDateUTC)) AS [Duration_HhMmSsMs]
       ,DATEDIFF(second,his.StartDateUTC,his.EndDateUTC) AS [Duration_Seconds]
       ,his.ExtendedInfo
       ,his.ErrorNumber
       ,his.ErrorMessage
       ,his.ExtendedInfo.value(N'count(/SpecificURLs/SpecificURL)',N'int') AS [NumberOfUris]
       ,his.ExtendedInfo.value(N'count(/SpecificURLs/SpecificURL/ErrorDetails)',N'int') AS [NumUrisWithErrorMessages]
       ,his.ExtendedInfo.value(N'count(/SpecificURLs/SpecificURL[ErrorDetails = "No Records returned; Moving to next URL/table..." or ErrorDetails = "No data for the expanded column was found."])',N'int') AS [NumUrisWithNoRecordsReturned]
       ,his.ExtendedInfo.value(N'count(/SpecificURLs/SpecificURL[ErrorDetails != "No Records returned; Moving to next URL/table..." and ErrorDetails != "No data for the expanded column was found."])',N'int') AS [NumUrisNotNoRecordsReturned]
       ,his.ExtendedInfo.value(N'sum(/SpecificURLs/SpecificURL/RecordsImported)',N'float') AS [TotalRecordsImported]
       ,his.ExtendedInfo.value(N'sum(/SpecificURLs/SpecificURL/RecordsNotImported)',N'float') AS [TotalRecordsNotImported]
       ,CASE his.ExtendedInfo.exist(N'/SpecificURLs/SpecificURL/ImportErrorOccurred')
             WHEN 1 THEN 'True'
             ELSE 'False'
        END AS [ImportErrorOccurred]
       ,CASE his.ExtendedInfo.exist(N'/SpecificURLs/SpecificURL[RecordsNotImported>"0"]')
             WHEN 1 THEN 'True'
             ELSE 'False'
        END AS [NotAllRecordsImported]
       ,his.RunBy_User
  FROM dbo.TableRefreshHistory his
       INNER JOIN LatestTable lst
          ON his.ID = lst.MaxID;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_LatestTableRefreshInfo') IS NOT NULL
PRINT 'View "v_LatestTableRefreshInfo" Created';
GO