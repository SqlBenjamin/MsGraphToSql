USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

--Could do: IF blah IS NULL ... EXECUTE (N'CREATE FUNCTION dbo.udf_SecondsToHrMinSecMs() RETURNS varchar(25) BEGIN RETURN ''''; END;');
IF OBJECT_ID(N'dbo.udf_MsToHrMinSecMs') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.udf_MsToHrMinSecMs;
    PRINT 'Function "udf_MsToHrMinSecMs" Deleted.';
END;
GO

/***************************************************************************************************************************
Object: dbo.udf_MsToHrMinSecMs
Purpose: This function takes the number of milliseconds provided and returns the number of hours, minutes, seconds,
         and milliseconds in the format of: hh<h>.mm.ss.mmm. EX: 34235244 milliseconds would be "09.30.35.244"

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.

***************************************************************************************************************************/

CREATE FUNCTION dbo.udf_MsToHrMinSecMs (@Ms bigint)
RETURNS varchar(25)
AS

BEGIN
DECLARE @Negative varchar(1) = '';
IF @Ms < 0
BEGIN
    SELECT  @Negative = '-'
           ,@Ms = ABS(@Ms);
END;
RETURN CASE WHEN (@Ms/1000) < 86400 THEN REPLACE(CONVERT(varchar(10),DATEADD(second,(@Ms/1000),0),8),':','.')+'.'+RIGHT('000'+CONVERT(varchar(3),CONVERT(int,ROUND(@Ms%1000,0))),3)
            ELSE CONVERT(varchar(13),CONVERT(bigint,ROUND(@Ms/1000,0,1))/3600)+'.'
                 +RIGHT('0'+CONVERT(varchar(2),CONVERT(bigint,ROUND(@Ms/1000,0,1)) % 3600/60),2)+'.'
                 +RIGHT('0'+CONVERT(varchar(2),CONVERT(bigint,ROUND(@Ms/1000,0,1)) % (3600/60)),2)+'.'
                 +RIGHT('000'+CONVERT(varchar(3),CONVERT(bigint,ROUND(@Ms%1000,0))),3)
       END;
END;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.udf_MsToHrMinSecMs') IS NOT NULL
PRINT 'Function "udf_MsToHrMinSecMs" Created.';
ELSE
PRINT 'Function "udf_MsToHrMinSecMs" NOT CREATED...Check for errors!';
GO
