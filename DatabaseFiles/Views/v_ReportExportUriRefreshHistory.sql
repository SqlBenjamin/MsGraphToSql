USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_ReportExportUriRefreshHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_ReportExportUriRefreshHistory') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_ReportExportUriRefreshHistory;
    PRINT 'View "v_ReportExportUriRefreshHistory" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_ReportExportUriRefreshHistory AS
SELECT  his.ID
       ,his.BatchID
       ,his.TableName
       ,rls.SpecificUrls.value(N'@ReportName[1]',N'varchar(2000)') AS [ReportName]
       ,rls.SpecificUrls.value(N'@UriVersion[1]',N'varchar(100)') AS [UriVersion]
       ,rls.SpecificUrls.value(N'@Select[1]',N'varchar(2000)') AS [ReportSelect]
       ,rls.SpecificUrls.value(N'@Filter[1]',N'varchar(2000)') AS [ReportFilter]
       ,rls.SpecificUrls.value(N'(./RecordsImported)[1]',N'int') AS [RecordsImported]
       ,rls.SpecificUrls.value(N'(./RecordsNotImported)[1]',N'int') AS [RecordsNotImported]
       ,rls.SpecificUrls.value(N'(./ImportErrorOccurred)[1]',N'varchar(10)') AS [ImportErrorOccurred]
       ,rls.SpecificUrls.value(N'(./ImportRetriesOccurred)[1]',N'varchar(10)') AS [ImportRetriesOccurred]
       ,rls.SpecificUrls.value(N'(./StartDateTimeUTC)[1]',N'datetime2') AS [UriPartStart]
       ,rls.SpecificUrls.value(N'(./EndDateTimeUTC)[1]',N'datetime2') AS [UriPartEnd]
       ,dbo.udf_MsToHrMinSecMs(DATEDIFF(millisecond,rls.SpecificUrls.value(N'(./StartDateTimeUTC)[1]',N'datetime2'),rls.SpecificUrls.value(N'(./EndDateTimeUTC)[1]',N'datetime2'))) AS [UriDuration_HhMmSsMs]
       ,DATEDIFF(second,rls.SpecificUrls.value(N'(./StartDateTimeUTC)[1]',N'datetime2'),rls.SpecificUrls.value(N'(./EndDateTimeUTC)[1]',N'datetime2')) AS [UriDuration_Seconds]
       ,rls.SpecificUrls.value(N'(./ErrorDetails)[1]',N'varchar(max)') AS [UriErrorDetails]
       ,rls.SpecificUrls.value(N'(./RetriesOccurred)[1]',N'varchar(10)') AS [RetriesOccurredForUri]
       ,rls.SpecificUrls.value(N'(./StatusResponse/LastClientRequestId)[1]',N'varchar(36)') AS [StatusResponse_LastClientRequestId]
       ,rls.SpecificUrls.value(N'(./StatusResponse/Duration)[1]',N'varchar(15)') AS [StatusResponse_Duration]
       ,rls.SpecificUrls.value(N'(./StatusResponse/id)[1]',N'varchar(1000)') AS [StatusResponse_id]
       ,rls.SpecificUrls.value(N'(./StatusResponse/status)[1]',N'varchar(100)') AS [StatusResponse_status]
       ,rls.SpecificUrls.value(N'(./StatusResponse/requestDateTime)[1]',N'datetime2') AS [StatusResponse_requestDateTime]
       ,rls.SpecificUrls.value(N'(./StatusResponse/expirationDateTime)[1]',N'datetime2') AS [StatusResponse_expirationDateTime]
       ,rls.SpecificUrls.value(N'(./StatusResponse/ErrorCaught)[1]',N'varchar(25)') AS [StatusResponse_ErrorCaught]
       ,rls.SpecificUrls.value(N'(./StatusResponse/ErrorMessage)[1]',N'varchar(max)') AS [StatusResponse_ErrorMessage]
  FROM dbo.TableRefreshHistory his WITH (NOLOCK)
       OUTER APPLY his.ExtendedInfo.nodes(N'/SpecificURLs/SpecificURL') rls(SpecificUrls)
 WHERE rls.SpecificUrls.exist(N'@ReportName') = 1;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_ReportExportUriRefreshHistory') IS NOT NULL
PRINT 'View "v_ReportExportUriRefreshHistory" Created';
GO