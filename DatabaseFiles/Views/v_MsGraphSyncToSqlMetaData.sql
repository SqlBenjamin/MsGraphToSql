USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.v_MsGraphSyncToSqlMetaData

History:
Date          Version    Author                   Notes:
05/25/2021    0.0        Benjamin Reynolds        Created (renamed from 'v_IntuneSyncToSqlMetaData').
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the view was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.v_MsGraphSyncToSqlMetaData') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_MsGraphSyncToSqlMetaData;
    PRINT 'View "v_MsGraphSyncToSqlMetaData" Dropped.';
END;
GO

-- View Definition:
CREATE VIEW dbo.v_MsGraphSyncToSqlMetaData AS
WITH MetaDataUnpivoted AS (
SELECT DBID,Property,Value
  FROM (
SELECT  DBID
       --,CONVERT(nvarchar(max),TableName) AS [TableName]
       ,CONVERT(nvarchar(max),UriPart) AS [UriPart]
       ,CONVERT(nvarchar(max),Version) AS [Version]
       ,CONVERT(nvarchar(max),ExpandColumns) AS [ExpandColumns]
       ,CONVERT(nvarchar(max),ExpandTableOrColumn) AS [ExpandTableOrColumn]
       ,CONVERT(nvarchar(max),MetaDataEntityToUse) AS [MetaDataEntityToUse]
       ,CONVERT(nvarchar(max),UriPartType) AS [UriPartType]
       ,CONVERT(nvarchar(max),ReplacementTable) AS [ReplacementTable]
       ,CONVERT(nvarchar(max),TargetTable) AS [TargetTable]
       ,CONVERT(nvarchar(max),ParentCols) AS [ParentCols]
       ,CONVERT(nvarchar(max),CASE SkipGraphMetaDataCheck WHEN 1 THEN N'TRUE' END) AS [SkipGraphMetaDataCheck]
       ,CONVERT(nvarchar(max),SelectColumns) AS [SelectColumns]
       ,CONVERT(nvarchar(max),ReportName) AS [ReportName]
       ,CONVERT(nvarchar(max),ReportFilter) AS [ReportFilter]
  FROM dbo.MsGraphSyncToSqlMetaData
       ) dta
UNPIVOT (Value FOR Property IN (/*TableName,*/UriPart,Version,ExpandColumns,ExpandTableOrColumn,MetaDataEntityToUse,UriPartType,ReplacementTable,TargetTable,ParentCols,SkipGraphMetaDataCheck,SelectColumns,ReportName,ReportFilter)) upv
)
SELECT  DISTINCT mdu.DBID
       ,CASE WHEN Enabled = 0 THEN N'#' ELSE N'' END+N',@{'+STUFF(hsh.HashValue,1,2,N'')+N'}' AS [UriHashString]
       ,mtd.TableId
       ,mtd.ParentId
       ,mtd.TableName
       ,mtd.UriPart
       ,mtd.Version
       ,mtd.ExpandColumns
       ,mtd.ExpandTableOrColumn
       ,mtd.MetaDataEntityToUse
       ,mtd.UriPartType
       ,mtd.ReplacementTable
       ,mtd.TargetTable
       ,mtd.ParentCols
       ,mtd.SkipGraphMetaDataCheck
       ,mtd.SelectColumns
       ,mtd.ReportName
       ,mtd.ReportFilter
       ,mtd.Enabled
       ,mtd.JobName
       ,mtd.JobOrder
       ,mtd.Notes
  FROM MetaDataUnpivoted mdu
       INNER JOIN dbo.MsGraphSyncToSqlMetaData mtd
          ON mdu.DBID = mtd.DBID
       CROSS APPLY (
                    SELECT N'; "'+Property+N'" = "'+Value+N'"'
                      FROM MetaDataUnpivoted
                     WHERE DBID = mdu.DBID
                       FOR XML PATH ('')
                    ) hsh(HashValue);
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.v_MsGraphSyncToSqlMetaData') IS NOT NULL
PRINT 'View "v_MsGraphSyncToSqlMetaData" Created';
GO