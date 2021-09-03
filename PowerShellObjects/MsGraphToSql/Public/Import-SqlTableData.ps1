# Import-SqlTableData
function Import-SqlTableData {
<#
.SYNOPSIS
    This function uses BCP to load data into a SQL table.
.DESCRIPTION
    This function connects to a given SQL Server and database and tries to import the data provided using Bulk Copy.
    A "DataTable" containing the data to import is required in order for the function to properly use Bulk Copy.
    To determine the SQL Server and database to run the command against either the Server/DB need to be passed in or a SQL Connection String.
    If no "SqlCredentials" are passed in then the current user's credentials will be used to try and create the connection; otherwise the
    credentials securely stored in the SqlCredential will be used to make the connection.
.PARAMETER SqlServerName
    The name of the SQL Server to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlDatabaseName
    The name of the Database to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlConnString
    The entire connection string used to make the connection to SQL. If this is defined neither SqlServerName nor SqlDatabaseName are required.
.PARAMETER SqlCredentials
    This is a SqlClient.SqlCredential containing the user/password to use to make the connection to SQL. If this is not passed in the function will try to use the current user's credentials
.PARAMETER SchemaName
    This is the name of the SQL schema in which the table to import data resides.
.PARAMETER TableName
    This is the name of the SQL table which should get the data loaded.
.PARAMETER ImportData
    This is a DataTable containing the data to import.
.PARAMETER BulkCopyTimeout
    This is an optional parameter which can be used to control the "BulkCopyTimeout" property of the Bulk Copy.
.PARAMETER BulkCopyBatchSize
    This is an optional parameter which can be used to control the "BatchSize" property of the Bulk Copy.
.PARAMETER TimeoutRetryThreshold
    This controls how many times the function should retry the import if it catches a "Execution Timeout Expired" error. The default is 3.
.PARAMETER ColumnMapping
    This allows specific column mappings to be passed in. This should be an ArrayList containing the Source and Destination indexes or names.
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection.
.EXAMPLE
    Import-SqlTableData -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SchemaName dbo -TableName MyTable -ImportData $A_DataTable_Object_Containing_Data;
    This will connect to MySqlServer/MyDb using the caller's credentials and import the data in the variable "A_DataTable_Object_Containing_Data" into the SQL table "dbo.MyTable".
.EXAMPLE
    Import-SqlTableData -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlCredentials $SqlCredentialsCreatedPreviously -SchemaName dbo -TableName MyTable -ImportData $A_DataTable_Object_Containing_Data;
    This will connect to MySqlServer/MyDb using the user/password credentials from the variable "SqlCredentialsCreatedPreviously" and import the data in the variable "A_DataTable_Object_Containing_Data" into the SQL table "dbo.MyTable".
.OUTPUTS
    An object (ArrayList) with the following property(ies):
    -Value = either -1 (failure) or 0 (success) 
    -ErrorCaptured = this property contains the information if an error was caught
    -RetryOccurred = this property exists if the function hit a timeout and performed at least one retry
    -NumberOfRetries = if the function hit a timeout and performed any retries, this will tell how many times it retried
    -TimeoutRetryThreshold = if the function hit a timeout and performed any retries, this will tell what the threshold was for the number of retries to perform
.NOTES
    NAME: Import-SqlTableData
    HISTORY:
        Date                Author                    Notes
        08/27/2018          Benjamin Reynolds         Initial Creation
        09/24/2018          Benjamin Reynolds         Added Command timeout,Batch Size, and timeoutretrythreshold parameters; added error handling for the command timeout
        10/12/2020          Benjamin Reynolds         The command timeout didn't work correctly (with a value of 0) so updated logic and added the default value. Also added an elapsed time for verbose output.
        01/27/2021          Benjamin Reynolds         Added the ColumnMapping parameter and functionality. (Necessary for the report export API stuff).
        01/28/2021          Benjamin Reynolds         Added retries for transport-level errors - when the connection is forcibly closed for some reason.
        03/08/2021          Benjamin Reynolds         Updated Connection string validation and ability to send credentials with either parameterset.
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
       ,[Parameter(Mandatory=$true)][Alias("DataTable")][System.Data.DataTable]$ImportData
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyBatchSize
       ,[Parameter(Mandatory=$false)][int]$TimeoutRetryThreshold=3
       ,[Parameter(Mandatory=$false)][Alias("ColumnMappingArrayList","ColumnMappingCollection")][System.Collections.ArrayList]$ColumnMapping
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
       #,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout use BulkCopyTimeout instead
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    $RowCount = $ImportData.Rows.Count;

    #Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Attempting to load data ($RowCount rows) into SQL table '$SchemaName.$TableName'...";
    Write-CmTraceLog -LogMessage "Attempting to load data ($RowCount rows) into SQL table '$SchemaName.$TableName'..." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -Verbose:$isVerbose;
    
    $ReturnObj = New-Object System.Collections.ArrayList;

    ## Create the connection to SQL:
    try
    {
        ## if the connection string was sent then this will validate that it's a valid connection string, if its null then it'll create an empty object which we'll populate:
        $SqlConnBuilder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new($SqlConnString);

        if ([String]::IsNullOrWhiteSpace($SqlConnBuilder.ConnectionString))
        {
            $SqlConnBuilder['Server'] = $SqlServerName;
            $SqlConnBuilder['Database'] = $SqlDatabaseName;
            if ($null -ne $SqlConnTimeout)
            {
                $SqlConnBuilder['Connection Timeout'] = $SqlConnTimeout;
            }
            
        }
        
        if ($null -ne $SqlCredentials) # Use SQL Authentication:
        {
            $SqlConn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $SqlConnBuilder.ConnectionString, $SqlCredentials;
        }
        else # Use Windows Authentication:
        {
            $SqlConnBuilder['Integrated Security'] = $true;
            $SqlConn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $SqlConnBuilder.ConnectionString;
        }
    }
    catch
    {
        $ErrorCaptured = $PSItem;
        $StopFunction = $true;
    }    
    
    if (-Not $StopFunction)
    {
        [int]$TransportRetryThreshold = 3;

        [int]$TimeoutRetry = 0;
        [int]$TransportRetry = 0;

        ## Connect to SQL and import the data:
        while ($TimeoutRetry -lt $TimeoutRetryThreshold -and $TransportRetry -lt $TransportRetryThreshold) {
            try {
                $SqlConn.Open();
                $SqlBulkCopy = New-Object -TypeName System.Data.SqlClient.SqlBulkCopy -ArgumentList $SqlConn;
                if ($null -ne $BulkCopyTimeout) {# default is 30 seconds; 0 = indefinite; 
                    $SqlBulkCopy.BulkCopyTimeout = $BulkCopyTimeout;
                }
                if ($null -ne $BulkCopyBatchSize) {# default is all records;
                    $SqlBulkCopy.BatchSize = $BulkCopyBatchSize;
                }
                $SqlBulkCopy.DestinationTableName = "$SchemaName.$TableName";

                if ($null -ne $ColumnMapping)
                {
                    foreach ($ColMap in $ColumnMapping)
                    {
                        $curColMap = New-Object -TypeName System.Data.SqlClient.SqlBulkCopyColumnMapping -ArgumentList $ColMap.Source,$ColMap.Destination;

                        [void]$SqlBulkCopy.ColumnMappings.Add($curColMap);
                    }
                }

                $StartTime = $(Get-Date);
                $SqlBulkCopy.WriteToServer($ImportData);
                $ElapsedTime = $(Get-Date) - $StartTime;
                $TimeoutRetry = $TimeoutRetryThreshold+1;
                Write-CmTraceLog -LogMessage "Data Loaded in $("{0:HH:mm:ss.fff}" -f [datetime]$ElapsedTime.Ticks)" -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -Verbose:$isVerbose;
                ## Test for all data imported??
            }
            catch {
                if ($PSItem.Exception -like '*Execution Timeout Expired*') {
                    $TimeoutRetry += 1;
                    $RetryOccurred = $true;
                    Write-CmTraceLog -LogMessage "We caught an 'Execution Timeout Expired' error so will try again. Retry: $TimeoutRetry of $TimeoutRetryThreshold..." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -MessageType Warning -Verbose:$isVerbose;

                    if ($null -eq $BulkCopyTimeout) {
                        Write-CmTraceLog -LogMessage "Setting the BulkCopyTimeout to 60 seconds..." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -Verbose:$isVerbose;
                        $BulkCopyTimeout = 60;
                    }
                
                    if ($TimeoutRetry -eq $TimeoutRetryThreshold) {
                        $ErrorCaptured = $PSItem;
                        Write-CmTraceLog -LogMessage "We hit the 'Execution Timeout Expired' error for the last number of retries ($TimeoutRetryThreshold); returning to caller." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -MessageType Error -Verbose:$isVerbose;
                    }
                }
                elseif ($PSItem.Exception -like '*transport-level error*' -or $PSItem.Exception -like '*connection was forcibly closed*')
                {
                    $TransportRetry += 1;
                    $RetryOccurred = $true;
                    Write-CmTraceLog -LogMessage "We caught a 'Transport-Level' error so will try again. Retry: $TransportRetry of $TransportRetryThreshold..." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -MessageType Warning -Verbose:$isVerbose;

                    if ($TransportRetry -eq $TransportRetryThreshold)
                    {
                        $ErrorCaptured = $PSItem;
                        Write-CmTraceLog -LogMessage "We hit the 'Transport-Level' error for the last number of retries ($TransportRetryThreshold); returning to caller." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -MessageType Error -Verbose:$isVerbose;
                    }
                }
                else {
                    $ErrorCaptured = $PSItem;
                    Write-CmTraceLog -LogMessage "Unhandled Error Encountered. Returning to caller." -LogFullPath $LogFullPath -Component 'Import-SqlTableData' -MessageType Error -Verbose:$isVerbose;
                    $TimeoutRetry = $TimeoutRetryThreshold+1;
                }
            }
            finally { # Make sure to close the connection whether successful or not
                if ($SqlBulkCopy) {$SqlBulkCopy.Close();}
                if ($SqlConn) {$SqlConn.Close();}
            }
        } # end while loop (to handle retries)

    }
    
    ## Create the return object (include the error if one was caught):
    if ($ErrorCaptured) {
        if ($RetryOccurred) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"ErrorCaptured" = $ErrorCaptured;"Value" = -1;"RetryOccurred" = $true;"NumberOfTimeoutRetries" = $TimeoutRetry;"TimeoutRetryThreshold" = $TimeoutRetryThreshold;"NumberOfTransportRetries" = $TransportRetry;"TransportRetryThreshold" = $TransportRetryThreshold};
        }
        else {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"ErrorCaptured" = $ErrorCaptured;"Value" = -1};
        }
        [void]$ReturnObj.Add($TmpRtnObj);
    }
    else {
        if ($RetryOccurred) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"Value" = 0;"RetryOccurred" = $true;"NumberOfTimeoutRetries" = $TimeoutRetry;"TimeoutRetryThreshold" = $TimeoutRetryThreshold;"NumberOfTransportRetries" = $TransportRetry;"TransportRetryThreshold" = $TransportRetryThreshold};
        }
        else {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"Value" = 0};
        }
        [void]$ReturnObj.Add($TmpRtnObj);
    }

    return $ReturnObj;
} # End: Import-SqlTableData
