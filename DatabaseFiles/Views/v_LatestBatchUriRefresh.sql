USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_LatestBatchUriRefresh

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_LatestBatchUriRefresh') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_LatestBatchUriRefresh;
    PRINT 'View "v_LatestBatchUriRefresh" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_LatestBatchUriRefresh AS
SELECT  his.ID
       ,his.BatchID
       ,his.TableName
       ,rls.SpecificUrls.value(N'@UriPart[1]',N'varchar(2000)') AS [UriPart]
       ,rls.SpecificUrls.value(N'@UriVersion[1]',N'varchar(100)') AS [UriVersion]
       ,rls.SpecificUrls.value(N'(./RecordsImported)[1]',N'int') AS [RecordsImported]
       ,rls.SpecificUrls.value(N'(./RecordsNotImported)[1]',N'int') AS [RecordsNotImported]
       ,rls.SpecificUrls.value(N'(./ImportErrorOccurred)[1]',N'varchar(10)') AS [ImportErrorOccurred]
       ,rls.SpecificUrls.value(N'(./ImportRetriesOccurred)[1]',N'varchar(10)') AS [ImportRetriesOccurred]
       ,rls.SpecificUrls.value(N'(./StartDateTimeUTC)[1]',N'datetime2') AS [UriPartStart]
       ,rls.SpecificUrls.value(N'(./EndDateTimeUTC)[1]',N'datetime2') AS [UriPartEnd]
       ,dbo.udf_MsToHrMinSecMs(DATEDIFF(millisecond,rls.SpecificUrls.value(N'(./StartDateTimeUTC)[1]',N'datetime2'),rls.SpecificUrls.value(N'(./EndDateTimeUTC)[1]',N'datetime2'))) AS [UriDuration_HhMmSsMs]
       ,rls.SpecificUrls.value(N'(./ErrorDetails)[1]',N'varchar(max)') AS [UriErrorDetails]
       ,rls.SpecificUrls.value(N'(./RetriesOccurred)[1]',N'varchar(10)') AS [RetriesOccurredForUri]
       --,his.StartDateUTC AS [TableStart]
       --,his.EndDateUTC AS [TableEnd]
       --,his.ExtendedInfo.value(N'count(/SpecificURLs/SpecificURL)',N'int') AS [NumberOfUris]
       --,his.ExtendedInfo.value(N'sum(/SpecificURLs/SpecificURL/RecordsImported)',N'float') AS [TotalRecordsImported]
  FROM dbo.TableRefreshHistory his WITH (NOLOCK)
       OUTER APPLY his.ExtendedInfo.nodes(N'/SpecificURLs/SpecificURL') rls(SpecificUrls)
 WHERE his.BatchID = (SELECT MAX(ID) FROM dbo.PowerShellRefreshHistory);
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_LatestBatchUriRefresh') IS NOT NULL
PRINT 'View "v_LatestBatchUriRefresh" Created';
GO