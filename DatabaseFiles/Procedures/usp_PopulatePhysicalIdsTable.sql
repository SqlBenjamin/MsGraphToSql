USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_PopulatePhysicalIdsTable') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_PopulatePhysicalIdsTable;
    PRINT 'Sproc "usp_PopulatePhysicalIdsTable" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_PopulatePhysicalIdsTable
Purpose: This procedure shreds the "physicalIds_JSON" column into records and inserts the data into devices_physicalIds.

History:
Date          Version    Author                   Notes:
??/??/2020    0.0        Benjamin Reynolds        Created.
*****************************************************************************************************************/
CREATE PROCEDURE dbo.usp_PopulatePhysicalIdsTable
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE  @RowsInserted int
          ,@Message nvarchar(2047)
          ,@StartTimeUtc datetime
          ,@EndTimeUtc datetime;

  SELECT @StartTimeUtc = GETUTCDATE();
  SET @Message = N'Script Starting: ' + CONVERT(nvarchar,@StartTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
  
  TRUNCATE TABLE dbo.devices_physicalIds;
  SET @Message = N'Table Successfully truncated.';
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
  
  INSERT dbo.devices_physicalIds (id,GID,HWID,OrderId,PurchaseOrderId,ZTDID,AzureResourceId,SHA256_GID,SHA256_HWID,SHA256_USER_GID,SHA256_USER_HWID,USER_GID,USER_HWID)
  SELECT  id
         ,GID,HWID,OrderId,PurchaseOrderId,ZTDID,AzureResourceId,SHA256_GID,SHA256_HWID,SHA256_USER_GID,SHA256_USER_HWID,USER_GID,USER_HWID
    FROM (
          SELECT  dvc.id
                 ,TRIM(N'[]' FROM REPLACE(SUBSTRING(jsn.value,1,CHARINDEX(N']',jsn.value)),N'-',N'_')) AS [NewKey]
                 ,SUBSTRING(jsn.value,CHARINDEX(N']:',jsn.value)+2,LEN(jsn.value)) AS [Value]
            FROM dbo.devices dvc
                 OUTER APPLY OPENJSON (dvc.physicalIds_JSON) jsn
           WHERE ISJSON(dvc.physicalIds_JSON) = 1
          ) dta
   PIVOT (MAX(Value) FOR NewKey IN (GID,HWID,OrderId,PurchaseOrderId,ZTDID,AzureResourceId,SHA256_GID,SHA256_HWID,SHA256_USER_GID,SHA256_USER_HWID,USER_GID,USER_HWID)) pvt;
  
  SELECT @RowsInserted = @@ROWCOUNT;
  SET @Message = CONVERT(nvarchar(25),@RowsInserted) + N' rows shredded and inserted into table.';
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @EndTimeUtc = GETUTCDATE();
  SET @Message = N'Script Completed: ' + CONVERT(nvarchar,@EndTimeUtc,120);
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;

  SELECT @Message = N'Duration: ' + dbo.udf_MsToHrMinSecMs(DATEDIFF_BIG(millisecond,@StartTimeUtc,@EndTimeUtc));
  RAISERROR('%s',10,1,@Message) WITH NOWAIT;
END;
GO

IF OBJECT_ID(N'dbo.usp_PopulatePhysicalIdsTable') IS NOT NULL
PRINT 'Sproc "usp_PopulatePhysicalIdsTable" Created.';
ELSE
PRINT 'Sproc "usp_PopulatePhysicalIdsTable" NOT CREATED...Check for errors!';
GO