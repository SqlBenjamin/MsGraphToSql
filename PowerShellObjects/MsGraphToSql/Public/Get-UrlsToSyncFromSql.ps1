# Get-UrlsToSyncFromSql
function Get-UrlsToSyncFromSql {
<#
.SYNOPSIS
    This function is used to create an ArrayList of hashtables from a SQL table to use in the "Tables To Sync".
.DESCRIPTION
    When a SQL table exists containing the information about syncs that should be performed, this function retrieves that information.
.PARAMETER SqlServerName
    The name of the SQL Server to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlDatabaseName
    The name of the Database to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlConnString
    The entire connection string used to make the connection to SQL. If this is defined neither SqlServerName nor SqlDatabaseName are required.
.PARAMETER SqlCredentials
    This is a SqlClient.SqlCredential containing the user/password to use to make the connection to SQL (via SQL Auth). If this is not passed in the function will try to use the caller's credentials for WinAuth.
.PARAMETER SqlCommandTimeout
    The SQL command timeout (in seconds) to use while running a command/query against SQL.
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection.
.PARAMETER UrlsToSync
    This is how the function determines the list of URIs that need to be sync'd to SQL. For Example:
     - There are multiple options to define what is sync'd; the value of this parameter must start with one of the following values (description/example follows each):
       - "SqlFilter:"
          -Description: This is the portion that will be added to the WHERE clause of the SQL query. The default table name in this scenario is "dbo.MsGraphSyncToSqlMetaData", to get data from other tables or with different logic use one of the other keywords.
          -Example: "SqlFilter:JobName = N'ECM_IntuneSyncToSql_SomeJob' AND Enabled = 1"
       - "SqlQuery:"
          -Description: This is the entire query that should be run to get the data - it can be as simple or complex as desired.
          -Example: "SqlQuery:SELECT * FROM SomeDB.dbo.SomeNewMetaDataTable WHERE SomeCriteria = SomeValue;"
       - "SqlView:"
          -Description: This is the name of a view that contains the data; a "SELECT *" will be performed on the view name. Anything after the view name will be included as well.
          -Example: "SqlView:v_MetaDataTableViewName" OR "SqlView:dbo.v_MetaDataTableViewName WHERE Enabled = 1 AND SomethingElse = SomeValue ORDER BY Blah;"
       - "SqlProcedure:"
          -Description: This is the name of the stored procedure that returns the data. The "Execute" is optional.
          -Example: "SqlProcedure:usp_SomeSprocName" OR "SqlProcedure:EXECUTE dbo.usp_SomeSprocName;"
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.PARAMETER RetryThreshold
    This defines how many times to retry getting the information in the event there is an execution timeout error. The default is 3 retries.
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlFilter:ID = 123" -LogFullPath "F:\SomeFolder\SomeFileName.log";
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat), logs information to the file "F:\SomeFolder\SomeFileName.log", and runs the following query to get the UrlsToSync:
  SELECT * FROM dbo.MsGraphSyncToSqlMetaData WHERE ID = 123;
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlFilter:ID = 123";
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat) and runs the following query to get the UrlsToSync:
  SELECT * FROM dbo.MsGraphSyncToSqlMetaData WHERE ID = 123;
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlFilter:ID = 123" -Verbose;
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat), writes information to the console, and runs the following query to get the UrlsToSync:
  SELECT * FROM dbo.MsGraphSyncToSqlMetaData WHERE ID = 123;
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlProcedure:usp_SomeSprocName";
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat) and executes the "usp_SomeSprocName" procedure to get the UrlsToSync:
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlQuery:SELECT * FROM DB1.dbo.SomeTable;";
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat) and runs the provided query to get the UrlsToSync:
  SELECT * FROM DB1.dbo.SomeTable;
.EXAMPLE
  Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync "SqlFilter:ID = 123 AND IsEnabled = 1";
  This makes a connection to SQL based on the SQL Connection parameters passed in (via the splat) and runs the following query to get the UrlsToSync:
  SELECT * FROM dbo.MsGraphSyncToSqlMetaData WHERE ID = 123 AND IsEnabled = 1;
.OUTPUTS
    An ArrayList of Hashtables (each hashtable is a table record).
.NOTES
    NAME: Get-UrlsToSyncFromSql
    NOTE: "dbo.MsGraphSyncToSqlMetaData" is the default MetaData table where the information resides. To change this use one of the other keywords (SqlQuery,SqlProcedure,SqlView).
    HISTORY:
        Date                Author                    Notes
        04/19/2021          Benjamin Reynolds         Initial Creation
        05/24/2021          Benjamin Reynolds         Changed default table name from 'IntuneSyncToSqlMetaData' to 'MsGraphSyncToSqlMetaData'
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("SqlServer")][string]$SqlServerName
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("DatabaseName","Database")][string]$SqlDatabaseName
       ,[Parameter(Mandatory=$true,ParameterSetName='ConnString')][string]$SqlConnString
       ,[Parameter(Mandatory=$false)][System.Data.SqlClient.SqlCredential]$SqlCredentials
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
       ,[Parameter(Mandatory=$true)][string]$UrlsToSync
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
       ,[Parameter(Mandatory=$false)][int]$RetryThreshold=3
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    $ReturnObj = New-Object -TypeName System.Collections.ArrayList;
    
    if ($UrlsToSync -notlike 'Sql*:*')
    {
        #throw "UrlsToSync is not of the right format! Can't retrieve the proper information.";
        Write-CmTraceLog -LogMessage "UrlsToSync is not of the right format! Can't retrieve the proper information; returning a null object to caller." -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Error -Verbose:$isVerbose;
        #return $ReturnObj;
        return;
    }

    ## Create the query:
    [int]$chrInd = $UrlsToSync.IndexOf(':');
    [string]$SqlType = $UrlsToSync.Substring(0,$chrInd);
    [string]$SqlPart = $UrlsToSync.Substring($chrInd+1).Trim();
    [string]$SqlCommandText = $null;

    switch ($SqlType)
    {
        'SqlFilter'
        {
            # Any cleanup or validation needed?
            $SqlCommandText =
              "SELECT TableName,UriPart,Version,ExpandColumns,ExpandTableOrColumn,MetaDataEntityToUse,UriPartType,ReplacementTable,TargetTable,ParentCols,SkipGraphMetaDataCheck,SelectColumns,ReportName,ReportFilter "+
              "  FROM dbo.MsGraphSyncToSqlMetaData "+
              " WHERE $SqlPart"+
              " ORDER BY JobOrder;";
            break;
        }
        'SqlProcedure'
        {
            # Any cleanup or validation needed?
            $SqlCommandText = $SqlPart;
            break;
        }
        'SqlView'
        {
            # Any cleanup or validation needed?
            $SqlCommandText = "SELECT * FROM $SqlPart;";
            break;
        }
        'SqlQuery'
        {
            $SqlCommandText = $SqlPart;
            break;
        }
    }

    if ([String]::IsNullOrWhiteSpace($SqlCommandText))
    {
        #throw "Something went wrong;";
        Write-CmTraceLog -LogMessage "Something didn't work correctly. Can't create a SQL query to get the proper information; returning a null object to caller." -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Error -Verbose:$isVerbose;
        Write-CmTraceLog -LogMessage "UrlsToSync value passed in:r`n$UrlsToSync" -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Error -Verbose:$isVerbose;
        #return $ReturnObj;
        return;
    }

    [int]$Retry = 0;
    
    while ($Retry -lt $RetryThreshold)
    {
        Write-CmTraceLog -LogMessage "Trying to run the following query to get the Tables to Sync:`r`n$SqlCommandText" -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -Verbose:$isVerbose;

        if ($PsCmdlet.ParameterSetName -eq 'ConnString')
        {
            $RetVal = Invoke-SqlCommand -SqlConnString $SqlConnString -SqlCredentials:$SqlCredentials -SqlCommandText $SqlCommandText -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout -ReturnTableData;
        }
        else
        {
            $RetVal = Invoke-SqlCommand -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlCredentials:$SqlCredentials -SqlCommandText $SqlCommandText -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout -ReturnTableData;
        }
            
        if ($RetVal.Value -eq -1)
        {
            if ($RetVal.ErrorCaptured.Exception -like '*Execution Timeout Expired*' -or $RetVal.ErrorCaptured.Exception -like '*transport-level error*' -or $RetVal.ErrorCaptured.Exception -like '*connection was forcibly closed*')
            {
                $Retry += 1;
                $RetryOccurred = $true;
                Write-CmTraceLog -LogMessage "We caught an 'Execution Timeout Expired' error so will try again. Retry: $Retry of $RetryThreshold." -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Warning -Verbose:$isVerbose;
                
                if ($null -eq $SqlCommandTimeout)
                {
                    Write-CmTraceLog -LogMessage "Setting the CommandTimeout to 60 seconds." -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -Verbose:$isVerbose;
                    $SqlCommandTimeout = 60;
                }
                
                if ($Retry -eq $RetryThreshold)
                {
                    $ErrorCaptured = $RetVal.ErrorCaptured;
                    Write-CmTraceLog -LogMessage "We hit the 'Execution Timeout Expired', 'Transport-Level', or 'forcibly closed' error for the last number of retries ($RetryThreshold); returning to caller. Error Captured:`r`n$($RetVal.ErrorCaptured)" -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Error -Verbose:$isVerbose;
                }
            }
            else
            {
                Write-CmTraceLog -LogMessage "Unhandled Error Encountered. Returning to caller. Error Captured:`r`n$($RetVal.ErrorCaptured)" -LogFullPath $LogFullPath -Component 'Get-UrlsToSyncFromSql' -MessageType Error -Verbose:$isVerbose;
                $Retry = $RetryThreshold+1;
            }
        }
        else
        {
            $ReturnObj = $RetVal.SqlTableData;
            
            # stop the while loop
            $Retry = $RetryThreshold+1;
        }
        Remove-Variable -Name RetVal -ErrorAction SilentlyContinue;
    } # end while loop (to handle retries)

    return $ReturnObj;
} # End: Get-UrlsToSyncFromSql
