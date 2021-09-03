USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.TableRefreshHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.
07/26/2021    0.0        Benjamin Reynolds        Added backup/restore logic.
***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.TableRefreshHistory') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.TableRefreshHistory)
    BEGIN
      DECLARE  @SqlText nvarchar(2000)
              ,@RowCount int;
      SET @SqlText = N'SELECT * INTO dbo.zTableRefreshHistoryBACKUP FROM dbo.TableRefreshHistory ORDER BY ID; SELECT @RowCount = @@ROWCOUNT;';
      EXECUTE sp_ExecuteSql @SqlText, N'@RowCount int OUTPUT', @RowCount = @RowCount OUTPUT;
      PRINT 'TableRefreshHistory backed up into zTableRefreshHistoryBACKUP (Rows backed up: '+CONVERT(varchar(15), @RowCount)+')';
    END;
    
    DROP TABLE dbo.TableRefreshHistory;
    PRINT 'Table "TableRefreshHistory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.TableRefreshHistory ( ID int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
                                      ,TableName sysname NOT NULL
                                      ,BatchID int NOT NULL DEFAULT (-1)
                                      ,StartDateUTC datetime2 NOT NULL DEFAULT (SYSUTCDATETIME())
                                      ,EndDateUTC datetime2 NULL
                                      ,ExtendedInfo xml NULL
                                      ,ErrorNumber int NULL
                                      ,ErrorMessage nvarchar(max) NULL
                                      ,RunBy_User nvarchar(256) NOT NULL DEFAULT (SUSER_SNAME())
                                      ) ON [PRIMARY];
GO
-- Create Index(es)
DROP INDEX IF EXISTS IDX_TableRefreshHistory_BatchID
  ON dbo.TableRefreshHistory;
CREATE NONCLUSTERED INDEX IDX_TableRefreshHistory_BatchID
    ON dbo.TableRefreshHistory (BatchID);
PRINT 'Index(es) created on TableRefreshHistory.';
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.TableRefreshHistory') IS NOT NULL
PRINT 'Table "TableRefreshHistory" Created';
GO

-- Restore backup data if exists:
IF OBJECT_ID(N'dbo.zTableRefreshHistoryBACKUP') IS NOT NULL AND OBJECT_ID(N'dbo.TableRefreshHistory') IS NOT NULL
BEGIN
    DECLARE @RowCnt int;
    INSERT dbo.TableRefreshHistory (TableName,BatchID,StartDateUTC,EndDateUTC,ExtendedInfo,ErrorNumber,ErrorMessage,RunBy_User)
    SELECT TableName,BatchID,StartDateUTC,EndDateUTC,ExtendedInfo,ErrorNumber,ErrorMessage,RunBy_User
      FROM dbo.zTableRefreshHistoryBACKUP
     ORDER BY ID;
    SELECT @RowCnt = @@ROWCOUNT;
    DROP TABLE dbo.zTableRefreshHistoryBACKUP;
    PRINT 'TableRefreshHistory data restored and backup table dropped; Records Restored: '+CONVERT(varchar(15), @RowCnt);
END;
GO