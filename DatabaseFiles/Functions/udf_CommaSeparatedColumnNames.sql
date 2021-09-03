USE [Intune];
GO

/********************************************************************************************
    SET SESSION HANDLING INFO
********************************************************************************************/
SET NOCOUNT ON;
GO

--Could do: IF blah IS NULL ... EXECUTE (N'CREATE FUNCTION dbo.udf_SecondsToHrMinSecMs() RETURNS varchar(25) BEGIN RETURN ''''; END;');
IF OBJECT_ID(N'dbo.udf_CommaSeparatedColumnNames') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.udf_CommaSeparatedColumnNames;
    PRINT 'Function "udf_CommaSeparatedColumnNames" Deleted.';
END;
GO

/***************************************************************************************************************************
Object: dbo.udf_CommaSeparatedColumnNames
Purpose: This function returns a comma separated list of column names for a given Table/Object.

History:
Date          Version    Author                   Notes:
04/27/2021    0.0        Benjamin Reynolds        Separate file created for better source control and management.

***************************************************************************************************************************/


CREATE FUNCTION dbo.udf_CommaSeparatedColumnNames (@TableName nvarchar(300))
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @Columns nvarchar(max);
    
    SELECT @Columns = COALESCE(@Columns + N',', N'') + QUOTENAME(name)
      FROM sys.all_columns
     WHERE object_id = OBJECT_ID(@TableName)
     ORDER BY column_id;
    
    RETURN @Columns;
END;
GO

-- Since this can be run in batches via PowerShell we need to check for the existence before blindly saying it was created...it may have hit an error while creating:
IF OBJECT_ID(N'dbo.udf_CommaSeparatedColumnNames') IS NOT NULL
PRINT 'Function "udf_CommaSeparatedColumnNames" Created.';
GO
