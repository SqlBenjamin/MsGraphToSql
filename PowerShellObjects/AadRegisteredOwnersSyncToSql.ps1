<#
.SYNOPSIS
    This script is used to sync the registeredOwners information from AAD to a SQL database. 
.DESCRIPTION
    This script pulls the registeredOwners data from AAD (via MS Graph) and stores the data in a SQL db.
    This is very similar to "IntuneSyncToSql.ps1" but is used specifically to get the registeredOwners information from AAD;
    The URI used is: "devices?$filter=deviceId eq '{azureADDeviceId}'&$select=id,deviceid&$expand=registeredOwners"
.PARAMETER SqlServerName
    The name of the SQL Server to which the Intune data will be saved.
.PARAMETER GraphUser
    The user or MSI used to authenticate with Graph (what to use to get the access token).
.PARAMETER SqlDatabaseName
    The name of the database where the data is to be stored. The default is "Intune".
.PARAMETER SqlSchemaName
    The schema in the database in which the tables to use for storing data reside. The default is "dbo".
.PARAMETER WriteBatchSize
    The script is capable of writing the data in batches, use this to better control the size of the batches to use (per URI). A batch is the number of records that will be collected before writing the data
    to SQL and starting to collect the data again. This is only applicable when paging through Graph for the data. The default batch size is 100,000,000 (essentially, no batching at all).
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection. The default is 240.
.PARAMETER SqlLoggingTableName
    The name of the table in the database used for logging the script's (or the batch) information. The default is "PowerShellRefreshHistory".
.PARAMETER SqlLoggingByTableName
    The name of the table in the database used for logging each URI/Table's information. The default is "TableRefreshHistory".
.PARAMETER SqlLoggingTableJobName
    The name of the job to log for greater control. Default is NULL.
.PARAMETER ApplicationId
    The App Id to use when authenticating to Graph with app/user.
.PARAMETER RedirectUri
    The redirect URI for the ApplicationId when authenticating to Graph with app/user.
.PARAMETER GraphUserIsMSI
    If the script is going to connect to Graph via an MSI then this flag is required. Note: the GraphUser parameter will be the id of the MSI.
.PARAMETER BulkCopyTimeout
    This can be used to control how long the script will wait for the bulk copy 'writetoserver' before timing out.
.PARAMETER BulkCopyBatchSize
    This can be used to control the batch size used in the bulk copy of data to SQL.
.PARAMETER BulkCopyTimeoutRetries
    This can be used to control how many times the 'writetoserver' function will retry (default is 3).
.PARAMETER AuthUrl
    This is the URL used to create the authentication for a user...the "Authority" to use. The default is 'https://login.microsoftonline.com/common/'.
.PARAMETER BaseURL
    This is the "Audience" to use in all the calls to Graph. It is the "base" portion of the URL to use. The default is 'https://graph.microsoft.com/'.
.PARAMETER LogFullPath
    If a log file should be written to then the full path to that ".log" file should be passed here. Instead of (or in addition to) writing to a log file the "Verbose" flag can be used to write the log information to the host.
.EXAMPLE
    .\AadRegisteredOwnersSyncToSql.ps1 -SqlServerName MySqlServer -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -GraphUserIsMSI;
    This will sync the registeredOwners data from the devices endpoint into MySqlServer.<Intune>.dbo.AzureAdJoinedRegisteredOwners.
.NOTES
   NAME: AadRegisteredOwnersSyncToSql.ps1
    HISTORY:
        Date          Author                    Notes
        06/17/2021    Benjamin Reynolds         Initial Creation.
        06/24/2021    Benjamin Reynolds         Several additions made after testing to ensure logging and stuff works as expected
#>
[cmdletbinding(PositionalBinding=$false)]
param (
     [Parameter(Mandatory=$true)][Alias("SqlServer")][string]$SqlServerName
    ,[Parameter(Mandatory=$true)][string]$GraphUser
    ,[Parameter(Mandatory=$false)][Alias("DatabaseName","Database")][string]$SqlDatabaseName = 'Intune'
    ,[Parameter(Mandatory=$false)][Alias("SchemaName","Schema")][string]$SqlSchemaName = 'dbo'
    ,[Parameter(Mandatory=$false)][int64]$WriteBatchSize = 100000000
    ,[Parameter(Mandatory=$false)][Alias("ConnectionTimeout","ConnTimeout")][int]$SqlConnTimeout = 240
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingTableName = 'PowerShellRefreshHistory'
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingByTableName = 'TableRefreshHistory'
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingTableJobName
    ,[Parameter(Mandatory=$false)][Alias("GraphApplicationId")][string]$ApplicationId
    ,[Parameter(Mandatory=$false)][Alias("GraphApplicationIdRedirectUri")][string]$RedirectUri
    ,[Parameter(Mandatory=$false)][switch]$GraphUserIsMSI
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyTimeout = 300
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyBatchSize = 50000
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyTimeoutRetries
    ,[Parameter(Mandatory=$false)][Alias("Authority")][string]$AuthUrl = 'https://login.microsoftonline.com/common/'
    ,[Parameter(Mandatory=$false)][Alias("Audience")][string]$BaseURL = 'https://graph.microsoft.com/'
    ,[Parameter(Mandatory=$false)][ValidateScript({(Test-Path -Path (Split-Path $PSItem)) -and ((Split-Path -Path $PSItem -Leaf).EndsWith(".log"))})][string]$LogFullPath
)

## Any script specific functions?

## Declare Working Variables and Validate:
[string]$scriptName = Split-Path $PSCmdlet.MyInvocation.MyCommand.Source -Leaf;
[bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;
[bool]$StopScript = $false;

Write-CmTraceLog -LogMessage "*************************** Script Starting... ***************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

## Create SQL ConnectionString (use builder to ensure everything is good to go):
$SqlConnStringBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
$SqlConnStringBuilder['Server'] = $SqlServerName;
$SqlConnStringBuilder['Database'] = $SqlDatabaseName;
$SqlConnStringBuilder['Connection Timeout'] = $SqlConnTimeout;
$SqlConnStringBuilder['Integrated Security'] = $true;

$SqlConnSplat = @{SqlConnString = $SqlConnStringBuilder.ConnectionString};
$SqlConnSplat.Add("SqlConnTimeout",$SqlConnTimeout);

## Create common SQL Importing Splat object:
$ImportSplatParams = @{};
if ($null -ne $BulkCopyTimeout) {
    $ImportSplatParams.Add("BulkCopyTimeout", $BulkCopyTimeout);
}
if ($null -ne $BulkCopyTimeoutRetries) {
    $ImportSplatParams.Add("TimeoutRetryThreshold", $BulkCopyTimeoutRetries);
}

## Build the Graph Authentication String to be used:
<#### Should I start using an object rather than a string to do all this? (Look at the "NEW DEV" file for this) ####>
if ($GraphUserIsMSI -eq $true) {
    $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -IsMSI -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
}
else {
    if ($ApplicationId -and $RedirectUri) {
        $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -ApplicationId '$ApplicationId' -RedirectUri '$RedirectUri' -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
    else {
        $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
}

#region : Log to SQL Table - Start of Script:
# Build and Run the insert command:
[string]$SqlLogCmd = Set-LogToSqlCommand -JobName $SqlLoggingTableJobName -LogToTable "$SqlSchemaName.$SqlLoggingTableName";
$SqlLogTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
# Check if logging to SQL was successful or not:
if ($SqlLogTblIdObj.Value -eq 0) {#successful
    $SqlLogTblId = $SqlLogTblIdObj.SqlColVal;
    Write-CmTraceLog -LogMessage "Successfully logged the start of the refresh to SQL table; Log ID = $SqlLogTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
}
else {
    Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
}
Remove-Variable -Name SqlLogTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
#endregion

#region : Connect to Graph:
 # If no Auth exists or it is going to expire within 10 minutes (ExpiresOn exists for user/app auth; expires_on exists for MSI auth):
if (    (-not $Global:ADAuthResult)  `
    -or (    ($null -ne $Global:ADAuthResult.ExpiresOn -and ($Global:ADAuthResult.ExpiresOn.datetime - $((Get-Date).ToUniversalTime())).Minutes -le 10)  `
         -or ($null -ne $Global:ADAuthResult.expires_on -and ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on)) - (Get-Date)).Minutes -le 10) `
         ) `
    )
{
    if ($GraphUserIsMSI -eq $true) {
        Write-CmTraceLog -LogMessage "Connecting to Graph using an MSI..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        Invoke-Expression $GetAuthStringCmd;
    }
    else {
        Write-CmTraceLog -LogMessage "Connecting to Graph using current user..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        Invoke-Expression $GetAuthStringCmd;
    }
}
else {
    Write-CmTraceLog -LogMessage "A Connection to Graph Has already been established...moving on..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
} # End of Connecting/Authenticating

Write-CmTraceLog -LogMessage "Connected to Graph" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
#endregion


#$Url = "devices?`$filter=deviceId eq '{azureADDeviceId}'&`$expand=registeredOwners";
$Url = "devices?`$filter=deviceId eq '{azureADDeviceId}'&`$select=id,deviceid&`$expand=registeredOwners";
$UriVersion = 'v1.0';
[string]$SqlTableName = 'AzureAdJoinedRegisteredOwners';


#region : Log to SQL Table - start of table
# Build and Run the insert command:
[string]$SqlLogCmd = Set-LogToSqlCommand -TableToLog $SqlTableName -BatchId $SqlLogTblId -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
$SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
# Check results:
if ($SqlLogByTblIdObj.Value -eq 0) {#successful
    $SqlLogByTblId = $SqlLogByTblIdObj.SqlColVal
    Write-CmTraceLog -LogMessage "Successfully logged the start of the refresh of table '$SqlTableName' to SQL table; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
}
else {# failure
    Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
}
Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
#endregion


#region : Get Sql Table Definition:  ## Should we explicitly cast this as "[System.Collections.ArrayList]"??
$EntityColDef = New-Object -TypeName System.Collections.ArrayList;
[void]$EntityColDef.Add($(New-Object -TypeName PSCustomObject -Property @{"DataName" = "";"Name" = "";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"}));
$SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $(Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $SqlTableName) -LogFullPath $LogFullPath -Verbose:$isVerbose;
#endregion


#region : Get the drill down ids to query for
[string]$SqlSelectCmd = "SELECT DISTINCT azureADDeviceId FROM dbo.v_IntuneHybridAadjOwners;";
$SqlDataObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlSelectCmd -ReturnTableData;

if ($SqlDataObj.Value -eq 0) {#successful
    $CurReplacementObj = $SqlDataObj.SqlTableData;
    Remove-Variable -Name SqlDataObj,SqlSelectCmd -ErrorAction SilentlyContinue;
}
else {# failure
    Write-CmTraceLog -LogMessage "Failed to get data from SQL." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    Write-CmTraceLog -LogMessage "Select statement used: $SqlSelectCmd" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlDataObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    
    ## Log the failure and 'skip' to Sql:
    if ($SqlLogByTblId) {
        [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -5;ErrorMessage = "FAILED TO RETRIEVE DRILL DOWN IDs FROM SQL USING SELECT STATEMENT '$SqlSelectCmd'. Error Captured: $($SqlDataObj.ErrorCaptured)"} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
        $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
        ##Check results?:
        if ($SqlLogByTblIdObj.Value -eq 0) {#successful
            Write-CmTraceLog -LogMessage "Successfully logged the skipping of the DrillDown Url to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        }
        else {# failure
            Write-CmTraceLog -LogMessage "Failed to log the skipping of the DrillDown Url to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        }
        Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
    } # end logging the skip to Sql

    Remove-Variable -Name UriVersion,SqlTableName,SqlLogByTblId,SqlDefinition,SqlDataObj,SqlSelectCmd -ErrorAction SilentlyContinue;
    
    $StopScript = $true;
}
#endregion

$Dta = New-Object -TypeName System.Collections.ArrayList;

[int64]$CurRecordCount = 0;
[bool]$RetriesOccurred = $false;
[int64]$RecordsImported = 0;

[bool]$TruncateSqlTable = $true; #if ($NoTruncate) {$false;} else {$true;};
[string]$DrillDownGrpErrorMessage = "";

[string]$XmlInfo = "";

foreach ($DrillUrl in $CurReplacementObj)
{
    if ($StopScript) {break;}

    $CurUriPart = $Url.Replace('{azureADDeviceId}',$DrillUrl.Values);

    ## Create the Uri to call:
    $OdataURL = "$BaseURL$($UriVersion)/$CurUriPart";

    ## Update Xml stuff for later insertion
    $tmpUriInfo = $([ordered]@{SpecificURL = [ordered]@{UriPart = $CurUriPart;UriVersion = $UriVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});

    ## Get the data for the Uri:
    $DtaObjFrmDS = Get-IntuneOpStoreData -OdataUrl $OdataURL -GetAuthStringCmd $GetAuthStringCmd -VerboseRecordCount $WriteBatchSize -Verbose:$isVerbose;

    $CurRecordCount += $DtaObjFrmDS.RecordCount;
    [string]$CurErrorMessage = $DtaObjFrmDS.ErrorMessage;
    if ($DtaObjFrmDS.RetriesOccurred -eq $true) {
        $RetriesOccurred = $true;
    }

    foreach ($itm in $DtaObjFrmDS.DataObject)
    {
        [void]$Dta.Add($itm);
    }
    Remove-Variable -Name itm -ErrorAction SilentlyContinue;

    # Update Xml Stuff again:
    $tmpUriInfo.Add('EndDateTimeUTC',$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff")));
    $tmpUriInfo.Add('RecordsImported',$DtaObjFrmDS.RecordCount);
    $tmpUriInfo.Add('RetriesOccurred',$RetriesOccurred);
    $tmpUriInfo.Add('ErrorDetails',$CurErrorMessage);
    $XmlInfo += Get-HashToXml -HashOrDictionary $tmpUriInfo;
    Remove-Variable -Name tmpUriInfo -ErrorAction SilentlyContinue;

    ## what else do we need/want to do with the return object before disposing?
    Remove-Variable -Name DtaObjFrmDS -ErrorAction SilentlyContinue;

    #region : Write Interim Data if Necessary
    if ($CurRecordCount -ge $WriteBatchSize)
    {
        #region : Convert the data we got from the service to a DataTable so that we can import it into SQL:
        Write-CmTraceLog -LogMessage "Converting the data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        $DtaTbl = ConvertTo-DataTable -InputObject $Dta -ColumnDef $SqlDefinition;
        Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        #endregion

        #region : Truncate Table
        # Only try to Truncate the table if it is the first or only batch of data:
        if ($TruncateSqlTable) {
            Write-CmTraceLog -LogMessage "Truncating the table '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $SqlTableName;
            ## Check to make sure we were able to truncate the table:
            if ($SqlTruncTblObj.Value -eq 0) {
                Write-CmTraceLog -LogMessage "Table Truncated." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                if ($SqlTruncTblObj.RetryOccurred) {
                    Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                $TruncateSqlTable = $false;
            }
            else {
                Write-CmTraceLog -LogMessage "There was an error trying to truncate the table. We'll need to skip this URL/Table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                if ($SqlTruncTblObj.RetryOccurred) {
                    Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                ## Create the CurErrorMessage for logging purposes:
                if ($CurErrorMessage) {
                    if ($SqlTruncTblObj.RetryOccurred) {
                        $CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n$CurErrorMessage";
                    }
                    else {
                        $CurErrorMessage = "There was an error trying to truncate the table. We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n$CurErrorMessage";
                    }
                }
                else {
                    if ($SqlTruncTblObj.RetryOccurred) {
                        [string]$CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                    }
                    else {
                        [string]$CurErrorMessage = "There was an error trying to truncate the table. We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                    }
                }
                $DrillDownGrpErrorMessage += $CurErrorMessage;

                $endUriInfo = $([ordered]@{SpecificURL = [ordered]@{UriPart = "Rollup/End Status Record"}});
                $endUriInfo.Add('TruncateErrorOccurred',$true);
                $endUriInfo.Add('ErrorDetails',$SqlTruncTblObj.ErrorCaptured);
                if ($SqlTruncTblObj.RetryOccurred) {$endUriInfo.Add('RetriesOccurred',$true);}
                $endUriInfo.Add('RecordsNotImported',$DtaTbl.Rows.Count);
                $XmlInfo += Get-HashToXml -HashOrDictionary $endUriInfo;

                Remove-Variable -Name DtaTbl,SqlTruncTblObj,endUriInfo -ErrorAction SilentlyContinue;
                $StopScript = $true;
                break; # break out of the foreach loop
            }
            Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
        }
        else {
            Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        }
        #endregion DrillDown: Table Truncate Logic

        #region : Write DataTable to SQL
        ## Create the 'splat' object from combining the base SqlConnSplat and ImportSplatParams objects and adding our custom items needed to import:
        $ImportSplat = $SqlConnSplat + $ImportSplatParams + @{SchemaName = $SqlSchemaName; TableName = $SqlTableName};
        if ($DtaTbl.Rows.Count -ge 200000 -and $null -eq $BulkCopyBatchSize) {
            $ImportSplat.Add("BulkCopyBatchSize", 200000);
        }
        elseif ($null -ne $BulkCopyBatchSize) {
            $ImportSplat.Add("BulkCopyBatchSize", $BulkCopyBatchSize);
        }
        
        Write-CmTraceLog -LogMessage "Starting an import of the DataTable for '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        
        $SqlImportRetObj = Import-SqlTableData @ImportSplat -ImportData $DtaTbl -LogFullPath $LogFullPath -Verbose:$isVerbose;
        Remove-Variable -Name ImportSplat -ErrorAction SilentlyContinue;
        
        ## Check if we were successful:
        if ($SqlImportRetObj.Value -eq 0) {
            ## Make sure we have the RecordsImported for proper logging
            $RecordsImported += $DtaTbl.Rows.Count;
            $CurRecordCount = 0; #set this back down to 0
            Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $RecordsImported" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            if ($SqlImportRetObj.RetryOccurred) {
                Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                $ImportRetriesOccurred = $true;
            }
            ## Cleanup for the next item in the while loop:
            Remove-Variable -Name DtaTbl,SqlImportRetObj -ErrorAction SilentlyContinue;
        }
        else { #failure to import data:
            Write-CmTraceLog -LogMessage "Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            if ($SqlImportRetObj.RetryOccurred) {
                $ImportRetriesOccurred = $true;
                [string]$ErrorMsgRetryPortion = "However, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). ";
            }
            else {
                [string]$ErrorMsgRetryPortion = "";
            }
            
            # Make sure to subtract the records that didn't get imported from the total records so we log the count accurately:
            $RecordsNotImported = $($DtaTbl.Rows.Count);
            $RecordsImported = if ($RecordsImported -gt 0) {$RecordsImported - $RecordsNotImported;} else {0;}
            $ImportError = $true;
        
            ## Create the CurErrorMessage for logging purposes:
            if ($CurErrorMessage) {
                $CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n$CurErrorMessage";
            }
            else {
                [string]$CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)";
            }
            $DrillDownGrpErrorMessage += $CurErrorMessage;
            
            $endUriInfo = $([ordered]@{SpecificURL = [ordered]@{UriPart = "Rollup/End Status Record"}});
            $endUriInfo.Add('RecordsNotImported',$RecordsNotImported);
            if ($ImportRetriesOccurred) {$endUriInfo.Add('RetriesOccurred',$true);}
            $endUriInfo.Add('ImportErrorOccurred',$true);
            $endUriInfo.Add('ErrorDetails',$SqlImportRetObj.ErrorCaptured);
            $XmlInfo += Get-HashToXml -HashOrDictionary $endUriInfo;
            
            Remove-Variable -Name DtaTbl,SqlImportRetObj,ErrorMsgRetryPortion,endUriInfo -ErrorAction SilentlyContinue;
            $StopScript = $true;
            break; # break out of the while loop
        }
        #endregion

        #region : Log interim information
        if ($SqlLogByTblId)
        {
            $PropValues =
              @{
                ErrorNumber = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {-1;} else {$null;}
                ErrorMessage = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {$DrillDownGrpErrorMessage;} else {$null;}
                ExtendedInfo = if (-not [String]::IsNullOrWhiteSpace($XmlInfo)) {"<SpecificURLs>$XmlInfo</SpecificURLs>"} else {$null;}
              }
            [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues $PropValues -IsFirstXml -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
            $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
            ##Check results:
            if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                Write-CmTraceLog -LogMessage "Successfully logged the interim refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            else {# failure to log
                Write-CmTraceLog -LogMessage "There was an error trying to log the interim refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            }
            Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd,PropValues -ErrorAction SilentlyContinue;
        }
        #endregion

        # dispose of DataTable and $Dta arraylist
        Remove-Variable -Name DtaTbl -ErrorAction SilentlyContinue;
        $Dta.Clear();
    }
    #endregion
}
Remove-Variable -Name DrillUrl -ErrorAction SilentlyContinue;

<#
## Handle a break error inside the loop above and falling here...
if ($StopScript)
{
    # do what??
}
#>

## if there's data still to take care of let's do that now:
while ($StopScript -eq $false -and $Dta.Count -gt 0) # use a while to allow breaking out of portions:
{
    #region : Convert the data we got from the service to a DataTable so that we can import it into SQL:
    Write-CmTraceLog -LogMessage "Converting the data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    $DtaTbl = ConvertTo-DataTable -InputObject $Dta -ColumnDef $SqlDefinition;
    Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    #endregion
    
    #region : Truncate Table
    # Only try to Truncate the table if it is the first or only batch of data:
    if ($TruncateSqlTable) {
        Write-CmTraceLog -LogMessage "Truncating the table '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $SqlTableName;
        ## Check to make sure we were able to truncate the table:
        if ($SqlTruncTblObj.Value -eq 0) {
            Write-CmTraceLog -LogMessage "Table Truncated." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            if ($SqlTruncTblObj.RetryOccurred) {
                Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            $TruncateSqlTable = $false;
        }
        else {
            Write-CmTraceLog -LogMessage "There was an error trying to truncate the table. We'll need to skip this URL/Table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            if ($SqlTruncTblObj.RetryOccurred) {
                Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            ## Create the CurErrorMessage for logging purposes:
            if ($CurErrorMessage) {
                if ($SqlTruncTblObj.RetryOccurred) {
                    $CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n$CurErrorMessage";
                }
                else {
                    $CurErrorMessage = "There was an error trying to truncate the table. We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n$CurErrorMessage";
                }
            }
            else {
                if ($SqlTruncTblObj.RetryOccurred) {
                    [string]$CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                }
                else {
                    [string]$CurErrorMessage = "There was an error trying to truncate the table. We'll need to skip this URL/Table...`r`nError Returned from the truncate call:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                }
            }
            $DrillDownGrpErrorMessage += $CurErrorMessage;

            $endUriInfo = $([ordered]@{SpecificURL = [ordered]@{UriPart = "Rollup/End Status Record"}});
            $endUriInfo.Add('TruncateErrorOccurred',$true);
            $endUriInfo.Add('ErrorDetails',$SqlTruncTblObj.ErrorCaptured);
            if ($SqlTruncTblObj.RetryOccurred) {$endUriInfo.Add('RetriesOccurred',$true);}
            $endUriInfo.Add('RecordsNotImported',$DtaTbl.Rows.Count);
            $XmlInfo += Get-HashToXml -HashOrDictionary $endUriInfo;

            Remove-Variable -Name DtaTbl,SqlTruncTblObj,endUriInfo -ErrorAction SilentlyContinue;
            $StopScript = $true;
            break; # break out of the foreach loop
        }
        Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
    }
    else {
        Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    }
    #endregion DrillDown: Table Truncate Logic
    
    #region : Write DataTable to SQL
    ## Create the 'splat' object from combining the base SqlConnSplat and ImportSplatParams objects and adding our custom items needed to import:
    $ImportSplat = $SqlConnSplat + $ImportSplatParams + @{SchemaName = $SqlSchemaName; TableName = $SqlTableName};
    if ($DtaTbl.Rows.Count -ge 200000 -and $null -eq $BulkCopyBatchSize) {
        $ImportSplat.Add("BulkCopyBatchSize", 200000);
    }
    elseif ($null -ne $BulkCopyBatchSize) {
        $ImportSplat.Add("BulkCopyBatchSize", $BulkCopyBatchSize);
    }
    
    Write-CmTraceLog -LogMessage "Starting an import of the DataTable for '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
    $SqlImportRetObj = Import-SqlTableData @ImportSplat -ImportData $DtaTbl -LogFullPath $LogFullPath -Verbose:$isVerbose;
    Remove-Variable -Name ImportSplat -ErrorAction SilentlyContinue;
    
    ## Check if we were successful:
    if ($SqlImportRetObj.Value -eq 0) {
        ## Make sure we have the RecordsImported for proper logging
        $RecordsImported += $DtaTbl.Rows.Count;
        Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $RecordsImported" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        if ($SqlImportRetObj.RetryOccurred) {
            Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            $ImportRetriesOccurred = $true;
        }
        ## Cleanup:
        Remove-Variable -Name DtaTbl,SqlImportRetObj -ErrorAction SilentlyContinue;
    }
    else { #failure to import data:
        Write-CmTraceLog -LogMessage "Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        if ($SqlImportRetObj.RetryOccurred) {
            $ImportRetriesOccurred = $true;
            [string]$ErrorMsgRetryPortion = "However, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). ";
        }
        else {
            [string]$ErrorMsgRetryPortion = "";
        }
        
        # Make sure to subtract the records that didn't get imported from the total records so we log the count accurately:
        $RecordsNotImported = $($DtaTbl.Rows.Count);
        $RecordsImported = if ($RecordsImported -gt 0) {$RecordsImported - $RecordsNotImported;} else {0;}
        $ImportError = $true;
    
        ## Create the CurErrorMessage for logging purposes:
        if ($CurErrorMessage) {
            $CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n$CurErrorMessage";
        }
        else {
            [string]$CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)";
        }
        $DrillDownGrpErrorMessage += $CurErrorMessage;

        $endUriInfo = $([ordered]@{SpecificURL = [ordered]@{UriPart = "Rollup/End Status Record"}});
        $endUriInfo.Add('RecordsNotImported',$RecordsNotImported);
        if ($ImportRetriesOccurred) {$endUriInfo.Add('RetriesOccurred',$true);}
        $endUriInfo.Add('ImportErrorOccurred',$true);
        $endUriInfo.Add('ErrorDetails',$SqlImportRetObj.ErrorCaptured);
        $XmlInfo += Get-HashToXml -HashOrDictionary $endUriInfo;

        Remove-Variable -Name DtaTbl,SqlImportRetObj,ErrorMsgRetryPortion -ErrorAction SilentlyContinue;
        $StopScript = $true;
        break; # break out of the while loop
    }
    #endregion

    #region : Log Last data import...
    if ($SqlLogByTblId)
    {
        $PropValues =
          @{
            ErrorNumber = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {-1;} else {$null;}
            ErrorMessage = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {$DrillDownGrpErrorMessage;} else {$null;}
            ExtendedInfo = if (-not [String]::IsNullOrWhiteSpace($XmlInfo)) {"<SpecificURLs>$XmlInfo</SpecificURLs>"} else {$null;}
          }
        [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues $PropValues -IsFirstXml -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
        $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
        ##Check results:
        if ($SqlLogByTblIdObj.Value -eq 0) {#successful
            Write-CmTraceLog -LogMessage "Successfully logged the interim refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        }
        else {# failure to log
            Write-CmTraceLog -LogMessage "There was an error trying to log the interim refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        }
        Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd,PropValues -ErrorAction SilentlyContinue;
    }
    #endregion

    ## Cleanup - if we got here we don't want to go through the loop eternally so fix that:
    $StopScript = $true;
    Remove-Variable -Name Dta -ErrorAction SilentlyContinue;
}


#region : Log completion of Target Table
## Log the completion of the Url TargetTable:
if ($SqlLogByTblId) {
    ## Create and Run the update statement:
    $PropValues =
      @{
        EndDateUTC = "SYSUTCDATETIME()"
        ErrorNumber = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {-1;} else {$null;}
        ErrorMessage = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {$DrillDownGrpErrorMessage;} else {$null;}
        ExtendedInfo = if (-not [String]::IsNullOrWhiteSpace($XmlInfo)) {"<SpecificURLs>$XmlInfo</SpecificURLs>"} else {$null;}
      }
    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
    ##Check results:
    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
        Write-CmTraceLog -LogMessage "Successfully logged the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    }
    else {# failure to log
        Write-CmTraceLog -LogMessage "There was an error trying to log the completion of the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    }
    Remove-Variable -Name SqlLogByTblId,SqlLogByTblIdObj,SqlLogCmd,PropValues -ErrorAction SilentlyContinue;
} # End: logging the refresh of the DrillDown URL Group/TargetTable
#endregion


#region : Log Completion of Script
## Log to SQL Table - completion of the script:
if ($SqlLogTblId) { # Currently this isn't logging any errors...
    ## Create and Run the update statement:
    $PropValues =
      @{
        EndDateUTC = 'SYSUTCDATETIME()'
        ErrorNumber = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {-1;} else {$null;}
        ErrorMessage = if (-not [String]::IsNullOrWhiteSpace($DrillDownGrpErrorMessage)) {$DrillDownGrpErrorMessage;} else {$null;}
       }
    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogTblId -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingTableName";
    $SqlLogTblObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
    ## Check results:
    if ($SqlLogTblObj.Value -eq 0) {#successful
        Write-CmTraceLog -LogMessage "Successfully logged the completion of the refresh to SQL table; Log ID = $SqlLogTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    }
    else {# failure to log
        Write-CmTraceLog -LogMessage "There was an error trying to log the completion to the SQL table! ; Log ID = $SqlLogTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    }
}
Remove-Variable -Name SqlLogTblObj,SqlLogCmd,SqlLogTblId,PropValues -ErrorAction SilentlyContinue;
#endregion


## Final Cleanup:
#Remove-Variable -Name SqlServerName,GraphUser,SqlDatabaseName,SqlSchemaName,WriteBatchSize,SqlConnTimeout,SqlLoggingTableName,SqlLoggingByTableName,SqlLoggingTableJobName,ApplicationId,RedirectUri,GraphUserIsMSI,BulkCopyTimeout,BulkCopyBatchSize,BulkCopyTimeoutRetries,AuthUrl,BaseURL,LogFullPath -ErrorAction SilentlyContinue;
#Remove-Variable -Name scriptName,isVerbose,StopScript,SqlConnStringBuilder,SqlConnSplat,ImportSplatParams,GetAuthStringCmd,SqlLogCmd,SqlLogTblIdObj,Url,UriVersion,SqlTableName,SqlLogByTblIdObj,EntityColDef,SqlDefinition,SqlSelectCmd,SqlDataObj,CurReplacementObj,Dta,CurRecordCount,RetriesOccurred,RecordsImported,TruncateSqlTable,DrillDownGrpErrorMessage,XmlInfo,DrillUrl,CurUriPart,OdataURL,tmpUriInfo,DtaObjFrmDS,CurErrorMessage,RetriesOccurred,itm,DtaTbl,SqlTruncTblObj,endUriInfo,ImportSplat,SqlImportRetObj,ImportRetriesOccurred,ErrorMsgRetryPortion,RecordsNotImported,ImportError,PropValues -ErrorAction SilentlyContinue;
#Clear-Authentication;

Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "******************************************   Script Finished   ****************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
