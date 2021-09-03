# Get-SqlTableColumnDefinition
function Get-SqlTableColumnDefinition {
<#
.SYNOPSIS
    This function gets the column definition of a given SQL table
.DESCRIPTION
    The function will get the column name, type, nullable, order, and length for every column in the table
.PARAMETER SqlServerName
    This is the name of the SQL Server to connect to (using the caller's credentials).
    If no connection string is provided then the name of the server to connect to is required
.PARAMETER SqlDatabaseName
    This is the name of the database to connect to on the given server.
    If no connection string is provided then the name of the server to connect to is required
.PARAMETER SqlConnString
    This is a string that contains the connection string. It needs to contain the server and database at a minimum.
    If this is provided the SqlServerName and SqlDatabaseName parameters are not required.
.PARAMETER SqlCredentials
    This is an object of type "System.Data.SqlClient.SqlCredential" which contains the user and password (secured)
    If this is provided then the user/password in the credentials will be used to make the connection to SQL rather than the current user.
.PARAMETER SqlSchemaName
    This is the name of the schema the table is in.
    Required.
.PARAMETER SqlTableName
    This is the name of the table from which to get the column definition
    Required.
.PARAMETER SqlCommandTimeout
    The command timeout for the SQL command if something other than the default should be used.
.PARAMETER SqlConnTimeout
    The connection timeout for the SQL connection if something other than the default should be used.
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.EXAMPLE
    Get-SqlTableColumnDefinition -SqlServerName "MySQLServer" -SqlDatabaseName "MyDatabase" -SqlSchemaName "dbo" -SqlTableName "SomeTable";
    This will get the column definition for MySQLServer.MyDatabase.dbo.SomeTable using the caller's credentials.
.EXAMPLE
    Get-SqlTableColumnDefinition -SqlConnString "A connection string containing server and datbase" -SqlSchemaName "dbo" -SqlTableName "SomeTable";
    This will get the column defintion for the table dbo.SomeTable using the server and database in the connection string, using the caller's credentials.
.EXAMPLE
    Get-SqlTableColumnDefinition -SqlConnString "A connection string containing server and datbase" -SqlCredentials $SqlCreds -SqlSchemaName "dbo" -SqlTableName "SomeTable";
    This will get the column defintion for the table dbo.SomeTable using the server and database in the connection string, using the user/password in the credentials provided.
.NOTES
    NAME: Get-SqlTableColumnDefinition
    HISTORY:
        Date                Author                    Notes
        02/07/2018          Benjamin Reynolds         Initial Creation
        03/26/2018          Benjamin Reynolds         Added MaxLength
        08/02/2018          Benjamin Reynolds         Added functionality for SqlCreds (to connect to Azure) as a
                                                      better/more secure way than using a secure connection string...
        02/25/2021          Benjamin Reynolds         Added ColumnMapping info based on the table "TableColumnMappings" if exists
        03/08/2021          Benjamin Reynolds         Updated to use Invoke-SqlCommand rather than create its own connection so it just contains the logic required.
                                                      Updated ability to send credentials with either parameterset. Added SqlCommandTimeout and SqlConnTimeout.
        03/25/2021          Benjamin Reynolds         Updated Write-Verbose info to write to the log file if it exists - added LogFullPath parameter and logic to achieve this.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("SqlServer")][String]$SqlServerName
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("DatabaseName","Database")][String]$SqlDatabaseName
       ,[Parameter(Mandatory=$true,ParameterSetName='ConnString')][String]$SqlConnString
       ,[Parameter(Mandatory=$false)][Alias("SqlCreds")][System.Data.SqlClient.SqlCredential]$SqlCredentials
       ,[Parameter(Mandatory=$true)][Alias("SchemaName")][String]$SqlSchemaName
       ,[Parameter(Mandatory=$true)][Alias("TableName")][String]$SqlTableName
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    $SqlTableDefinition = New-Object -TypeName System.Collections.ArrayList;

    ## Create the query to run:
    $SqlTblDefQry = "IF OBJECT_ID(N'dbo.TableColumnMappings') IS NOT NULL
SELECT  col.name AS [Name]
       ,tip.NewType AS [Type]
       ,CASE col.is_nullable WHEN 1 THEN 'true' ELSE 'false' END AS [Nullable]
       ,col.column_id AS [ColumnOrder]
       ,CASE WHEN tip.NewType = 'String' AND col.max_length > 0 THEN col.max_length/2
             WHEN tip.NewType = 'Binary' AND col.max_length > 0 THEN col.max_length
        END AS [MaxLength]
       ,tcm.MappedColumnName
  FROM sys.objects obj
       INNER JOIN sys.columns col
          ON obj.object_id = col.object_id
       INNER JOIN sys.types typ
          ON col.user_type_id = typ.user_type_id
       INNER JOIN sys.schemas scm
          ON obj.schema_id = scm.schema_id
       CROSS APPLY (
                    SELECT CASE WHEN typ.name = N'bit' THEN 'Boolean'
                                WHEN typ.name = N'uniqueidentifier' THEN 'Guid'
                                WHEN typ.name = N'smallint' THEN 'Int16'
                                WHEN typ.name = N'int' THEN 'Int32'
                                WHEN typ.name = N'bigint' THEN 'Int64'
                                WHEN typ.name = N'tinyint' THEN 'UInt16'
                                WHEN typ.name IN (N'date',N'time',N'datetime2',N'datetimeoffset',N'smalldatetime',N'datetime',N'timestamp') THEN 'DateTime'
                                WHEN typ.name IN (N'real',N'money',N'float',N'decimal',N'numeric',N'smallmoney') THEN 'Decimal'
                                WHEN typ.name IN (N'binary',N'varbinary') THEN 'Binary'
                                ELSE 'String'
                           END
                    ) tip(NewType)
        LEFT OUTER JOIN dbo.TableColumnMappings tcm
          ON obj.name = tcm.TableName
         AND scm.name = tcm.SchemaName
         AND col.name = tcm.SqlColumnName
 WHERE scm.name = N'$SqlSchemaName'
   AND obj.name = N'$SqlTableName'
 ORDER BY col.column_id;
ELSE
SELECT  col.name AS [Name]
       ,tip.NewType AS [Type]
       ,CASE col.is_nullable WHEN 1 THEN 'true' ELSE 'false' END AS [Nullable]
       ,col.column_id AS [ColumnOrder]
       ,CASE WHEN tip.NewType = 'String' AND col.max_length > 0 THEN col.max_length/2
             WHEN tip.NewType = 'Binary' AND col.max_length > 0 THEN col.max_length
        END AS [MaxLength]
  FROM sys.objects obj
       INNER JOIN sys.columns col
          ON obj.object_id = col.object_id
       INNER JOIN sys.types typ
          ON col.user_type_id = typ.user_type_id
       INNER JOIN sys.schemas scm
          ON obj.schema_id = scm.schema_id
       CROSS APPLY (
                    SELECT CASE WHEN typ.name = N'bit' THEN 'Boolean'
                                WHEN typ.name = N'uniqueidentifier' THEN 'Guid'
                                WHEN typ.name = N'smallint' THEN 'Int16'
                                WHEN typ.name = N'int' THEN 'Int32'
                                WHEN typ.name = N'bigint' THEN 'Int64'
                                WHEN typ.name = N'tinyint' THEN 'UInt16'
                                WHEN typ.name IN (N'date',N'time',N'datetime2',N'datetimeoffset',N'smalldatetime',N'datetime',N'timestamp') THEN 'DateTime'
                                WHEN typ.name IN (N'real',N'money',N'float',N'decimal',N'numeric',N'smallmoney') THEN 'Decimal'
                                WHEN typ.name IN (N'binary',N'varbinary') THEN 'Binary'
                                ELSE 'String'
                           END
                    ) tip(NewType)
 WHERE scm.name = N'$SqlSchemaName'
   AND obj.name = N'$SqlTableName'
 ORDER BY col.column_id;";

    if ($PsCmdlet.ParameterSetName -eq 'ConnString')
    {
        $RetVal = Invoke-SqlCommand -SqlConnString $SqlConnString -SqlCredentials:$SqlCredentials -SqlCommandText $SqlTblDefQry -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout -ReturnTableData;
    }
    else
    {
        $RetVal = Invoke-SqlCommand -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlCredentials:$SqlCredentials -SqlCommandText $SqlTblDefQry -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout -ReturnTableData;
    }


    if ($RetVal.Value -eq -1)
    {
        ## There was an error, we'll just return a null object:
        #Write-Verbose "We hit an error trying to get the SqlTableDefinition. Error Captured:`r`n$($RetVal.ErrorCaptured)";
        Write-CmTraceLog -LogMessage "We hit an error trying to get the SqlTableDefinition. Error Captured:`r`n$($RetVal.ErrorCaptured)" -LogFullPath $LogFullPath -Component 'Get-SqlTableColumnDefinition' -MessageType Error -Verbose:$isVerbose;
    }
    else
    {
        $SqlTableDefinition = $RetVal.SqlTableData;
    }

    return $SqlTableDefinition;
    # doing this instead of the return will ensure that the ArrayList is the output instead of an Array:
    #Write-Output @(,($SqlTableDefinition));

} # End: Get-SqlTableColumnDefinition
