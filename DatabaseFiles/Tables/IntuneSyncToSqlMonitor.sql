USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.IntuneSyncToSqlMonitor

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.IntuneSyncToSqlMonitor') IS NOT NULL
BEGIN
    DROP TABLE dbo.IntuneSyncToSqlMonitor;
    PRINT 'Table "IntuneSyncToSqlMonitor" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.IntuneSyncToSqlMonitor ( ID int IDENTITY (1,1) NOT NULL PRIMARY KEY CLUSTERED
                                         ,BatchID int NOT NULL
                                         ,AlertDateUTC datetime2 NOT NULL DEFAULT (SYSUTCDATETIME())
                                         ,AlertDateLocal datetime NOT NULL DEFAULT (GETDATE())
                                         ,JobName nvarchar(256) NULL
                                         ,AlertMessage nvarchar(max) NULL
                                         ) ON [PRIMARY];
GO
-- Create Index(es)
DROP INDEX IF EXISTS IX_IntuneSyncToSqlMonitor_BatchID
  ON dbo.IntuneSyncToSqlMonitor;
CREATE NONCLUSTERED INDEX IX_IntuneSyncToSqlMonitor_BatchID
    ON dbo.IntuneSyncToSqlMonitor (BatchID)
INCLUDE (AlertDateUTC,AlertDateLocal);
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.IntuneSyncToSqlMonitor') IS NOT NULL
PRINT 'Table "IntuneSyncToSqlMonitor" Created';
GO