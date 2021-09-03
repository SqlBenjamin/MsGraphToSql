# Invoke-SqlTruncate
function Invoke-SqlTruncate {
<#
.SYNOPSIS
    This function truncates a table based on the schema and table names provided. The truncate is run as part of a try/catch.
.DESCRIPTION
    The function will try to truncate a provided table and if successful the value returned will be "0|Successful". If it fails the return value is the ErrorNumber|ErrorMessage.
    A ConnectionString or a Server/DB can be passed in for either SQL Auth or WinAuth connections. However, if connecting via SQL Auth a SqlCredential is required to make the connection securely.
.PARAMETER SqlServerName
    The name of the SQL Server to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlDatabaseName
    The name of the Database to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlConnString
    The entire connection string used to make the connection to SQL. If this is defined neither SqlServerName nor SqlDatabaseName are required.
.PARAMETER SqlCredentials
    This is a SqlClient.SqlCredential containing the user/password to use to make the connection to SQL (via SQL Auth). If this is not passed in the function will try to use the caller's credentials for WinAuth.
.PARAMETER SchemaName
    This is the name of the SQL schema in which the table to truncate resides.
.PARAMETER TableName
    This is the name of the SQL table which should be truncated.
.PARAMETER SqlCommandTimeout
    The SQL command timeout (in seconds) to use while running a command/query against SQL.
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection.
.PARAMETER RetryThreshold
    This defines how many times to retry getting the information in the event there is an execution timeout error. The default is 3 retries.
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.EXAMPLE
    Invoke-SqlTruncate -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SchemaName "dbo" -TableName "MyTable";
    This will use the connection string to connect to MySqlServer/MyDb with the caller's credentials and try to truncate the table dbo.MyTable.
.EXAMPLE
    Invoke-SqlTruncate -SqlServerName "MySqlServer" -SqlDatabaseName "MyDb" -SchemaName "dbo" -TableName "MyTable";
    This will connect to MySqlServer/MyDb with the caller's credentials and try to truncate the table dbo.MyTable.
.EXAMPLE
    Invoke-SqlTruncate -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlCredentials $SqlCredentialsCreatedPreviously -SchemaName "dbo" -TableName "MyTable";
    This will use the connection string to connect to MySqlServer/MyDb using the user/password in the variable "SqlCredentialsCreatedPreviously" and try to truncate the table dbo.MyTable.
.EXAMPLE
    Invoke-SqlTruncate -SqlServerName "MySqlServer" -SqlDatabaseName "MyDb" -SqlCredentials $SqlCredentialsCreatedPreviously -SchemaName "dbo" -TableName "MyTable";
    This will connect to MySqlServer/MyDb with the user/password in the variable "SqlCredentialsCreatedPreviously" and try to truncate the table dbo.MyTable.
.OUTPUTS
    An object (ArrayList) with the following property(ies):
    -Value = either -1 (failure) or 0 (success) 
    -ErrorCaptured = this property contains the information if an error was caught and only exists if an error was caught
.NOTES
    NAME: Invoke-SqlTruncate
    HISTORY:
        Date                Author                    Notes
        08/27/2018          Benjamin Reynolds         Initial Creation
        01/28/2021          Benjamin Reynolds         Added Retry logic for timeouts and forcibly closed connections along with CommandTimeout parameter.
        03/08/2021          Benjamin Reynolds         Updated to use Invoke-SqlCommand rather than create its own connection so it just contains the logic required.
        03/25/2021          Benjamin Reynolds         Updated Write-Verbose info to write to the log file if it exists - added LogFullPath parameter and logic to achieve this. Added SqlConnTimeout.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("SqlServer")][string]$SqlServerName
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("DatabaseName","Database")][string]$SqlDatabaseName
       ,[Parameter(Mandatory=$true,ParameterSetName='ConnString')][string]$SqlConnString
       ,[Parameter(Mandatory=$false)][System.Data.SqlClient.SqlCredential]$SqlCredentials
       ,[Parameter(Mandatory=$true)][Alias("SqlSchemaName")][string]$SchemaName
       ,[Parameter(Mandatory=$true)][Alias("SqlTableName")][string]$TableName
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
       ,[Parameter(Mandatory=$false)][int]$RetryThreshold=3
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    $ReturnObj = New-Object System.Collections.ArrayList;
    
    ## Create the query:
    $SqlQry = "BEGIN TRY
TRUNCATE TABLE $SchemaName.$TableName;
SELECT N'0|Successful' AS [ReturnValue];
END TRY
BEGIN CATCH
SELECT CONVERT(nvarchar(100),ERROR_NUMBER())+N'|'+ERROR_MESSAGE() AS [ReturnValue];
END CATCH";

    [int]$Retry = 0;
    
    while ($Retry -lt $RetryThreshold)
    {
            if ($PsCmdlet.ParameterSetName -eq 'ConnString')
            {
                $RetVal = Invoke-SqlCommand -SqlConnString $SqlConnString -SqlCredentials:$SqlCredentials -SqlCommandText $SqlQry -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout;
            }
            else
            {
                $RetVal = Invoke-SqlCommand -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlCredentials:$SqlCredentials -SqlCommandText $SqlQry -SqlCommandTimeout:$SqlCommandTimeout -SqlConnTimeout:$SqlConnTimeout;
            }

            if ($RetVal.Value -eq -1)
            {
                if ($RetVal.ErrorCaptured.Exception -like '*Execution Timeout Expired*' -or $RetVal.ErrorCaptured.Exception -like '*transport-level error*' -or $RetVal.ErrorCaptured.Exception -like '*connection was forcibly closed*')
                {
                    $Retry += 1;
                    $RetryOccurred = $true;
                    #Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : We caught an 'Execution Timeout Expired' error so will try again. Retry: $Retry of $RetryThreshold...";
                    Write-CmTraceLog -LogMessage "We caught an 'Execution Timeout Expired' error so will try again. Retry: $Retry of $RetryThreshold." -LogFullPath $LogFullPath -Component 'Invoke-SqlTruncate' -MessageType Warning -Verbose:$isVerbose;
                    
                    if ($null -eq $SqlCommandTimeout)
                    {
                        #Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Setting the CommandTimeout to 60 seconds...";
                        Write-CmTraceLog -LogMessage "Setting the CommandTimeout to 60 seconds." -LogFullPath $LogFullPath -Component 'Invoke-SqlTruncate' -Verbose:$isVerbose;
                        $SqlCommandTimeout = 60;
                    }
                    
                    if ($Retry -eq $RetryThreshold)
                    {
                        $ErrorCaptured = $RetVal.ErrorCaptured;
                        #Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : We hit the 'Execution Timeout Expired', 'Transport-Level', or 'forcibly closed' error for the last number of retries ($RetryThreshold); returning to caller.";
                        Write-CmTraceLog -LogMessage "We hit the 'Execution Timeout Expired', 'Transport-Level', or 'forcibly closed' error for the last number of retries ($RetryThreshold); returning to caller." -LogFullPath $LogFullPath -Component 'Invoke-SqlTruncate' -MessageType Error -Verbose:$isVerbose;
                    }
                }
                else
                {
                    $ErrorCaptured = $RetVal.ErrorCaptured;
                    #Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unhandled Error Encountered. Returning to caller.";
                    Write-CmTraceLog -LogMessage "Unhandled Error Encountered. Returning to caller." -LogFullPath $LogFullPath -Component 'Invoke-SqlTruncate' -MessageType Error -Verbose:$isVerbose;
                    $Retry = $RetryThreshold+1;
                }
            }
            else
            {
                # this is for when we 'succeed' in running the command but the command itself caught an error:
                if ($RetVal.SqlColVal -ne '0|Successful')
                {
                    $ErrorCaptured = $RetVal.SqlColVal;
                }
                
                # stop the while loop
                $Retry = $RetryThreshold+1;
            }
            Remove-Variable -Name RetVal -ErrorAction SilentlyContinue;
    } # end while loop (to handle retries)

    ## Create the return object (include the error if one was caught):
    if ($ErrorCaptured)
    {
        if ($RetryOccurred)
        {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"ErrorCaptured" = $ErrorCaptured;"Value" = -1;"RetryOccurred" = $true;"NumberOfRetries" = $Retry;"RetryThreshold" = $RetryThreshold};
        }
        else
        {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"ErrorCaptured" = $ErrorCaptured;"Value" = -1};
        }
        [void]$ReturnObj.Add($TmpRtnObj);
    }
    else
    {
        if ($RetryOccurred)
        {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"Value" = 0;"RetryOccurred" = $true;"NumberOfRetries" = $Retry;"RetryThreshold" = $RetryThreshold};
        }
        else
        {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"Value" = 0};
        }
        
        [void]$ReturnObj.Add($TmpRtnObj);
    }

    return $ReturnObj;
} # End: Invoke-SqlTruncate
