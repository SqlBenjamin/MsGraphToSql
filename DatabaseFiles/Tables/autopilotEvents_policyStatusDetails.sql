USE [Intune];
GO
SET NOCOUNT ON;

/***************************************************************************************************************************
Object: dbo.autopilotEvents_policyStatusDetails

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.
06/08/2021    0.0        Benjamin Reynolds        Updated to account for PowerShell (running in batches) which could say the table was
                                                  created when in fact there was an error creating it.

***************************************************************************************************************************/

-- Drop if already exists:
IF OBJECT_ID(N'dbo.autopilotEvents_policyStatusDetails') IS NOT NULL
BEGIN
    DROP TABLE dbo.autopilotEvents_policyStatusDetails;
    PRINT 'Table "autopilotEvents_policyStatusDetails" Dropped.';
END;
GO

-- Create Table:
CREATE TABLE dbo.autopilotEvents_policyStatusDetails ( ParentId nvarchar(46) NOT NULL
                                                      ,id nvarchar(100) NOT NULL -- 97?
                                                      ,displayName nvarchar(512) NULL
                                                      ,policyType nvarchar(19) NOT NULL
                                                      ,complianceStatus nvarchar(12) NOT NULL
                                                      ,trackedOnEnrollmentStatus bit NOT NULL
                                                      ,lastReportedDateTime datetime2 NOT NULL
                                                      ) ON [PRIMARY];
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.autopilotEvents_policyStatusDetails') IS NOT NULL
PRINT 'Table "autopilotEvents_policyStatusDetails" Created';
GO