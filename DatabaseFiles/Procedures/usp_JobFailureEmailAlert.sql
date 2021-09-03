USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.usp_JobFailureEmailAlert') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_JobFailureEmailAlert;
    PRINT 'Sproc "usp_JobFailureEmailAlert" Deleted.';
END;
GO

/***************************************************************************************************************
Object: dbo.usp_JobFailureEmailAlert
Purpose: The Purpose of this Stored Procedure is to create an email alert if any errors occurred with the
         IntuneSyncToSql job (passed in).

History:
Date          Version    Author                   Notes:
06/26/2020    0.0        Benjamin Reynolds        Created.
09/04/2020    0.0        Benjamin Reynolds        Added additional ErrorDetails check due to an additional non actionable error
                                                  message added to the process.

NOTE: Make sure to update the environmental variables below (far below) before running!
*****************************************************************************************************************/

CREATE PROCEDURE dbo.usp_JobFailureEmailAlert
    @JobName nvarchar(128)
AS

BEGIN
SET NOCOUNT ON;

DECLARE @Failures table ( ID int NOT NULL PRIMARY KEY CLUSTERED
                         ,TableName sysname NOT NULL
                         ,ErrorMessage nvarchar(max) NULL
                         ,StartDateUTC datetime2 NOT NULL
                         ,EndDateUTC datetime2 NULL
                         ,Duration_HhMmSsMs varchar(25) NULL                    
						 ,TotalRecordsImported int NULL
						 ,TotalRecordsNotImported int NULL
                         );

INSERT @Failures
SELECT  ID
       ,TableName
       ,CONVERT(nvarchar(max),ExtendedInfo.query('distinct-values(/SpecificURLs/SpecificURL[ErrorDetails != "No Records returned; Moving to next URL/table..." and ErrorDetails != "No data for the expanded column was found."]/ErrorDetails/text())')) AS [ErrorMessage]
       ,StartDateUTC
       ,EndDateUTC
       ,Duration_HhMmSsMs
	   ,TotalRecordsImported
	   ,TotalRecordsNotImported
  FROM dbo.v_TableRefreshHistory 
 WHERE (   ErrorNumber NOT IN (-1,-4)
        OR NumUrisNotNoRecordsReturned > 0
        OR NotAllRecordsImported = 'True'
        OR ImportErrorOccurred = 'True'
        OR EndDateUTC IS NULL
        )
   AND BatchID = (
                  SELECT TOP 1 ID
                    FROM dbo.PowerShellRefreshHistory
                   WHERE RunBy_User = SUSER_NAME()
                     AND JobName = @JobName
                   ORDER BY ID DESC
                  );

-- Trigger the alert...go ahead and create a table with the results of this query:
IF EXISTS (SELECT * FROM @Failures)
BEGIN
--------------------- UPDATE THESE VARIABLES FOR YOUR ENVIRONMENT! ----------------------------------------
DECLARE  @email_profile nvarchar(256) = N'DBA Email' -- A valid db mail profile name
        ,@emailrecipients nvarchar(500) = N'user@contoso.com;user2@contoso.com' -- semi-colon separated list of email addresses
        ,@emailCCrecipients nvarchar(500) = N'' -- semi-colon separated list of email addresses if desired
-----------------------------------------------------------------------------------------------------------
        ,@subject nvarchar(max) = N'"' + @JobName + N'" Job Failure Report at ' + @@SERVERNAME + ' server'
        ,@msgbodynontable nvarchar(max) = N'SQL Server Agent Job Failure Report For: "' + @JobName + N'"';

DECLARE @tableHTML nvarchar(max) = N'
<html>
<body>
    <H1>' + @msgbodynontable + N'</H1>
        <table border="1" style=
        "background-color: #C0C0C0; border-collapse: collapse">
        <caption style="font-weight: bold">
            ****** 
            Failure occurred in the SQL Agent job named: ''' + @JobName + N''' in at least one of the tables. 
            Below is the job failure detail for ALL tables of this job today without needing to connect to SSMS to check.
            ******
        </caption>

<tr>
    <th style="text-decoration: underline">ID</th>
	<th style="text-decoration: underline">Intune Table Name</th>
	<th style="text-decoration: underline">Error Message</th>
    <th style="text-decoration: underline">StartDateUTC</th>
	<th style="text-decoration: underline">EndDateUTC</th>
    <th style="text-decoration: underline">Duration_HhMmSsMs</th>
	<th style="text-decoration: underline">TotalRecordsImported</th>
    <th style="text-decoration: underline">TotalRecordsNotImported</th>
</tr>' + CAST((
               SELECT td = ID
                   ,''
                   ,td = TableName 
                   ,''
                   ,td = ErrorMessage
                   ,''
                   ,td = StartDateUTC
			   	,''
                   ,td = EndDateUTC 
                   ,''
                   ,td = Duration_HhMmSsMs
			   	 ,''
                   ,td = TotalRecordsImported
                   ,''
                   ,td = TotalRecordsNotImported
                 FROM @Failures
                ORDER BY ID DESC
                  FOR XML PATH('tr'),TYPE,ELEMENTS XSINIL
               ) AS nvarchar(max)
              ) + N'
    </table>
</body>
</html>';

-- Only send an email if the db mail profile exists:
IF EXISTS (
SELECT *
  FROM msdb.dbo.sysmail_profileaccount pra
       INNER JOIN msdb.dbo.sysmail_profile pro
          ON pra.profile_id = pro.profile_id
       INNER JOIN msdb.dbo.sysmail_account acc
          ON pra.account_id = acc.account_id
 WHERE pro.name = @email_profile
)
EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @email_profile
    ,@recipients = @emailrecipients
    ,@copy_recipients = @emailCCrecipients
    ,@subject = @subject
    ,@body = @tableHTML
    ,@body_format = 'HTML';

END;
END;
GO

IF OBJECT_ID(N'dbo.usp_JobFailureEmailAlert') IS NOT NULL
PRINT 'Sproc "usp_JobFailureEmailAlert" Created.';
ELSE
PRINT 'Sproc "usp_JobFailureEmailAlert" NOT CREATED...Check for errors!';
GO