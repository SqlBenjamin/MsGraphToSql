USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.PowerShellRefreshHistory

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.
07/26/2021    0.0        Benjamin Reynolds        Added backup/restore logic.
***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.PowerShellRefreshHistory') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.PowerShellRefreshHistory)
    BEGIN
      DECLARE  @SqlText nvarchar(2000)
              ,@RowCount int;
      SET @SqlText = N'SELECT * INTO dbo.zPowerShellRefreshHistoryBACKUP FROM dbo.PowerShellRefreshHistory ORDER BY ID; SELECT @RowCount = @@ROWCOUNT;';
      EXECUTE sp_ExecuteSql @SqlText, N'@RowCount int OUTPUT', @RowCount = @RowCount OUTPUT;
      PRINT 'PowerShellRefreshHistory backed up into zPowerShellRefreshHistoryBACKUP (Rows backed up: '+CONVERT(varchar(15), @RowCount)+')';
    END;

    DROP TABLE dbo.PowerShellRefreshHistory;
    PRINT 'Table "PowerShellRefreshHistory" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.PowerShellRefreshHistory ( ID int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
                                           ,StartDateUTC datetime2 NOT NULL DEFAULT (SYSUTCDATETIME())
                                           ,EndDateUTC datetime2 NULL
                                           ,ErrorNumber int NULL
                                           ,ErrorMessage nvarchar(max) NULL
                                           ,RunBy_User nvarchar(256) NOT NULL DEFAULT (SUSER_SNAME())
                                           ,JobName nvarchar(128) NULL
                                           ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.PowerShellRefreshHistory') IS NOT NULL
PRINT 'Table "PowerShellRefreshHistory" Created';
GO

-- Restore backup data if exists:
IF OBJECT_ID(N'dbo.zPowerShellRefreshHistoryBACKUP') IS NOT NULL AND OBJECT_ID(N'dbo.PowerShellRefreshHistory') IS NOT NULL
BEGIN
    DECLARE @RowCnt int;
    INSERT dbo.PowerShellRefreshHistory (StartDateUTC,EndDateUTC,ErrorNumber,ErrorMessage,RunBy_User,JobName)
    SELECT StartDateUTC,EndDateUTC,ErrorNumber,ErrorMessage,RunBy_User,JobName
      FROM dbo.zPowerShellRefreshHistoryBACKUP
     ORDER BY ID;
    SELECT @RowCnt = @@ROWCOUNT;
    DROP TABLE dbo.zPowerShellRefreshHistoryBACKUP;
    PRINT 'PowerShellRefreshHistory data restored and backup table dropped; Records Restored: '+CONVERT(varchar(15), @RowCnt);
END;
GO