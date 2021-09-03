<#
.SYNOPSIS
    This script is used to sync MS Graph URI's to a SQL database.
.DESCRIPTION
    This script pulls data from MS Graph and stores the data into a SQL db.
.PARAMETER SqlServerName
    The name of the SQL Server to which the Intune data will be saved.
.PARAMETER UrlsToSync
    This contains the list of URIs that need to be sync'd to SQL. The data can be stored in a txt file, sent directly in, or be stored in a SQL table. For Example:
     - A Path: the value here would be the full path name to the text file containing at least two lines, each line a hashtable containing the necessary information. Note: The lines to sync need to be in hashtable format.
       - Example: "D:\Test\TestSync.txt"
     - Direct HashTable: the value here would be the hashtable format of the URI to sync (it can be multiline for multiple URIs).
       - Example: '@{"UriPart" = "deviceManagement/WindowsAutopilotDeviceIdentities"; "Version" = "beta"}'
     - From SQL: In this case there are multiple options to define what is sync'd; the value must start with one of the following values (description/example follows each):
       - "SqlFilter:"
          -Description: This is the portion that will be added to the WHERE clause of the SQL query. The default table name in this scenario is "dbo.MsGraphSyncToSqlMetaData", to get data from other tables or with different logic use one of the other keywords.
          -Example: "SqlFilter:JobName = N'IntuneSyncToSql_SomeJob' AND Enabled = 1"
       - "SqlQuery:"
          -Description: This is the entire query that should be run to get the data - it can be as simple or complex as desired.
          -Example: "SqlQuery:SELECT * FROM SomeDB.dbo.SomeNewMetaDataTable WHERE SomeCriteria = SomeValue;"
       - "SqlView:"
          -Description: This is the name of a view that contains the data; a "SELECT *" will be performed on the view name. Anything after the view name will be included as well.
          -Example: "SqlView:v_MetaDataTableViewName" OR "SqlView:dbo.v_MetaDataTableViewName WHERE Enabled = 1 AND SomethingElse = SomeValue ORDER BY Blah;"
       - "SqlProcedure:"
          -Description: This is the name of the stored procedure that returns the data. The "Execute" is optional.
          -Example: "SqlProcedure:usp_SomeSprocName" OR "SqlProcedure:EXECUTE dbo.usp_SomeSprocName;"
.PARAMETER GraphUser
    The user or MSI used to authenticate with Graph (what to use to get the access token).
.PARAMETER SqlUser
    The user to use to connect to the SQL Server. Simply using "me" is acceptable since it will just use the calling user's name/credentials via Windows Authentication.
    If Sql Authentication is desired then the user must be correct AND the KeyVault parameters must be used since that is the only place from which the password will be retrieved.
.PARAMETER GraphKeyVaultName
    if using App/User to authenticate for Graph calls, this can be used to retrieve the password for the user from KeyVault.
.PARAMETER GraphKeyVaultSecretName
    if using App/User to authenticate for Graph calls, this can be used to retrieve the password for the user from KeyVault.
.PARAMETER SqlKeyVaultName
    If using SQL Authentication to connect to SQL (the the password must be in KeyVault) then this is the name of the vault containing the secret.
.PARAMETER SqlKeyVaultSecretName
    If using SQL Authentication to connect to SQL (the the password must be in KeyVault) then this is the name of the secret in the vault.
.PARAMETER certThumbprint
    If a certificate is being used to connect to Azure (for the authentication to connect to KeyVault), this is the "CertificateThumbprint" value in that "Connect-AzAccount" call.
.PARAMETER KeyVaultApplicationId
    If a certificate is being used to connect to Azure (for the authentication to connect to KeyVault), this is the "ApplicationId" value in that "Connect-AzAccount" call.
.PARAMETER tenantId
    This is the tenant to use for the connection to Azure (for KeyVault). This is only required if using secrets from KeyVault.
.PARAMETER SubscriptionId
    This is the subscription to use for the connection to Azure (for KeyVault). This is only required if using secrets from KeyVault.
.PARAMETER SqlDatabaseName
    The name of the database where the data is to be stored. The default is "Intune".
.PARAMETER SqlSchemaName
    The schema in the database in which the tables to use for storing data reside. The default is "dbo".
.PARAMETER WriteBatchSize
    The script is capable of writing the data in batches, use this to better control the size of the batches to use (per URI). A batch is the number of records that will be collected before writing the data
    to SQL and starting to collect the data again. This is only applicable when paging through Graph for the data. The default batch size is 100,000,000 (essentially, no batching at all).
.PARAMETER VerboseRecordCount
    This is for use when using the script with ISE or some other host - it is meant to control the amount of messages written to the host but isn't fool proof.
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection. The default is 240.
.PARAMETER ProcessUrisWithoutPartType
    This flag can be used to skip the 'normal' URIs (or those without a 'UriPartType' defined) in the script. The default is "True" so the script will try and process these URIs.
.PARAMETER ProcessSpecificURLs
    This flag can be used to skip the URIs with a 'UriPartType' of "SpecificURL" defined in the script. The default is "True" so the script will try and process these URIs.
.PARAMETER ProcessDrillDownURLs
    This flag can be used to skip the URIs with a 'UriPartType' of "DrillDownData" defined in the script. The default is "True" so the script will try and process these URIs.
.PARAMETER ProcessReportExports
    This flag can be used to skip the URIs with a 'UriPartType' of "ReportExport" defined in the script. The default is "True" so the script will try and process these URIs.
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
.PARAMETER NoTruncate
    This flag can be used when the script needs to run and insert data to a table without truncating it.
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -UrlsToSync 'C:\SomePath\TablesToSync.txt' -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI;
    This will sync the tables listed in the TablesToSync.txt file to tables in the 'dbo' schema in the 'Intune' database using the MSI eeeee* to authenticate to Graph.
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -UrlsToSync '@{"UriPart" = "deviceManagement/deviceManagementScripts"; "Version" = "beta"}' -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI;
    This will sync the deviceManagementScripts URI to the table 'dbo.deviceManagementScripts' in the 'Intune' database using the MSI eeeee* to authenticate to Graph.
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -UrlsToSync "SqlFilter:TableName = N'managedDevices'" -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI;
    This will sync the managedDevices URI to the table 'dbo.managedDevices' in the 'Intune' database using the MSI eeeee* to authenticate to Graph.
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -UrlsToSync "SqlFilter:JobName = N'MyJobName' AND Enabled = 1" -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI;
    This will sync the tables found in the 'dbo.MsGraphSyncToSqlMetaData' table that are "Enabled" and have a "JobName" of "MyJobName" to tables in the 'dbo' schema in the 'Intune' database using the MSI eeeee* to authenticate to Graph.
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -SqlDatabaseName IntuneV2 -UrlsToSync '@{"UriPart" = "deviceManagement/deviceManagementScripts"; "Version" = "beta"}' -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI -LogFullPath 'D:\SomeFolder\LogFileName.log' -Verbose;
    This will sync the deviceManagementScripts URI to the table 'dbo.deviceManagementScripts' in the 'IntuneV2' database using the MSI eeeee* to authenticate to Graph. And information will be written to the 'D:\SomeFolder\LogFileName.log' file as well as written to the host (if running interactively).
.EXAMPLE
    .\IntuneSyncToSql.ps1 -SqlServerName MySqlServer -UrlsToSync '@{"UriPart" = "deviceManagement/deviceManagementScripts"; "Version" = "crazyVersion"}' -GraphUser 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' -SqlUser 'me' -GraphUserIsMSI -AuthUrl 'https://login.windows.net/common' -BaseURL 'https://canary.graph.microsoft.com';
    This will sync the deviceManagementScripts URI to the table 'dbo.deviceManagementScripts' in the 'Intune' database using the MSI eeeee* to authenticate to Graph using the Authority "https://login.windows.net/common".
    The URI call will be to "https://canary.graph.microsoft.com/crazyVersion/deviceManagement/deviceManagementScripts" rather than "https://graph.microsoft.com/crazyVersion/deviceManagement/deviceManagementScripts".
.NOTES
    NAME: IntuneSyncToSql.ps1
    HISTORY:
        Date          Author                    Notes
        ??/??/2017    Benjamin Reynolds         Initial Creation. This was created and iterated many many times before these comments were added in 2020*.
        09/12/2019    Benjamin Reynolds         Added logic for 'MetaDataEntityToUse' to explicitly define what to use rather than dynamically determining this
        03/16/2020*   Benjamin Reynolds         Added this comment block for the script. Added MSI authentication.
        03/30/2020    Benjamin Reynolds         Added BulkCopy parameters to be able to pass to "Import-SqlTableData" in the module. Added splatting of parameters
                                                to use for the function to help simplify what to pass to the function.
        06/26/2020    Benjamin Reynolds         Added the "SqlLoggingTableJobName" parameter and functionality for better logging/monitoring control of jobs.
        09/02/2020    Benjamin Reynolds         Added Authentication items - AuthUrl and "SchemaVersion" parameters and functionality. Added logic to skip expanded
                                                column properties when no data exists for the property but is supposed to write to a separate table.
        09/11/2020    Benjamin Reynolds         Added ability to skip the metadata check and to just use the SQL definition using "SkipGraphMetaDataCheck".
        01/28/2021    Benjamin Reynolds         Added logic to account for the Invoke-SqlTruncate Retry information now being returned.
        02/16/2021    Benjamin Reynolds         Added ability to use a '$select' in the URI call (for the no UriPartType items).
        03/03/2021    Benjamin Reynolds         Added ReportExport logic (incl variable 'ProcessReportExports').
        03/19/2021    Benjamin Reynolds         Added some retry logic for report export stuff; Added NoTruncate parameter...so that data can be added to a table.
        03/22/2021    Benjamin Reynolds         Updated the "TablesToSync" logic to accept either a path or hash string in one parameter instead of separate ones.
        03/23/2021    Benjamin Reynolds         Removed credential file options for security purposes. Updated remaining ParameterSetName's.
        03/24/2021    Benjamin Reynolds         Updated for updates to Get-IntuneOpStoreData and Get-ColumnDefinitionsAndCompare
        03/25/2021    Benjamin Reynolds         Updated for updates to Import-SqlTableData, Invoke-SqlTruncate, Get-SqlTableColumnDefinition (using splatting for this too);
                                                Added "Set-LogToSqlCommand" logic (to begin process of simplifying logging functions and logic in the script).
        04/13/2021    Benjamin Reynolds         Added "Get-HashToXml" logic; Removed references to "UseSkipCountToken"/"PageSize" workaround;
                                                Added ability to write to a log file (using "Write-CmTraceLog") which also has logic for writing to the host so
                                                all Write-Host items could be removed; Added "Get-UrlsToSyncFromSql" logic - Updated the "TablesToSync" logic to accept
                                                a way to get the values from SQL. TablesToSync can get the tables from SQL if the value starts with one of the following:
                                                 -"SqlFilter:" ex: "SqlFilter:JobName = N'IntuneSyncToSql_Various' AND Enabled = 1"
                                                 -"SqlProcedure:" ex: "SqlProcedure:usp_SomeSprocName"
                                                 -"SqlQuery:" ex: "SqlQuery:SELECT * FROM dbo.GraphToSqlMetaData WHERE Id = N'mobapp' OR ParentId = N'mobapp';"
                                                 -"SqlView:" ex: "dbo.v_SomeViewName"
                                                 Note: "dbo.MsGraphSyncToSqlMetaData" is the default MetaData table where the information resides; this will be used
                                                 when "SqlFilter" is passed in.
        06/11/2021    Benjamin Reynolds         Updated DrillDown logic to allow replacements outside of slashes. Ex: "entity?$filter=id eq '{id}'" works now as well
                                                as the traditional structure "entity/{id}"

    NOTES:

    TODO:
      [ ] Fix/Test/Validate the Azure/KeyVault connection since this is new/untested logic
      [ ] ? Integrate getting the authentication using MSAL.PS when not an MSI ?
      [ ] ? start using an object rather than a string for Get-Authentication ?
      [ ] Remove the following parameters (and in module where needed)??
          [ ] VerboseRecordCount
          [ ] ProcessUrisWithoutPartType
          [ ] ProcessSpecificURLs
          [ ] ProcessDrillDownURLs
          [ ] ProcessReportExports
      [ ] ? Remove the Graph Entity Checks and Comparisons?
      [ ] ? Remove or simplify the expand params stuff to separate tables (in the 'normal' uris) ?
      [ ] ? Remove all Graph Checking?

#>
[cmdletbinding(PositionalBinding=$false)]
param (
     [Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [Alias("SqlServer")]
     [string]$SqlServerName
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [Alias("FilePath","HashString","UrlsToSyncFromSql")]
     [string]$UrlsToSync
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$GraphUser
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$SqlUser
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$GraphKeyVaultName
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$GraphKeyVaultSecretName
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$SqlKeyVaultName
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$SqlKeyVaultSecretName
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$certThumbprint
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$KeyVaultApplicationId
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$tenantId
    ,[Parameter(Mandatory=$true,ParameterSetName='GraphUserSqlKeyVault')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlUser')]
     [Parameter(Mandatory=$true,ParameterSetName='GraphKeyVaultSqlKeyVault')]
     [string]$SubscriptionId
    ,[Parameter(Mandatory=$false)][Alias("DatabaseName","Database")][string]$SqlDatabaseName = 'Intune'
    ,[Parameter(Mandatory=$false)][Alias("SchemaName","Schema")][string]$SqlSchemaName = 'dbo'
    ,[Parameter(Mandatory=$false)][int64]$WriteBatchSize = 100000000
    ,[Parameter(Mandatory=$false)][int64]$VerboseRecordCount = 50000
    ,[Parameter(Mandatory=$false)][Alias("ConnectionTimeout","ConnTimeout")][int]$SqlConnTimeout = 240
    ,[Parameter(Mandatory=$false)][boolean]$ProcessUrisWithoutPartType = $true
    ,[Parameter(Mandatory=$false)][boolean]$ProcessSpecificURLs = $true
    ,[Parameter(Mandatory=$false)][boolean]$ProcessDrillDownURLs = $true
    ,[Parameter(Mandatory=$false)][boolean]$ProcessReportExports = $true
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingTableName = 'PowerShellRefreshHistory'
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingByTableName = 'TableRefreshHistory'
    ,[Parameter(Mandatory=$false)][string]$SqlLoggingTableJobName
    ,[Parameter(Mandatory=$false)][Alias("GraphApplicationId")][string]$ApplicationId
    ,[Parameter(Mandatory=$false)][Alias("GraphApplicationIdRedirectUri")][string]$RedirectUri
    ,[Parameter(Mandatory=$false)][switch]$GraphUserIsMSI
    #,[Parameter(Mandatory=$false)][switch]$KeyVaultMSI
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyTimeout
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyBatchSize
    ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$BulkCopyTimeoutRetries
    ,[Parameter(Mandatory=$false)][Alias("Authority")][string]$AuthUrl = 'https://login.microsoftonline.com/common/'
    ,[Parameter(Mandatory=$false)][Alias("Audience")][string]$BaseURL = 'https://graph.microsoft.com/'
    ,[Parameter(Mandatory=$false)][ValidateScript({(Test-Path -Path (Split-Path $PSItem)) -and ((Split-Path -Path $PSItem -Leaf).EndsWith(".log"))})][string]$LogFullPath
    ,[Parameter(Mandatory=$false)][Alias("AddData")][switch]$NoTruncate
)

## Declare Working Variables and Validate:
[string]$scriptName = Split-Path $PSCmdlet.MyInvocation.MyCommand.Source -Leaf;
[bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

## Do we force a log to be created or just do nothing?...let's do nothing for now:
#if ([String]::IsNullOrWhiteSpace($LogFullPath))
#{
#    $LogFullPath = "$(Split-Path $PSCmdlet.MyInvocation.MyCommand.Source)\Logs\";
#    $LogFullPath += "$((Split-Path $PSCmdlet.MyInvocation.MyCommand.Source -Leaf).Replace('.ps1',''))";
#    $LogFullPath += "-$(Get-Date -Format "yyyyMMddTHHmmssfff").log";
#    if (-Not (Test-Path -Path (Split-Path $LogFullPath)))
#    {
#        $mkDir = New-Item -Path (Split-Path $LogFullPath) -ItemType Directory;
#        if ($null -eq $mkDir)
#        {
#            throw "Can't create log directory! Script not running.";
#        }
#    }
#}

if (-Not $BaseURL.EndsWith('/'))
{
    $BaseURL = "$BaseURL/";
}


## Log the start of the script
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "******************************************   Script Starting   ****************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

<####################################################################################################################
        Variable Validation and Determine Access items: Graph & SQL
####################################################################################################################>

#########################################################################################################
########################### THIS PORTION HAS NOT BEEN TESTED YET ########################################

### If KeyVault is going to be used for any secrets Connect to Azure and get the secret values:
if ($PsCmdlet.ParameterSetName.IndexOf('KeyVault') -ne -1)
{   ##### THIS PORTION HAS NOT BEEN TESTED YET #####
    # make connection to azure (Connect-AzAccount) and then use 'Get-AzKeyVaultSecret' to get the secret with which to build the credential!
    <#if ($KeyVaultMSI -eq $true)
    {
        # Use MSI to connect to Azure:
        Connect-AzAccount -Tenant $tenantId -Subscription $SubscriptionId -Identity;
    }
    else#>if ($certThumbprint)
    {
        # Use AppId and Cert to connect to Azure:
        Connect-AzAccount -Tenant $tenantId -Subscription $SubscriptionId -CertificateThumbprint $certThumbprint -ApplicationId $KeyVaultApplicationId -ServicePrincipal;
    }
    else
    {
        # Use current user's credentials to connect to Azure:
        Connect-AzAccount -Tenant $tenantId -Subscription $SubscriptionId;
    }

    # Get the secrets:
    if ($PsCmdlet.ParameterSetName.IndexOf('GraphKeyVault') -ne -1)
    {
        [Security.SecureString]$GraphPassword = Get-AzKeyVaultSecret -VaultName $GraphKeyVaultName -Name $GraphKeyVaultSecretName; # -AsPlainText?
    }
    if ($PsCmdlet.ParameterSetName.IndexOf('SqlKeyVault') -ne -1)
    {
        [Security.SecureString]$SqlPassword = Get-AzKeyVaultSecret -VaultName $SqlKeyVaultName -Name $SqlKeyVaultSecretName; # -AsPlainText?
        $SqlPassword.MakeReadOnly();
    } 
    
}

## If we have secrets (for passwords) create the credentials and remove the secrets:
if ($null -ne $GraphPassword)
{   ##### THIS PORTION HAS NOT BEEN TESTED YET #####
    if ((Test-ADAssembliesLoaded) -eq $false) {
        Add-ADAssemblies;
    }
    
    $Global:GraphCreds = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $GraphUser, $GraphPassword;
    Remove-Variable -Name GraphPassword -ErrorAction SilentlyContinue;
}
if ($null -ne $SqlPassword)
{
    $SqlCreds = New-Object -TypeName System.Data.SqlClient.SqlCredential -ArgumentList $SqlUser, $SqlPassword;
    Remove-Variable -Name SqlPassword -ErrorAction SilentlyContinue;
}
######################################## END OF UNTESTED PORTION ########################################
#########################################################################################################


## Create SQL ConnectionString (use builder to ensure everything is good to go):
$SqlConnStringBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
$SqlConnStringBuilder['Server'] = $SqlServerName;
$SqlConnStringBuilder['Database'] = $SqlDatabaseName;
$SqlConnStringBuilder['Connection Timeout'] = $SqlConnTimeout;

if ($PsCmdlet.ParameterSetName.IndexOf('SqlKeyVault') -ne -1) # SQL Auth: we'll have a $SqlCreds object
{
    $SqlConnStringBuilder.Encrypt = $true;
}
else # Windows Auth: no $SqlCreds object exists
{
    $SqlConnStringBuilder['Integrated Security'] = $true;
}
$SqlConnSplat = @{SqlConnString = $SqlConnStringBuilder.ConnectionString};
if ($null -ne $SqlCreds)
{
    $SqlConnSplat.Add("SqlCredentials",$SqlCreds);
}
$SqlConnSplat.Add("SqlConnTimeout",$SqlConnTimeout);

## Create common SQL Importing Splat object:
$ImportSplatParams = @{};
if ($null -ne $BulkCopyTimeout) {
    $ImportSplatParams.Add("BulkCopyTimeout", $BulkCopyTimeout);
}
if ($null -ne $BulkCopyTimeoutRetries) {
    $ImportSplatParams.Add("TimeoutRetryThreshold", $BulkCopyTimeoutRetries);
}

## Create the TablesToSync array
if ($UrlsToSync -like 'Sql*:*')
{
    $TablesToSync = Get-UrlsToSyncFromSql @SqlConnSplat -UrlsToSync $UrlsToSync -LogFullPath $LogFullPath -Verbose:$isVerbose;
    Write-CmTraceLog -LogMessage "Got TablesToSync from input string '$UrlsToSync'." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
}
elseif (([regex]::Matches($UrlsToSync,'^(\S{1}:{1}){1}[\\][\s\S]*(.txt)$',[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)).Success -eq $true) # ($isPath)
{
    if (Test-Path -Path $UrlsToSync)
    {
        $TablesToSync = Get-UrlsToSync -Path $UrlsToSync;
        Write-CmTraceLog -LogMessage "Got TablesToSync from file path '$UrlsToSync'." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    }
    else
    {
        Write-CmTraceLog -LogMessage "The file path '$UrlsToSync' is not a valid path! Exiting Script!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
        throw "unable to retrieve the Urls To Sync! File does not exist!";
    }
}
else
{
    $TablesToSync = Get-UrlsToSync -HashString $UrlsToSync;
    Write-CmTraceLog -LogMessage "Got TablesToSync from input string '$UrlsToSync'." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
}

## Check that we have tables to sync:
if ($null -eq $TablesToSync -or $TablesToSync.Count -lt 1)
{
    Write-CmTraceLog -LogMessage "We didn't get any Tables To Sync! We will Throw an exception to stop processing." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    throw "We didn't get any Tables To Sync! Stopping the process.";
}


## Build the Graph Authentication String to be used:
<#### Should I start using an object rather than a string to do all this? (Look at the "NEW DEV" file for this) ####>
if ($GraphUserIsMSI -eq $true) {
    $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -IsMSI -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
}
elseif ($Global:GraphCreds) {
    if ($ApplicationId -and $RedirectUri) {
        $GetAuthStringCmd = "Get-Authentication -UserPasswordCredentials `$GraphCreds -ApplicationId '$ApplicationId' -RedirectUri '$RedirectUri' -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
    else {
        $GetAuthStringCmd = "Get-Authentication -UserPasswordCredentials `$GraphCreds -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
}
else {
    if ($ApplicationId -and $RedirectUri) {
        $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -ApplicationId '$ApplicationId' -RedirectUri '$RedirectUri' -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
    else {
        $GetAuthStringCmd = "Get-Authentication -User '$GraphUser' -AuthUrl '$AuthUrl' -resourceAppIdURI '$BaseURL'";
    }
}


<####################################################################################################################
        Begin main portion of the script now that we have the access items...
####################################################################################################################>

## Log to SQL Table - Start of Script:
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


## Connect to Graph:
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
    elseif ($PsCmdlet.ParameterSetName.IndexOf('GraphKeyVault') -ne -1) {
        Write-CmTraceLog -LogMessage "Connecting to Graph using Credentials from KeyVault..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
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


## Create a hashtable of the unique versions - key = version; value = hashtable of cleanversion and variable names <old: [version 'clean' = value]>:
$Versions = New-Object -TypeName System.Collections.Hashtable;
foreach ($i in ($TablesToSync.Version | Sort-Object -Unique)) {
    $iVer = $i.Replace('.','dot');
    [void]$Versions.Add($i,[ordered]@{"VersionClean" = $iVer;"MetaData" = "MetaData_$($iVer)";"Enums" = "Enums_$($iVer)";"Entities" = "Entities_$($iVer)"});
    Remove-Variable -Name iVer -ErrorAction SilentlyContinue;
}
Remove-Variable -Name i -ErrorAction SilentlyContinue;

## Create an ArrayList (of hashtables) for the "SpecificURL" items:
$SpecificURLs = New-Object -TypeName System.Collections.ArrayList;
foreach ($i in $TablesToSync <#| Where-Object {$_.UriPartType -eq 'SpecificURL'}#>) {
    if ($i.UriPartType -eq 'SpecificURL') {
        [void]$SpecificURLs.Add($i);
    }
}
Remove-Variable -Name i -ErrorAction SilentlyContinue;

## Create a Grouped object by TargetTable for the SpecificURLs:
$SpecificURLsGrouped = $SpecificURLs | Group-Object {$_.TargetTable};

## Get MetaData items
Write-CmTraceLog -LogMessage "Getting MetaData items..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
foreach ($Version in $Versions.GetEnumerator()) {
    Write-CmTraceLog -LogMessage "Creating Global variables for the version: '$($Version.Key)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    Get-GraphMetaData -Version $Version.Key -BaseUrl $BaseURL;
}
Remove-Variable -Name Version -ErrorAction SilentlyContinue;


####### Process the 'Normal' URL items (those without a UriPartType...) #########
if ($ProcessUrisWithoutPartType) {
    Write-CmTraceLog -LogMessage "Processing Urls in the 'TablesToSync' Object without a UriPartType" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
    foreach ($Table in $TablesToSync) {
        if ([String]::IsNullOrWhiteSpace($Table.UriPartType))
        {
            $UriPart = $Table.UriPart;
            $ExpandCols = $Table.ExpandColumns;
            $SelectCols = $Table.SelectColumns;
            $ExpandTableOrColumn = $Table.ExpandTableOrColumn;
            $UriVersion = $Table.Version;
            $UriParts = $UriPart -split "/";
            # Reverse the order of the array for now:
            [array]::Reverse($UriParts);
    
            Write-CmTraceLog -LogMessage "Working with UriPart '$UriPart'; getting the information for this URI..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            
            ## Determine the SQL Table name to use to store the data:
            if (-Not [String]::IsNullOrWhiteSpace($Table.TargetTable)) {
                $SqlTableName = $Table.TargetTable;
            }
            else {
                $SqlTableName = $UriParts[0];
            }
    
            ## Log to SQL Table - start of table
            # Build and Run the insert command:
            [string]$SqlLogCmd = Set-LogToSqlCommand -TableToLog $SqlTableName -BatchId $SqlLogTblId -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
            $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
            # Check results:
            if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                $SqlLogByTblId = $SqlLogByTblIdObj.SqlColVal
                Write-CmTraceLog -LogMessage "Successfully logged the start of the refresh of table '$SqlTableName' to SQL table; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            else {#failure
                Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
            }
            Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
    
    
            ## Determine the EntityName to use from Graph:
            if (-Not [String]::IsNullOrWhiteSpace($Table.MetaDataEntityToUse)) {
                $GraphMetaDataEntityName = $Table.MetaDataEntityToUse;
            }
            elseif (-Not $Table.SkipGraphMetaDataCheck -eq "TRUE") {
                foreach ($NavPrp in (Get-CollectionEntity -UrlPartsReversed $UriParts -Version $UriVersion).NavigationProperty) {
                    if ($NavPrp.Name -eq $UriParts[0]) {
                        $GraphMetaDataEntityName = $NavPrp.Type.Replace("Collection(","").Replace(")","");
                        continue; # stop the foreach as soon as we find it...
                    }
                }
                Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;
            }
    
            # ? - Do a check on ExpandCols to make sure they all exist? If not there will be an error in the Get call...which would be handled anyway but...
    
            # ? - Put the array back to original order?
            #[array]::Reverse($UriParts)
    
    
            ## Get Sql Table Definition:  ## Should we explicitly cast this as "[System.Collections.ArrayList]"??
            $SqlDefinition = Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $SqlTableName;
    
            ## Make sure we have a table to work with; if not alert and go to the next entity:
            if (-not $SqlDefinition) {
                 # should we automatically create the table and try again?
                Write-CmTraceLog -LogMessage "'$SqlTableName' DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "You can run the following to create the table(s):" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

                if (-Not [String]::IsNullOrWhiteSpace($ExpandCols)) {
                    Write-CmTraceLog -LogMessage "$(Get-SqlTableCreateStatementsFromUrl -UriPart $UriPart -UriVersion $UriVersion -UriExpandCols $ExpandCols) " -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {
                    Write-CmTraceLog -LogMessage "$(Get-SqlTableCreateStatementsFromUrl -UriPart $UriPart -UriVersion $UriVersion) " -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                Write-CmTraceLog -LogMessage "Skipping '$SqlTableName'..." -LogFullPath $LogFullPath -MessageType Warning -Component $scriptName -Verbose:$isVerbose;
                
                ## Log the 'skip' to Sql:
                if ($SqlLogByTblId) {
                    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -9;ErrorMessage = 'TABLE DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!'} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "Successfully logged the skipping of the table to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# Value will equal -1 for errors...can check the "ErrorCaptured" property to know what happened
                        Write-CmTraceLog -LogMessage "Failed to log the skipping of the table to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                }
                # cleanup the variables we've created thus far:
                Remove-Variable -Name UriPart,ExpandCols,ExpandTableOrColumn,UriVersion,UriParts,SqlTableName,GraphMetaDataEntityName,SqlLogByTblId -ErrorAction SilentlyContinue;
                
                continue; # go to the next Uri in the table
            }
    
            #region GraphMetaData & SqlMetaData Comparison
            ######################################################################## COMPARISON SECTION ########################################################################
            ## Get MetaData Column Definition for Comparisons:
            if ($Table.SkipGraphMetaDataCheck -eq "TRUE")
            {
                Write-CmTraceLog -LogMessage "Skipping the MetaData Check for '$UriPart'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                # Create a blank ColDef so the next piece doesn't fail:
                $EntityColDef = New-Object -TypeName System.Collections.ArrayList;
                $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = "";"Name" = "";"Type" = "";"Nullable" = "";"IsCollection" = ""};
                [void]$EntityColDef.Add($CCO);

                # if we have expanded columns to deal with we'll build some dummy stuff here instead of calling the graph reverse engineering garbage:
                if ((-Not [String]::IsNullOrWhiteSpace($ExpandCols)) -and ($ExpandTableOrColumn -eq 'Table' -or $ExpandTableOrColumn -eq 'Both'))
                {
                    $ExpandedEntitiesColDef = New-Object -TypeName System.Collections.ArrayList;
                    foreach ($ExpCol in ($ExpandCols -split ","))
                    {
                        $CurColumnDefinition = New-Object -TypeName System.Collections.ArrayList;

                        $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "ParentOdataType";"Name" = "ParentOdataType";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
                        [void]$CurColumnDefinition.Add($CurColObj);
                        Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
                        $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "ParentId";"Name" = "ParentId";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
                        [void]$CurColumnDefinition.Add($CurColObj);
                        Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;

                        $CurExpObj = New-Object -TypeName PSObject -Property @{"ExpandedColName" = $ExpCol; "ColumnDefinition" = $CurColumnDefinition; "ExpandedSqlTableName" = "$($SqlTableName)_$($ExpCol)"};
                        [void]$ExpandedEntitiesColDef.Add($CurExpObj);
                        
                        Remove-Variable -Name CurColumnDefinition,CurExpObj -ErrorAction SilentlyContinue;
                    }
                }

                # Get the column definition that will be used to build the data table:
                $SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $SqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
                Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
            }
            else
            {
                if ((-Not [String]::IsNullOrWhiteSpace($ExpandCols)) -and ($ExpandTableOrColumn -eq 'Column')) {
                    $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -ExpandedColumns $ExpandCols -Version $UriVersion;
                } # end if adding expanded item as a column to the table
                  ## Note:
                   ## Get-ColumnDefWithInheritedProps returns an object of column definitions (DataName,Name,IsCollection,Type,Nullable) - An Array of PSCustomObjects
                   ## Get-ExpandedColDefWithInheritedProps returns an object of column objects (ExpandedColName,ExpandedColEntityName,ColumnDefinition) having a column definition (DataName,Name,IsCollection,Type,Nullable) as a hashtable? object as a property - An Array of PSCustomObjects
                elseif ((-Not [String]::IsNullOrWhiteSpace($ExpandCols)) -and ($ExpandTableOrColumn -eq 'Table')) {
                    $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion;
                    # Get an object with the expanded columns' column definition for use in the batch loop?
                    $ExpandedEntitiesColDef = Get-ExpandedColDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -ExpandedColumns $ExpandCols -Version $UriVersion;
                    # Add the SqlTableName for each item:
                    foreach ($itm in $ExpandedEntitiesColDef) {
                        Add-Member -InputObject $itm -MemberType NoteProperty -Name "ExpandedSqlTableName" -Value "$($SqlTableName)_$($itm.ExpandedColName)";
                    }
                    Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                } # end if creating separate table only
                elseif ((-Not [String]::IsNullOrWhiteSpace($ExpandCols)) -and ($ExpandTableOrColumn -eq 'Both')) {
                    $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -ExpandedColumns $ExpandCols -Version $UriVersion;
                    # Get an object with the expanded columns' column definition for use in the batch loop?
                    $ExpandedEntitiesColDef = Get-ExpandedColDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -ExpandedColumns $ExpandCols -Version $UriVersion;
                    # Add the SqlTableName for each item:
                    foreach ($itm in $ExpandedEntitiesColDef) {
                        Add-Member -InputObject $itm -MemberType NoteProperty -Name "ExpandedSqlTableName" -Value "$($SqlTableName)_$($itm.ExpandedColName)";
                    }
                    Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                } # end if creating separate table AND adding to columns
                else {
                    $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion;
                } # end if no expanded column information is to be added
    
                ## Alert if we don't have any metadata info and skip to the next item...:
                if (-not $EntityColDef) {
                    Write-CmTraceLog -LogMessage "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! If this is a valid call then consider using the 'SkipGraphMetaDataCheck' flag for this URI." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Skipping and moving to the next URL..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    
                    ## Log the 'skip' to Sql:
                    if ($SqlLogByTblId) {
                        [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -8;ErrorMessage = "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! If this is a valid call then consider using the 'SkipGraphMetaDataCheck' flag for this URI."} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                        $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                        ##Check results?:
                        if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                            Write-CmTraceLog -LogMessage "Successfully logged the skipping of the Specific URL Group/Table to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                        else {# Failure
                            Write-CmTraceLog -LogMessage "Failed to log the skipping of the Specific URL Group/Table to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        }
                        Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                    }
                    
                    ## Cleanup the variables created thus far:
                    Remove-Variable -Name UriPart,ExpandCols,ExpandTableOrColumn,UriVersion,UriParts,SqlTableName,GraphMetaDataEntityName,SqlLogByTblId,ExpandedEntitiesColDef -ErrorAction SilentlyContinue;
                    
                    continue;
                }
                ## Otherwise, let's compare the SQL and Graph properties to create a new SqlDefinition (containing the DataName and IsCollection properties found in the Graph properties) and alert on any property differences (removed/added).
                else {
                    $SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $SqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
                } # End of Data Comparison ($EntityColDef exists)
            }
            ######################################################################## END COMPARISON SECTION ####################################################################
            #endregion GraphMetaData & SqlMetaData Comparison
            
            # Build the "$Select" portion of the Url and pass in???

            ## Create the URL based on whether there are selected and/or expanded columns or not:
            if ((-Not [String]::IsNullOrWhiteSpace($SelectCols)) -and (-Not [String]::IsNullOrWhiteSpace($ExpandCols)))
            {
                [string]$LogUriPart = "$($UriPart)?`$select=$SelectCols&`$expand=$ExpandCols";
            }
            elseif ((-Not [String]::IsNullOrWhiteSpace($SelectCols)) -and ([String]::IsNullOrWhiteSpace($ExpandCols)))
            {
                [string]$LogUriPart = "$($UriPart)?`$select=$SelectCols";
            }
            elseif (([String]::IsNullOrWhiteSpace($SelectCols)) -and (-Not [String]::IsNullOrWhiteSpace($ExpandCols)))
            {
                [string]$LogUriPart = "$($UriPart)?`$expand=$ExpandCols";
            }
            else
            {
                [string]$LogUriPart = "$UriPart";
            }
            $OdataURL = "$BaseURL$($UriVersion)/$LogUriPart";

            ## Log the "SpecificURL" information as XML elements for more granular logging...
            if ($SqlLogByTblId) {
                [string]$SqlXmlLogTxt = Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $LogUriPart;UriVersion = $UriVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -IsFirstXml -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                ##Check results?:
                if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Successfully logged the start of the URL refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# Failure
                    Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the URL refresh will not be logged in XML!; the error was:`r`n$($SqlLogTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
                }
                Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
            }

            ## Prepare for the while loop
            $IsBatchData = if ($NoTruncate) {$true;} else {$false;};
            $CurRecordCount = 0;
    
            ## If we get data in batches this while loop will handle that:
            while ($OdataURL) {
                ## Determine whether we need to truncate/log the table or not in this iteration (if inserting data in batches we only want to truncate/log the table on the first batch!)
                if (-not $IsBatchData) {
                    $TruncateSqlTable = $true;
                }
                else {
                    $TruncateSqlTable = $false;
                }
    
                ## Get the data from Graph:
                Write-CmTraceLog -LogMessage "Getting data for '$LogUriPart' from Graph..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                $DtaObjFrmDS = Get-IntuneOpStoreData -OdataUrl $OdataURL -WriteBatchSize $WriteBatchSize -GetAuthStringCmd $GetAuthStringCmd -VerboseRecordCount $VerboseRecordCount -CurNumRecords $CurRecordCount -LogFullPath $LogFullPath -Verbose:$isVerbose;
    
                $OdataURL = $DtaObjFrmDS.URL;
                $CurRecordCount = $DtaObjFrmDS.RecordCount;
    
                ## if we don't have any records let's break out of the loop (and log the 'completion'); otherwise keep processing...
                if ($CurRecordCount -eq 0) {
                    Write-CmTraceLog -LogMessage "No Records returned; Moving to next table..." -LogFullPath $LogFullPath -MessageType Warning -Component $scriptName -Verbose:$isVerbose;
                    
                    ## Create an error number/message which we'll use at the end of the while loop:
                    [string]$CurErrorNumber = "-7";
                    if ($DtaObjFrmDS.ErrorCaught -eq "true") {
                        [string]$CurErrorMessage = "No Records returned from the service for ""$LogUriPart""`r`n$($DtaObjFrmDS.ErrorMessage)";
                    }
                    else {
                        [string]$CurErrorMessage = "No Records returned from the service for ""$LogUriPart""";
                    }

                    $RecordsNotImported = 0;
                    $RecordsImported = 0;
                    
                    Remove-Variable -Name DtaObjFrmDS -ErrorAction SilentlyContinue;
    
                    break; # break out of the while loop...
                }
    
                ## Convert the data we got from the service to a DataTable so that we can import it into SQL:
                Write-CmTraceLog -LogMessage "Converting the data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                $DtaTbl = ConvertTo-DataTable -InputObject $DtaObjFrmDS.DataObject -ColumnDef $SqlDefinition;
                Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                ## Only try to Truncate the table if it is the first or only batch of data:
                if ($TruncateSqlTable) {
                    Write-CmTraceLog -LogMessage "Truncating the table '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $SqlTableName;
    
                    ## Check to make sure we were able to truncate the table:
                    if ($SqlTruncTblObj.Value -eq 0) {
                        Write-CmTraceLog -LogMessage "Table Truncated." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

                        if ($SqlTruncTblObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                    }
                    else {
                        Write-CmTraceLog -LogMessage "There was an error trying to truncate the table. We'll need to skip this URL/Table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        if ($SqlTruncTblObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        }

                        ## Make sure to subtract the records that didn't get imported from the total records so we log the count as accurately as possible:
                        $RecordsNotImported = $($DtaTbl.Rows.Count);
                        $RecordsImported = $CurRecordCount - $RecordsNotImported;
                        
                        ## Create an error number/message which we'll use at the end of the while loop:
                        [string]$CurErrorNumber = "-7";
                        if ($DtaObjFrmDS.ErrorCaught -eq "true") {
                            if ($SqlTruncTblObj.RetryOccurred) {
                                [string]$CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n`r`nWe also caught the following error(s) from the service:`r`n$($DtaObjFrmDS.ErrorMessage)";
                            }
                            else {
                                [string]$CurErrorMessage = "There was an error trying to truncate the table. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)`r`n`r`nWe also caught the following error(s) from the service:`r`n$($DtaObjFrmDS.ErrorMessage)";
                            }
                        }
                        else {
                            if ($SqlTruncTblObj.RetryOccurred) {
                                [string]$CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                            }
                            else {
                                [string]$CurErrorMessage = "There was an error trying to truncate the table. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                            }
                        }
    
                        ## Because we have some data we don't want to "break/continue" the while loop so we can try to process any expanded column entities that may exist.
                    }
                    Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                }
                else { # Not Truncating
                    Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                
                #region Write DataTable to SQL
                ## Write the data to SQL (if there's no error message created yet...):
                if (-not $CurErrorMessage) {
                    ## Create the 'splat' object from combining the base SqlConnSplat and ImportSplatParams objects and adding our custom items needed to import:
                    $ImportSplat = $SqlConnSplat + $ImportSplatParams + @{SchemaName = $SqlSchemaName; TableName = $SqlTableName};
                    if ($DtaTbl.Rows.Count -ge 200000 -and $null -eq $BulkCopyBatchSize) {
                        $ImportSplat.Add("BulkCopyBatchSize", 200000);
                    }
                    elseif ($null -ne $BulkCopyBatchSize) {
                        $ImportSplat.Add("BulkCopyBatchSize", $BulkCopyBatchSize);
                    }

                    Write-CmTraceLog -LogMessage "Starting the import of the DataTable for '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    
                    $SqlImportRetObj = Import-SqlTableData @ImportSplat -ImportData $DtaTbl -LogFullPath $LogFullPath -Verbose:$isVerbose;
                    Remove-Variable -Name ImportSplat -ErrorAction SilentlyContinue;
    
                    if ($SqlImportRetObj.Value -eq 0) {
                        ## Make sure we have the RecordsImported for proper logging
                        $RecordsImported = $CurRecordCount;
                        Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $($DtaTbl.Rows.Count)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                        if ($SqlImportRetObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            $ImportRetriesOccurred = $true;
                        }
                    }
                    else {
                        Write-CmTraceLog -LogMessage "Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
    
                        if ($SqlImportRetObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            $ImportRetriesOccurred = $true;
                        }
    
                        # Make sure to subtract the records that didn't get imported from the total records so we log the count as accurately as possible:
                        $RecordsNotImported = $($DtaTbl.Rows.Count);
                        $RecordsImported = $CurRecordCount - $RecordsNotImported;
                        $ImportError = $true;
    
                        ## Create an error number/message which we'll use at the end of the while loop:
                        [string]$CurErrorNumber = "-6";
                        if ($DtaObjFrmDS.ErrorCaught -eq "true") {
                            if ($ImportRetriesOccurred) {
                                [string]$CurErrorMessage = "Error Importing the records into SQL; however, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n`r`nWe also caught the following error(s) from the service:`r`n$($DtaObjFrmDS.ErrorMessage)";
                            }
                            else {
                                [string]$CurErrorMessage = "Error Importing the records into SQL. Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n`r`nWe also caught the following error(s) from the service:`r`n$($DtaObjFrmDS.ErrorMessage)";
                            }
                        }
                        else {
                            [string]$CurErrorMessage = "Error Importing the records into SQL. Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlImportRetObj.ErrorCaptured)";
                        }
                        ## Because we have some data we don't want to "break/continue" the while loop so we can try to process any expanded column entities that may exist.
                    }
                    Remove-Variable -Name SqlImportRetObj,DtaTbl -ErrorAction SilentlyContinue;
                }
                #endregion  Write DataTable to SQL
    
    
                #region Expanded Columns Handling
                #####################################################################################################################################################################################################################
                ############################################ Expand Columns into separate tables logic is here, but uses some of the same column comparison functions ###############################################################
                ############################################ This needs to be looked at to see if this should be here or somewhere else; or a function?? ############################################################################
                #####################################################################################################################################################################################################################
                if ($ExpandedEntitiesColDef) {
                    Write-CmTraceLog -LogMessage "Will now start handling the '`$expand' columns which will be separate tables..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
    
                ##
                foreach ($ExpEnt in $ExpandedEntitiesColDef) {
                    if (-not $ExpEnt.StopProcessing) {
                        $CurSqlTableName = $ExpEnt.ExpandedSqlTableName;
    
                        ## Start Logging of the expanded column table in SQL:
                        if ($SqlLogByTblId -and $TruncateSqlTable) {
                            if ($ExpEnt.SqlStartTime) {
                                # We don't have to do anything becuase we're in a batch loop and we've already gotten the start time!
                            }
                            else {# We need to create the start time and try to log:
                                $ExpEntStrt = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                                # Build and Run the insert command:
                                [string]$SqlLogCmd = Set-LogToSqlCommand -TableToLog $CurSqlTableName -BatchId $SqlLogTblId -PropertyValues @{StartDateUTC = $ExpEntStrt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                                $ExpEntLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                                # Check results:
                                if ($ExpEntLogByTblIdObj.Value -eq 0) {#successful
                                    $ExpEntLogByTblId = $ExpEntLogByTblIdObj.SqlColVal;
                                    Write-CmTraceLog -LogMessage "*** Successfully logged the start of the refresh of table '$CurSqlTableName' to SQL table; Log ID = $ExpEntLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                    Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlPkId" -Value $ExpEntLogByTblId;
                                    Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlStartTime" -Value $ExpEntStrt;
                                }
                                else {# Failure
                                    Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                    Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlStartTime" -Value $ExpEntStrt;
                                }
                            } # end: creating the start time and trying to log to Sql
                        }
                        Remove-Variable -Name ExpEntLogByTblIdObj,ExpEntLogByTblId,SqlLogCmd,ExpEntStrt -ErrorAction SilentlyContinue;
    
                        #region Expanded Columns: Create/Set SqlDefinition
                        ## we already have the data so we just need to get Sql Table Definition:
                        if ($ExpEnt.SqlDefinition) { # if we created it before (this is in a batch process) then get what was already defined previously:
                            $CurSqlDefinition = $ExpEnt.SqlDefinition;
                        }
                        else { # this is the first 'batch' (or only batch) so we need to create the Sql Definition:
                            $CurSqlDefinition = Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $CurSqlTableName;
    
                            ## Make sure there's a SQL definition for the expanded columns (since we're writing to a separate table):
                            if (-not $CurSqlDefinition) {
                                Write-CmTraceLog -LogMessage "*** '$CurSqlTableName' DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                Write-CmTraceLog -LogMessage "*** Skipping '$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                
                                ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrNum" -Value "-9";
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrMsg" -Value "TABLE DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!";
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "StopProcessing" -Value $true;
    
                                ## Cleanup the variables created thus far:
                                Remove-Variable -Name CurSqlTableName -ErrorAction SilentlyContinue;
    
                                continue;
                            }
    
                            ## Check for the Expanded Column's ColumnDefinition
                            if (-not $ExpEnt.ColumnDefinition) {
                                Write-CmTraceLog -LogMessage "*** COULD NOT FIND METADATA FOR '$($ExpEnt.ExpandedColEntityName)'!" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                Write-CmTraceLog -LogMessage "*** Skipping '$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                
                                ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrNum" -Value "-8";
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrMsg" -Value "COULD NOT FIND METADATA FOR ""$($ExpEnt.ExpandedColEntityName)""!";
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "StopProcessing" -Value $true;
    
                                ## Cleanup the variables created thus far:
                                Remove-Variable -Name CurSqlTableName,CurSqlDefinition -ErrorAction SilentlyContinue;
                                
                                continue;
                            }
                            else { # Create a new SQL definition by combining the information from Graph along with the SQL definition (to account for DataName and such). Note: this will also compare the properties and alert on deltas
                                $CurSqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $ExpEnt.ColumnDefinition -SqlColumnDefinition $CurSqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
                            }
    
                            ## Lastly, let's add the definition to the main object for possible future processing:
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlDefinition" -Value $CurSqlDefinition;
                        } # End: creating and setting the Sql Definition
                        #endregion Expanded Columns: Create/Set SqlDefinition
                        
                        ## Create the Parent properties in the expanded column data:
                        Write-CmTraceLog -LogMessage "*** Creating the Parent properties..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        foreach ($itm in $DtaObjFrmDS.DataObject) {
                            if ($itm."$($ExpEnt.ExpandedColName)" -ne $null) {
                                ### Using Add-Member directly doesn't work here for some reason. Ex: Add-Member -InputObject $itm."$($ExpEnt.ExpandedColName)" -MemberType NoteProperty -Name "ParentId" -Value $itm.id;
                                $itm."$($ExpEnt.ExpandedColName)" | Add-Member -MemberType NoteProperty -Name "ParentOdataType" -Value $itm.'@odata.type';
                                $itm."$($ExpEnt.ExpandedColName)" | Add-Member -MemberType NoteProperty -Name "ParentId" -Value $itm.id;
                            }
                        }
                        Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                        ## Now that we added the parent properties to the expanded column/object we need to create an object of just that column/object:
                        $CurDtaObj = $DtaObjFrmDS.DataObject."$($ExpEnt.ExpandedColName)";
    
                        if ($ExpEnt.RecordsImported) {
                            $ExpCurRecCount = ($CurDtaObj.Count + $ExpEnt.RecordsImported);
                        }
                        else {
                            $ExpCurRecCount = $CurDtaObj.Count;
                        }
    
                        #region Expanded Columns: No Data Exists Logic
                        # if no data exists in the expanded column then we need to skip it so we don't hit an error:
                        if ($ExpCurRecCount -eq 0)
                        {
                            Write-CmTraceLog -LogMessage "*** No data exists for the expanded column '$($ExpEnt.ExpandedColName)'!" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            ## Only try to Truncate the table if this is the first or only batch of data:
                            if ($TruncateSqlTable)
                            {
                                Write-CmTraceLog -LogMessage "*** Truncating the table '$SqlSchemaName.$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $CurSqlTableName;
                                # check the results of the truncate:
                                if ($SqlTruncTblObj.Value -eq 0) {
                                    Write-CmTraceLog -LogMessage "*** Table Truncated" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                    if ($SqlTruncTblObj.RetryOccurred) {
                                        Write-CmTraceLog -LogMessage "*** Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                    }
                                    Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                                }
                                else {
                                    Write-CmTraceLog -LogMessage "*** There was an error trying to truncate the table." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                    Write-CmTraceLog -LogMessage "*** Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                    if ($SqlTruncTblObj.RetryOccurred) {
                                        Write-CmTraceLog -LogMessage "*** Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                    }
                                    
                                    Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                                }
                            }

                            Write-CmTraceLog -LogMessage "*** Skipping '$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

                            ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrNum" -Value "-4";
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrMsg" -Value "No data for the expanded column was found.";
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "StopProcessing" -Value $true;

                            Remove-Variable -Name CurSqlTableName,CurSqlDefinition,CurDtaObj -ErrorAction SilentlyContinue;
                            
                            continue;
                        }
                        #endregion Expanded Columns: No Data Exists Logic
                        
                        ## Convert the data object into a DataTable object:
                        Write-CmTraceLog -LogMessage "*** Converting the Expanded Column data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        $DtaTbl = ConvertTo-DataTable -InputObject $CurDtaObj -ColumnDef $CurSqlDefinition;
                        Write-CmTraceLog -LogMessage "*** DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        
                        #region Expanded Columns: Truncate Table Logic
                        ## Only try to Truncate the table if this is the first or only batch of data:
                        if ($TruncateSqlTable) {
                            Write-CmTraceLog -LogMessage "*** Truncating the table '$SqlSchemaName.$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $CurSqlTableName;
                            # check the results of the truncate:
                            if ($SqlTruncTblObj.Value -eq 0) {
                                Write-CmTraceLog -LogMessage "*** Table Truncated" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                if ($SqlTruncTblObj.RetryOccurred) {
                                    Write-CmTraceLog -LogMessage "*** Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                }
                                Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                            }
                            else {
                                Write-CmTraceLog -LogMessage "*** There was an error trying to truncate the table. We'll need to skip this URL/Table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                Write-CmTraceLog -LogMessage "*** Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                if ($SqlTruncTblObj.RetryOccurred) {
                                    Write-CmTraceLog -LogMessage "*** Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                }

                                ## Create variable to be used in next step:
                                if ($SqlTruncTblObj.RetryOccurred) {
                                    [string]$ErrMsg = "*** There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)).`r`nError Captured:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                                }
                                else {
                                    [string]$ErrMsg = "*** There was an error trying to truncate the table.`r`nError Captured:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                                }
                                
                                ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrNum" -Value "-7";
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrMsg" -Value $ErrMsg;
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "RecordsNotImported" -Value $($DtaTbl.Rows.Count);
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "RecordsImported" -Value ($ExpCurRecCount - $($DtaTbl.Rows.Count));
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "StopProcessing" -Value $true;
                                
                                Remove-Variable -Name CurSqlTableName,CurSqlDefinition,CurDtaObj,DtaTbl,SqlTruncTblObj -ErrorAction SilentlyContinue;
                                
                                continue;
                            }
                        }
                        else {
                            Write-CmTraceLog -LogMessage "*** Writing data in batches...no need to truncate '$SqlSchemaName.$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                        #endregion Expanded Columns: Truncate Table Logic
    
                        #region Expanded Columns: Write Data to SQL
                        ## Write the data to SQL:
                        # Create the 'splat' object from combining the base SqlConnSplat and ImportSplatParams objects and adding our custom items needed to import:
                        $ImportSplat = $SqlConnSplat + $ImportSplatParams + @{SchemaName = $SqlSchemaName; TableName = $CurSqlTableName};
                        if ($DtaTbl.Rows.Count -ge 200000 -and $null -eq $BulkCopyBatchSize) {
                            $ImportSplat.Add("BulkCopyBatchSize", 200000);
                        }
                        elseif ($null -ne $BulkCopyBatchSize) {
                            $ImportSplat.Add("BulkCopyBatchSize", $BulkCopyBatchSize);
                        }
                        
                        Write-CmTraceLog -LogMessage "*** Starting the import of the DataTable for '$SqlSchemaName.$CurSqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        $SqlImportRetObj = Import-SqlTableData @ImportSplat -ImportData $DtaTbl -LogFullPath $LogFullPath -Verbose:$isVerbose;
                        Remove-Variable -Name ImportSplat -ErrorAction SilentlyContinue;

                        # Check the result of the import:
                        if ($SqlImportRetObj.Value -eq 0) {
                            Write-CmTraceLog -LogMessage "*** Finished importing data for '$SqlSchemaName.$CurSqlTableName'. Records Imported: $($DtaTbl.Rows.Count)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                            if ($SqlImportRetObj.RetryOccurred) {
                                Write-CmTraceLog -LogMessage "*** Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                if (-not $ExpEnt.ImportRetriesOccurred) {
                                    Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "ImportRetriesOccurred" -Value $true;
                                }
                            }
                            Remove-Variable -Name SqlImportRetObj -ErrorAction SilentlyContinue;
                            
                            if ($ExpEnt.RecordsImported) {
                                $ExpEnt.RecordsImported = $ExpCurRecCount;
                            }
                            else {
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "RecordsImported" -Value $ExpCurRecCount;
                            }
                        }
                        else { # Failure Importing
                            Write-CmTraceLog -LogMessage "*** Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                            
                            if ($SqlImportRetObj.RetryOccurred) {
                                Write-CmTraceLog -LogMessage "*** Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

                                ## Add this property to the expanded column for correct logging. Do it here so we don't have to do the check again.
                                if (-not $ExpEnt.ImportRetriesOccurred) {
                                    Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "ImportRetriesOccurred" -Value $true;
                                }
                                $SqlErrMsg = "*** Error Importing the records into SQL. However, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). Records NOT imported: $($DtaTbl.Rows.Count).`r`nError Captured:`r`n$($SqlImportRetObj.ErrorCaptured)";
                            }
                            else {
                                $SqlErrMsg = "*** Error Importing the records into SQL. Records NOT imported: $($DtaTbl.Rows.Count).`r`nError Captured:`r`n$($SqlImportRetObj.ErrorCaptured)";
                            }
    
                            ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrNum" -Value "-6";
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlErrMsg" -Value $SqlErrMsg;
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "RecordsNotImported" -Value $($DtaTbl.Rows.Count);
                            if ($ExpEnt.RecordsImported) {
                                $ExpEnt.RecordsImported = ($ExpCurRecCount - $($DtaTbl.Rows.Count));
                            }
                            else {
                                Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "RecordsImported" -Value ($ExpCurRecCount - $($DtaTbl.Rows.Count));
                            }
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "ImportError" -Value $true;
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "StopProcessing" -Value $true;
    
                            Remove-Variable -Name CurSqlTableName,CurSqlDefinition,CurDtaObj,DtaTbl,SqlImportRetObj,SqlErrMsg -ErrorAction SilentlyContinue;
    
                            continue;
                        }
                        #endregion Expanded Columns: Write Data to SQL
    
                        ## Add some properties to the expanded column so that we can correctly log the information later (after the loops):
                         # if this is a batch process we may already have a SqlEndTime property so we just need to update it, otherwise create the property (on the first run):
                        if ($ExpEnt.SqlEndTime) {
                            $ExpEnt.SqlEndTime = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                        }
                        else {
                            Add-Member -InputObject $ExpEnt -MemberType NoteProperty -Name "SqlEndTime" -Value $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));
                        }
                        
                        Remove-Variable -Name DtaTbl,CurDtaObj,CurSqlTableName,CurSqlDefinition,ExpCurRecCount -ErrorAction SilentlyContinue;
                    } # End: if expanded entity doesn't have a StopProcessing equal to true
                } # End: Foreach expanded column to separate table
                Remove-Variable -Name ExpEnt -ErrorAction SilentlyContinue;

                if ($ExpandedEntitiesColDef) {
                    Write-CmTraceLog -LogMessage "...The '`$expand' columns have been handled into separate tables..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "...The logging of the finish date will occur at a later time due to possible batching..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                ########################################################################################## End: Expanded Columns to Separate Tables Stuff ###########################################################################
                #endregion Expanded Columns Handling
    
                ### Final checks/assignments (to know if getting data in batches):
                ## If there was an error caught we're going to move to the next item in the loop:
                if ($CurErrorMessage) {
                    Remove-Variable -Name DtaObjFrmDS -ErrorAction SilentlyContinue;
                    break; # stop processing the While OdataURL loop
                }
                elseif ($DtaObjFrmDS.ErrorCaught -eq "true") { # use string or $true/$false???
                    ## Create an error number/message which we'll use at the end of the while loop:
                    [string]$CurErrorNumber = "-1";
                    [string]$CurErrorMessage = "An exception was caught while getting data from the service for ""$LogUriPart""`r`n$($DtaObjFrmDS.ErrorMessage)";
                    Remove-Variable -Name DtaObjFrmDS -ErrorAction SilentlyContinue;
                    break; # stop processing the While OdataURL loop
                }
                ## If we still have an "OdataURL" then we're doing this in batches
                if ($OdataURL) {
                    $IsBatchData = $true;
                }
                ### End final checks
    
                # Cleanup for the next item in the while loop:
                Remove-Variable -Name DtaObjFrmDS -ErrorAction SilentlyContinue;
    
            } # End While Loop (for OdataUrl)
    
            ## Write information about the completion of the URL:
            if ($CurErrorMessage) {
                Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName' and any columns that are being 'expanded' into separate tables. However, an error was caught while getting the data so it may not be complete data that was captured/imported. The Error information we caught is:`r`n$CurErrorMessage" -LogFullPath $LogFullPath -Component $scriptName -MessageType Warning -Verbose:$isVerbose;
            }
            else {
                Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName' and any columns that are being 'expanded' into separate tables." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
    
            
            ### Log to SQL Table - completion of Expanded Table(s):
            foreach ($ExpTblLogId in $ExpandedEntitiesColDef) {
                if ($ExpTblLogId.SqlPkId) {
                    ## Create and Run the XML and Insert Statements:
                    [string]$SqlXmlLogTxt = Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $LogUriPart;UriVersion = $UriVersion};StartDateTimeUTC = $ExpTblLogId.SqlStartTime;EndDateTimeUTC = $ExpTblLogId.SqlEndTime;ErrorNumber = $ExpTblLogId.SqlErrNum;ErrorDetails = $ExpTblLogId.SqlErrMsg;RecordsImported = $ExpTblLogId.RecordsImported;RecordsNotImported = $ExpTblLogId.RecordsNotImported;ImportErrorOccurred = $ExpTblLogId.ImportError;ImportRetriesOccurred = $ExpTblLogId.ImportRetriesOccurred});
                    $PropValues =
                        @{
                          EndDateUTC = if($ExpTblLogId.SqlEndTime) {$ExpTblLogId.SqlEndTime;} else {"NULL";}
                          ErrorNumber = if ($ExpTblLogId.SqlErrNum) {$ExpTblLogId.SqlErrNum;} elseif (-not $ExpTblLogId.SqlEndTime) {-99;} else {$null;}
                          ErrorMessage = if ($ExpTblLogId.SqlErrMsg) {$ExpTblLogId.SqlErrMsg;} elseif (-not $ExpTblLogId.SqlEndTime) {"UNKNOWN ERROR ENCOUNTERED IN SCRIPT";} else {$null;}
                          ExtendedInfo = $SqlXmlLogTxt
                        }
                    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $ExpTblLogId.SqlPkId -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $ExpTblLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                    ## Check to see if we were successful or not:
                    if ($ExpTblLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "*** Successfully logged the refresh for '$SqlSchemaName.$($ExpTblLogId.ExpandedSqlTableName)'; Log ID = $($ExpTblLogId.SqlPkId)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# Failure to log
                        Write-CmTraceLog -LogMessage "*** There was an error trying to log the completion of the refresh for '$SqlSchemaName.$($ExpTblLogId.ExpandedSqlTableName)'; Log ID = $($ExpTblLogId.SqlPkId)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Warning -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "*** Error Returned from the Call:`r`n$($ExpTblLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Warning -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name ExpTblLogByTblIdObj,SqlXmlLogTxt,SqlSetStatement,SqlLogCmd,PropValues -ErrorAction SilentlyContinue;
                }
                else {
                    Write-CmTraceLog -LogMessage "*** We weren't able to log to SQL the refresh start time for '$SqlSchemaName.$($ExpTblLogId.ExpandedSqlTableName)' so we can't log the completion either..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Warning -Verbose:$isVerbose;
                }
            } # End: Foreach expanded column table logging
            Remove-Variable -Name ExpTblLogId,ExpandedEntitiesColDef -ErrorAction SilentlyContinue;
            
            ## Specific Table Completion Logging:
            if ($SqlLogByTblId) {
                # Build the xml insert string with all the information we want to store for the URL:
                [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{EndDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));RecordsImported = $RecordsImported;RecordsNotImported = $RecordsNotImported;ImportErrorOccurred = $ImportError;ImportRetriesOccurred = $ImportRetriesOccurred;RetriesOccurred = $RetriesOccurred;ErrorDetails = $CurErrorMessage});
                ## Create and Run the SQL Statement:
                $PropValues =
                    @{
                      EndDateUTC = "SYSUTCDATETIME()"
                      ErrorNumber = if ($CurErrorNumber) {$CurErrorNumber;} else {$null;}
                      ErrorMessage = if ($CurErrorMessage) {$CurErrorMessage;} else {$null;}
                      ExtendedInfo = $SqlXmlLogTxt
                    }
                [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -AttrName "UriPart" -AttrValue $LogUriPart -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                ## Check to see if we were successful or not:
                if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Successfully logged the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# Value will equal -1 for errors...can check the "ErrorCaptured" property to know what happened
                    Write-CmTraceLog -LogMessage "There was an error trying to log the completion of the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
            } # End: logging the completion of the specific table
            Remove-Variable -Name CurErrorNumber,CurErrorMessage,SqlXmlLogTxt,SqlLogCmd,PropValues,SqlLogByTblIdObj,SqlLogByTblId,RecordsImported,RecordsNotImported,ImportError,RetriesOccurred,ImportRetriesOccurred -ErrorAction SilentlyContinue;
    
            ## Cleanup Current 'table' item:
            Remove-Variable -Name EntityColDef,UriPart,UriParts,UriVersion,ExpandCols,SelectCols,LogUriPart,ExpandTableOrColumn,SqlTableName,GraphMetaDataEntityName,SqlDefinition,DtaObjFrmDS,OdataURL,IsBatchData,CurRecordCount,TruncateSqlTable,DrillDownTable,CurDrillDownInfo,SqlLogByTblIdObj,SqlLogByTblId,ExpandedEntitiesLoggingByTblObj -ErrorAction SilentlyContinue;
    
        } # End "if there is not a UriPartType"
    
    } # End foreach table in TablesToSync where UriPartType isn't specified
    Remove-Variable -Name Table -ErrorAction SilentlyContinue;
} # End: Process "Normal" URIs...

Remove-Variable -Name ProcessUrisWithoutPartType -ErrorAction SilentlyContinue;


####### Process the Specific URL items #########
if ($ProcessSpecificURLs) {
## Note: If a specific url has an "expand" then we will only expand it to the target table as a column and not create a separate table for the expanded column as long as the target table has a column for that expand property.
    Write-CmTraceLog -LogMessage "Processing the 'Specific Urls' in the 'TablesToSync' Object" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
    foreach ($SpecUrlGrp in $SpecificURLsGrouped) {
        Write-CmTraceLog -LogMessage "Working with Specific URL group/Sql Table: '$($SpecUrlGrp.Name)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
        $SqlTableName = $SpecUrlGrp.Name;
        
        ## Log to SQL Table - start of table (Note: this used to be later in the process but I moved it up...should see if this is good or not)
        # Build and Run the insert command:
        [string]$SqlLogCmd = Set-LogToSqlCommand -TableToLog $SqlTableName -BatchId $SqlLogTblId -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
        $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
        # Check results:
        if ($SqlLogByTblIdObj.Value -eq 0) {#successful
            $SqlLogByTblId = $SqlLogByTblIdObj.SqlColVal
            Write-CmTraceLog -LogMessage "Successfully logged the start of the refresh of table '$SqlTableName' to SQL table; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        }
        else {# Failure
            Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        }
        Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;    
        
        ## Use the first UriPart from the group to determine Sql and Graph property definitions for comparisons and data table creation
        $Url = $SpecUrlGrp.Group[0].UriPart;
        $ParentCols = $SpecUrlGrp.Group[0].ParentCols;
    
        ## Check the UriPart to see if it contains elements which we need to strip off and/or handle differently:
        if ($Url.IndexOf('graph.microsoft.com/') -ne -1) {
            $UriStartInd = $Url.IndexOf('graph.microsoft.com/')+20;
            $UriVersion = $Url.Substring($UriStartInd,$Url.IndexOf('/',$UriStartInd)-$UriStartInd);
            $UriPart = $Url.Substring($UriStartInd+$UriVersion.Length+1);
        }
        else {
            $UriVersion = $SpecUrlGrp.Group[0].Version;
            $UriPart = $Url;
        }
        Remove-Variable -Name UriStartInd,Url -ErrorAction SilentlyContinue;
        
        ## Now we'll check the UriPart for query parameters:
        if ($UriPart.IndexOf('?') -ne -1) {
            $QryParamPart = $UriPart.Substring($UriPart.IndexOf('?'),($UriPart.Length - $UriPart.IndexOf('?')));
            $UriPart = $UriPart.Substring(0,$UriPart.IndexOf('?'));
        
            foreach ($QryParam in ($QryParamPart.Replace('?','').Replace(' ','').Replace('$','') -split '&')) {
                #
                Switch ($QryParam.Substring(0,$QryParam.IndexOf('='))) {
                        "expand"  {
                            $UriExpandCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                            break;
                        }
                        "select" { # I'm not really doing anything with this at the moment...
                            $UriSelectCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                            break;
                        }
                }
                
                if ($UriExpandCols) {
                    if ($UriExpandCols.IndexOf('(') -ne -1) {
                        #throw "I'm not going to deal with this type of url just yet...perhaps in a later iteration but not now." Example: categories(select=blah,blah2,blah3),assignments
                        # maybe for now let's just remove all the select crap and keep just the expand portion?
                        foreach ($Parentheses in $UriExpandCols.Split(')')) {
                            if ($Parentheses) {
                                $ExpandParam += $Parentheses.Substring(0,$Parentheses.IndexOf('('));
                            }
                        }
                        Remove-Variable -Name Parentheses -ErrorAction SilentlyContinue;
                    }
                    else {
                        $ExpandParam = $UriExpandCols;
                    }
                }
            } # End foreach $QryParam in $QryParamPart
            Remove-Variable -Name QryParam -ErrorAction SilentlyContinue;
        } # End checking for query parameters (?) in the UriPart
        Remove-Variable -Name QryParamPart,UriExpandCols,UriSelectCols -ErrorAction SilentlyContinue;
        
        $UriParts = $UriPart -split "/";
        # Reverse the order of the array for now:
        [array]::Reverse($UriParts);
    
        # ? - Do a check on ExpandCols to make sure they all exist? If not there will be an error in the Get call...which would be handled anyway but...
    
        ## Get Sql Table Definition:
        $SqlDefinition = Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $SqlTableName;
    
        ## Make sure we have a table to work with; if not alert and go to the next specific url group:
        if (-not $SqlDefinition) {
            # should we automatically create the table and try again?
            Write-CmTraceLog -LogMessage "'$SqlTableName' DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "You can run the following to create the table(s):`r`n$(Get-SqlTableCreateStatementsFromUrl -UriPart $UriPart -UriVersion $UriVersion -SqlTableName $SqlTableName <#-UriExpandCols $UriExpandCols#>)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Warning -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "Skipping Specific Url Group '$($SpecUrlGrp.Name)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
            ## Log the 'skip' to Sql:
            if ($SqlLogByTblId) {
                # Build and Run the SQL command:
                [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -9;ErrorMessage = 'TABLE DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!'} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                ##Check results?:
                if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Successfully logged the skipping of the Specific URL Group/Table to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# Failure
                    Write-CmTraceLog -LogMessage "Failed to log the skipping of the Specific URL Group/Table to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                }
                Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name SqlTableName,SqlLogByTblId,ParentCols,UriVersion,UriPart,ExpandParam -ErrorAction SilentlyContinue;
    
            continue; # go to the next group...
        }
        Remove-Variable -Name UriPart -ErrorAction SilentlyContinue;
    
        #region GraphMetaData & SqlMetaData Comparison
        ######################################################################## COMPARISON SECTION ########################################################################
        ## Get MetaData Column Definition for Comparisons:
        if ($SpecUrlGrp.Group[0].SkipGraphMetaDataCheck -eq "TRUE") # this assumes that each URI in the group will have this property set the same
        {
            Write-CmTraceLog -LogMessage "Skipping the MetaData Check for '$UriPart'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            # Create a blank ColDef so the next piece doesn't fail:
            $EntityColDef = New-Object -TypeName System.Collections.ArrayList;
            $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = "";"Name" = "";"Type" = "";"Nullable" = "";"IsCollection" = ""};
            [void]$EntityColDef.Add($CCO);
            $SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $SqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
            Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
        }
        else
        {
            ## Determine the EntityName to use from Graph:
            foreach ($NavPrp in (Get-CollectionEntity -UrlPartsReversed $UriParts -Version $UriVersion).NavigationProperty)
            {
                if ($NavPrp.Name -eq $UriParts[0]) {
                    $GraphMetaDataEntityName = $NavPrp.Type.Replace("Collection(","").Replace(")","");
                    continue; # stop the foreach as soon as we find it...
                }
            }
            Remove-Variable -Name NavPrp,UriParts -ErrorAction SilentlyContinue;

            ## Get the Entity Column Definition (from Graph):
            if ($ExpandParam) {
                $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion -ExpandedColumns $ExpandParam;
                Remove-Variable -Name ExpandParam -ErrorAction SilentlyContinue;
            }
            else {
                $EntityColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion;
            }
    
            ## If the Specific URL group has a "ParentCols" hashtable then we'll create the column definition using these parent columns in addition to the data that is returned for the URI:
            if (-Not [String]::IsNullOrWhiteSpace($ParentCols)) {
                $CCD = New-Object System.Collections.ArrayList;
                
                foreach ($pc in $ParentCols.GetEnumerator().Keys) {
                    $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = "$pc";"Name" = "$pc";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
                    [void]$CCD.Add($CCO);
                    Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
                }
                Remove-Variable -Name pc,ParentCols -ErrorAction SilentlyContinue;
    
                # Now add all the original properties/columns in:
                foreach ($c in $EntityColDef) {
                    $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = $c.DataName;"Name" = $c.Name;"Type" = $c.Type;"Nullable" = $c.Nullable;"IsCollection" = $c.IsCollection};
                    [void]$CCD.Add($CCO);
                    Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
                }
                Remove-Variable -Name c -ErrorAction SilentlyContinue;
    
                # Assign the new result set to what we expect:
                $EntityColDef = $CCD;
                Remove-Variable -Name CCD -ErrorAction SilentlyContinue;
            }
    
            ## Alert if we don't have any metadata info and skip to the next item...:
            if (-not $EntityColDef) {
                Write-CmTraceLog -LogMessage "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! If this is a valid call then consider using the 'SkipGraphMetaDataCheck' flag for this URI." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Skipping Specific Url Group '$($SpecUrlGrp.Name)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                
                ## Log the 'skip' to Sql:
                if ($SqlLogByTblId) {
                    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -8;ErrorMessage = "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! PLEASE LOOK INTO THIS!"} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                    ##Check results?:
                    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "Successfully logged the skipping of the Specific URL Group/Table to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# Failure
                        Write-CmTraceLog -LogMessage "Failed to log the skipping of the Specific URL Group/Table to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                }
                
                Remove-Variable -Name SqlTableName,SqlLogByTblId,UriVersion -ErrorAction SilentlyContinue;
    
                continue; # go to the next group...
            }
            ## Otherwise, let's compare the SQL and Graph properties to create a new SqlDefinition (containing the DataName and IsCollection properties found in the Graph properties)
             # and alert on any property differences (removed/added).
            else {
                $SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $SqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
            } # End of Data Comparison ($EntityColDef exists)
        }
        ######################################################################## END COMPARISON SECTION ####################################################################
        Remove-Variable -Name GraphMetaDataEntityName,EntityColDef,NavPrp,UriParts -ErrorAction SilentlyContinue;
        #endregion GraphMetaData & SqlMetaData Comparison
        
        ## Set some variables to use for the Specific URL Group/Table:
        $IsFirstSpecUrl = $true;
        $TruncateSqlTable = if ($NoTruncate) {$false;} else {$true;};
        [string]$SpecUrlGrpErrorMessage = "";
        
        ## We need to process each URI that is supposed to store data in the same table:
        foreach ($SpecUrl in $SpecUrlGrp.Group) {
            Write-CmTraceLog -LogMessage "Working with UriPart '$($SpecUrl.UriPart)'; getting the information for this URI..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
            ## check to make sure the Version exists (it is expected to be required but just in case...) for use in a few places:
            if (-Not [String]::IsNullOrWhiteSpace($SpecUrl.Version)) {
                $SpecUrlVersion = $SpecUrl.Version;
            }
            else {
                $SpecUrlVersion = $UriVersion;
            }
            
            ## Log the "SpecificURL" information as XML elements for more granular logging...
            if ($SqlLogByTblId) {
                if ($IsFirstSpecUrl) {
                    [string]$SqlXmlLogTxt = Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $SpecUrl.UriPart;UriVersion = $SpecUrlVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                    [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -IsFirstXml -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $IsFirstSpecUrl = $false;
                }
                else {
                    [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $SpecUrl.UriPart;UriVersion = $SpecUrlVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                    [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                }
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                ##Check results?:
                if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Successfully logged the start of the SpecificURL refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# Failure
                    Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the SpecificURL refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Error Captured for remediation:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
            }
    
            ## Create the Uri to call:
            if ($SpecUrl.UriPart.IndexOf('graph.microsoft.com/') -ne -1) {
                # if the UriPart has the "BaseURL" in it then we'll just use the given Url rather than build it:
                $OdataURL = $SpecUrl.UriPart;
            }
            elseif ($SpecUrl.UriPart.IndexOf('?') -ne -1) { # if it doesn't have the "BaseURL" but has a "?" then we'll use the entire URL but build it correctly:
                if ($SpecUrl.UriPart.StartsWith($SpecUrlVersion)) {
                    $OdataURL = "$BaseURL$($SpecUrl.UriPart)";
                }
                else {
                    $OdataURL = "$BaseURL$($SpecUrlVersion)/$($SpecUrl.UriPart)";
                }
            }
            else { # if it doesn't have the "BaseURL" then we'll build it:
                $OdataURL = "$BaseURL$($SpecUrlVersion)/$($SpecUrl.UriPart)";
            }
    
            ## Get the Parent Columns
            ## SQL Returns the ParentCols as a string whereas the other methods return it as a hashtable so we need to convert to a hashtable in those cases:
            if ($SpecUrl.ParentCols.GetType().Name -ne 'Hashtable')
            {
                $tmpStr = "";
                foreach ($ln in $SpecUrl.ParentCols.Split(';'))
                {
                    $tmpStr += "`n$($ln.Trim(',@}{').Replace('"','').Trim())";
                }
                $ParentCols = ConvertFrom-StringData -StringData $tmpStr;
                Remove-Variable -Name ln,tstString -ErrorAction SilentlyContinue;
            }
            else
            {
                $ParentCols = $SpecUrl.ParentCols;
            }
    
            ## Prepare for the While Loop:
            $CurRecordCount = 0;
            $RetriesOccurred = $false;
    
            #region SpecificURL: Get/Write Data along with all other logic
            ## If we get data in batches this while loop will handle that:
            while ($OdataURL) {
                ## Get the data from Graph:
                Write-CmTraceLog -LogMessage "Getting data for '$($SpecUrl.UriPart)' from Graph..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                $DtaObjFrmDS = Get-IntuneOpStoreData -OdataUrl $OdataURL -WriteBatchSize $WriteBatchSize -GetAuthStringCmd $GetAuthStringCmd -VerboseRecordCount $VerboseRecordCount -CurNumRecords $CurRecordCount -LogFullPath $LogFullPath -Verbose:$isVerbose;
    
                $OdataURL = $DtaObjFrmDS.URL;
                $CurRecordCount = $DtaObjFrmDS.RecordCount;
                [string]$CurErrorMessage = $DtaObjFrmDS.ErrorMessage;
                if ($DtaObjFrmDS.RetriesOccurred -eq $true) {
                    $RetriesOccurred = $true;
                }
    
                ## if we don't have any records let's break out of the loop; otherwise keep processing...
                if ($CurRecordCount -eq 0) {
                    Write-CmTraceLog -LogMessage "No Records returned; Moving to next URL/table..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    
                    ## Create the CurErrorMessage for logging purposes:
                    if ($CurErrorMessage) {
                        $CurErrorMessage = "No Records returned; Moving to next URL/table...`r`n$CurErrorMessage";
                    }
                    else {
                        [string]$CurErrorMessage = "No Records returned; Moving to next URL/table...";
                    }

                    $RecordsNotImported = 0;
                    $RecordsImported = 0;
                    
                    $SpecUrlGrpErrorMessage += $CurErrorMessage;
                    break; # break out of the while loop...
                }
    
                ## if we have ParentCols we need to add this information to the DataObject so that we can create the data in the DataTable:
                if ($ParentCols.Count -gt 0) {
                    foreach ($pc in $ParentCols.Keys) {
                        foreach ($itm in $DtaObjFrmDS.DataObject) {
                            $itm | Add-Member -MemberType NoteProperty -Name $pc -Value $ParentCols.$pc;
                        }
                        Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                    }
                    Remove-Variable -Name pc -ErrorAction SilentlyContinue;
                }
                Remove-Variable -Name ParentCols -ErrorAction SilentlyContinue;
                
                # Convert the data we got from the service to a DataTable so that we can import it into SQL:
                Write-CmTraceLog -LogMessage "Converting the data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                $DtaTbl = ConvertTo-DataTable -InputObject $DtaObjFrmDS.DataObject -ColumnDef $SqlDefinition;
                Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                #### Do a check on the datatable???
                
                ## Only try to Truncate the table if it is the first or only batch of data:
                if ($TruncateSqlTable) {
                    Write-CmTraceLog -LogMessage "Truncating the table '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $SqlTableName;
                    ## Check to make sure we were able to truncate the table:
                    if ($SqlTruncTblObj.Value -eq 0) {
                        Write-CmTraceLog -LogMessage "Table Truncated" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        if ($SqlTruncTblObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                        $TruncateSqlTable = $false;
                    }
                    else { # Failure to Truncate:
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
                        $SpecUrlGrpErrorMessage += $CurErrorMessage;
                        break; # break out of the while loop
                    }
                    Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                }
                else {
                    Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
    
                #region Write DataTable to SQL
                ## Write the data to SQL:
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
                    $RecordsImported = $CurRecordCount;
                    Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $($DtaTbl.Rows.Count)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    if ($SqlImportRetObj.RetryOccurred) {
                        Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        $ImportRetriesOccurred = $true;
                    }
                    # Cleanup for the next item in the while loop:
                    Remove-Variable -Name SqlImportRetObj,DtaTbl,DtaObjFrmDS -ErrorAction SilentlyContinue;
                }
                else {
                    Write-CmTraceLog -LogMessage "Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    if ($SqlImportRetObj.RetryOccurred) {
                        Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        $ImportRetriesOccurred = $true;
                        [string]$ErrorMsgRetryPortion = "However, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). ";
                    }
                    else {
                        [string]$ErrorMsgRetryPortion = "";
                    }
                    
                    # Make sure to subtract the records that didn't get imported from the total records so we log the count accurately:
                    $RecordsNotImported = $($DtaTbl.Rows.Count);
                    $RecordsImported = $CurRecordCount - $RecordsNotImported;
                    $ImportError = $true;
    
                    ## Create the CurErrorMessage for logging purposes:
                    if ($CurErrorMessage) {
                        $CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n$CurErrorMessage";
                    }
                    else {
                        [string]$CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)";
                    }
                    $SpecUrlGrpErrorMessage += $CurErrorMessage;
                    ## Cleanup:
                    Remove-Variable -Name SqlImportRetObj,DtaTbl,ErrorMsgRetryPortion,DtaObjFrmDS -ErrorAction SilentlyContinue;
                    break; # break out of the while loop
                }
                #endregion Write DataTable to SQL
    
                ## If there was an error caught we're going to display that and move to the next item in the loop:
                if ($CurErrorMessage) {
                    break; # stop processing the While OdataURL loop
                }
    
            } #End While loop for Specific URLs
            #endregion SpecificURL: Get/Write Data along with all other logic
            Remove-Variable -Name OdataURL,ParentCols,CurRecordCount -ErrorAction SilentlyContinue;
                    
            ## Log the completion of the Specific URL:
            if ($SqlLogByTblId) {
                # Build the xml insert string with all the information we want to store for the URI:
                [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{EndDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));RecordsImported = $RecordsImported;RecordsNotImported = $RecordsNotImported;ImportErrorOccurred = $ImportError;ImportRetriesOccurred = $ImportRetriesOccurred;RetriesOccurred = $RetriesOccurred;ErrorDetails = $CurErrorMessage});
                [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -AttrName "UriPart" -AttrValue $($SpecUrl.UriPart) -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                # Try to update the xml for the current URI:
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                ##Check results:
                if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Successfully logged the completion of the SpecificURL refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# failure
                    Write-CmTraceLog -LogMessage "Logging the completion of the Specific URL to SQL failed! The script will continue but the information won't be properly logged" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                }
                Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
            } # end logging completion of Specific URL
            
            Remove-Variable -Name SpecUrlVersion,CurRecordCount,RetriesOccurred,RecordsImported,RecordsNotImported,CurErrorMessage,ImportError,ImportRetriesOccurred -ErrorAction SilentlyContinue;
    
        } # End foreach specific url in specific url group
    
        ## Log the completion of the Specific Url Group/TargetTable:
        if ($SqlLogByTblId) {
            ## Create the update statement to run:
            $PropValues =
                @{
                  EndDateUTC = "SYSUTCDATETIME()"
                  ErrorNumber = if ($SpecUrlGrpErrorMessage -ne "") {-1;} else {$null;}
                  ErrorMessage = if ($SpecUrlGrpErrorMessage -ne "") {$SpecUrlGrpErrorMessage;} else {$null;}
                }
            [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
            ## Run the update statement:
            $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
            ##Check results:
            if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                Write-CmTraceLog -LogMessage "Successfully logged the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            else {# failure
                Write-CmTraceLog -LogMessage "There was an error trying to log the completion of the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            }
            Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
        } # End: logging the refresh of the Specific URL Group/TargetTable
    
        ## Cleanup:
        Remove-Variable -Name SpecUrl,IsFirstSpecUrl,TruncateSqlTable,SqlLogByTblId,SqlTableName,SqlDefinition,UriVersion,SpecUrlGrpErrorMessage -ErrorAction SilentlyContinue;
    
    } # End foreach specific url group
    Remove-Variable -Name SpecUrlGrp -ErrorAction SilentlyContinue;

    Write-CmTraceLog -LogMessage "Finished processing the 'Specific Urls' in the 'TablesToSync' Object" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
} # End: Process Specific URLs

Remove-Variable -Name ProcessSpecificURLs -ErrorAction SilentlyContinue;


####### Process the Drill Down Items #########
if ($ProcessDrillDownURLs) {
## Note: 
 #"Expand Columns":
 # - We can only have an expand as part of the URL since I will not be handling this in the property/table
 # - If a drilldown url has an "expand" then we will only expand it to the target table as a column and not create a separate table for the expanded column
 # - If a drilldown url has an "expand" but the target table doesn't have a column for that expand column then the data is retrieved but ignored when writing it to sql

    Write-CmTraceLog -LogMessage "Processing the 'DrillDown Urls' in the 'TablesToSync' Object" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
    foreach ($DrillDown in $TablesToSync) {
        if ($DrillDown.UriPartType -eq 'DrillDownData') {
            ## Determine what distinct Ids we need to get from SQL to create the 'foreach' object we'll use:
            [string]$RplcmntIds = "";
            $ParentCols = New-Object -TypeName System.Collections.Hashtable;
    
            ##############foreach ($i in ($DrillDown.UriPart -split '/')) {
            ##############    if ($i.ToString().StartsWith('{')) {
            ##############        $RplcmntIds += ",$($i.Replace('{','[').Replace('}',']'))";
            ##############        $ParentCols.Add("Parent$($i.Replace('{','').Replace('}',''))","");
            ##############    }
            ##############}
            ##############Remove-Variable -Name i -ErrorAction SilentlyContinue;
            foreach ($i in ($DrillDown.UriPart -split '/'))
            {
                if ($i.IndexOf('{') -ne -1)
                {
                    [int]$q = $i.Length - $i.Replace('{','').Length;
                    [int]$r = 0;
                    for ($j = 1; $j -le $q; $j++)
                    {
                        $r = $i.IndexOf('{',$r);
                        $s = $i.IndexOf('}',$r)+1;
                        $RplcmntIds += ",$($i.Substring($r,$s-$r).Replace('{','[').Replace('}',']'))";
                        $ParentCols.Add("Parent$($i.Substring($r,$s-$r).Replace('{','').Replace('}',''))","");            
                        $r = $s;
                    }
                    Remove-Variable -Name q,r,s,j -ErrorAction SilentlyContinue;
                }
            }
            Remove-Variable -Name i -ErrorAction SilentlyContinue;
    
            ## Now that we know the 'replacement ids' we'll create a unique variable name:
            [string]$ReplacementVarName = "RplcmntIdsVar_$($RplcmntIds.Substring(1).Replace(',','_').Replace('[','').Replace(']',''))__$($DrillDown.ReplacementTable)";
    
            ## Get the Url we're supposed to use and do some minor cleanup if necessary:
            $Url = $DrillDown.UriPart;
            
            ## Check the UriPart to see if it contains elements which we need to strip off and/or handle differently:
            if ($Url.IndexOf('graph.microsoft.com/') -ne -1) {
                $UriStartInd = $Url.IndexOf('graph.microsoft.com/')+20;
                $UriVersion = $Url.Substring($UriStartInd,$Url.IndexOf('/',$UriStartInd)-$UriStartInd);
                $UriPart = $Url.Substring($UriStartInd+$UriVersion.Length+1);
            }
            else {
                $UriVersion = $DrillDown.Version;
                $UriPart = $Url;
            }
            Remove-Variable -Name UriStartInd,Url -ErrorAction SilentlyContinue;
            
            ## Now we'll check the UriPart for query parameters:
            if ($UriPart.IndexOf('?') -ne -1) {
                $QryParamPart = $UriPart.Substring($UriPart.IndexOf('?'),($UriPart.Length - $UriPart.IndexOf('?')));
                $UriPart = $UriPart.Substring(0,$UriPart.IndexOf('?'));
            
                foreach ($QryParam in ($QryParamPart.Replace('?','').Replace(' ','').Replace('$','') -split '&')) {
                    #
                    Switch ($QryParam.Substring(0,$QryParam.IndexOf('='))) {
                            "expand"  {
                                $UriExpandCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                                break;
                            }
                            "select" {# we currently do nothing with this variable/info...
                                $UriSelectCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                                break;
                            }
                    }
                    
                    if ($UriExpandCols) {
                        if ($UriExpandCols.IndexOf('(') -ne -1) {
                            #throw "I'm not going to deal with this type of url just yet...perhaps in a later iteration but not now." Example: $expand=categories(select=blah,blah2,blah3),assignments
                            # maybe for now let's just remove all the select crap and keep just the expand portion:
                            foreach ($Parentheses in $UriExpandCols.Split(')')) {
                                if ($Parentheses) {
                                    [string]$ExpandParam += $Parentheses.Substring(0,$Parentheses.IndexOf('('));
                                }
                            }
                            Remove-Variable -Name Parentheses -ErrorAction SilentlyContinue;
                        }
                        else {
                            [string]$ExpandParam = $UriExpandCols;
                        }
                    }
                } # End foreach $QryParam in $QryParamPart
                Remove-Variable -Name QryParam -ErrorAction SilentlyContinue;
            } # End checking for ? in the UriPart
            Remove-Variable -Name QryParamPart,UriExpandCols,UriSelectCols -ErrorAction SilentlyContinue;
            
            ## Now that we have the UriPart we can figure out the rest of the variables we need
            [System.Collections.ArrayList]$UriParts = $UriPart -split "/";
            
            ## Let's remove any blank items in the array:
            for ($i = $UriParts.Count-1; $i -ge 0; $i--) {
                if ([String]::IsNullOrEmpty($UriParts[$i])) {
                    $UriParts.RemoveAt($i);
                }
                elseif ($UriParts[$i] -notlike '{*') {
                    [int]$ArrCnt += 1;
                }
            }
            Remove-Variable -Name i -ErrorAction SilentlyContinue;
            
            ## Reverse the order of the array:
            $UriParts.Reverse();
            
            ## Determine the SQL Table name to use to store the data:
            if (-Not [String]::IsNullOrWhiteSpace($DrillDown.TargetTable)) {
                [string]$SqlTableName = $DrillDown.TargetTable;
            }
            else {
                ## if the table name wasn't provided we'll create it using the format "class_drilldownclass" or "class" in rare cases.
                 ## For example: the drill down uri "deviceManagement/deviceCompliancePolicies/{id}/userStatusOverview" will have a table of "deviceCompliancePolicies_userStatusOverview".
                 ## For example: the drill down uri "deviceManagement/windowsAutopilotDeviceIdentities/{id}/?$expand=deploymentProfile" will have a table of "windowsAutopilotDeviceIdentities".
                if ($ArrCnt -eq 2) {
                    [string]$SqlTableName = $UriParts[1];
                }
                else {
                    $NewParts = New-Object -TypeName System.Collections.ArrayList;
                    foreach ($Part in $UriParts) {
                        if ($Part -notlike '{*' -and $Part -notlike '`?*') {
                            [void]$NewParts.Add($Part);
                            if ($NewParts.Count -eq 2) {
                                [string]$SqlTableName = "$($NewParts[1])_$($NewParts[0])";
                                Remove-Variable -Name Part,NewParts -ErrorAction SilentlyContinue;
                                break;
                            }
                        }
                    }
                }
            } # End determining the SQL Table name to use
            Remove-Variable -Name ArrCnt -ErrorAction SilentlyContinue;

            Write-CmTraceLog -LogMessage "Working with DrillDown URL: '$($UriPart)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            
            
            ## Log to SQL Table - start of table
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
    
    
            ## Determine the EntityName to use from Graph:
            if (-Not $DrillDown.SkipGraphMetaDataCheck -eq "TRUE")
            {
                for ($i = 0; $i -lt $UriParts.Count; $i++) {
                    if ($UriParts[$i] -notlike '{*') {
                        $GraphName = $UriParts[$i];
                        break;
                    }
                }
                Remove-Variable -Name i -ErrorAction SilentlyContinue;
                foreach ($NavPrp in (Get-CollectionEntity -UrlPartsReversed $UriParts -Version $UriVersion).NavigationProperty) {
                    if ($NavPrp.Name -eq $GraphName) {
                        [string]$GraphMetaDataEntityName = $NavPrp.Type.Replace("Collection(","").Replace(")","");
                        break; # stop the foreach as soon as we find it...
                    }
                }
            }
            Remove-Variable -Name NavPrp,UriParts,GraphName -ErrorAction SilentlyContinue;
    
            # ? - Do a check on ExpandCols to make sure they all exist? If not there will be an error in the Get call...which would be handled anyway but...
    
            ## Get Sql Table Definition:  ## Should we explicitly cast this as "[System.Collections.ArrayList]"??
            $SqlDefinition = Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $SqlTableName;
    
            ## Make sure we have a table to work with; if not alert and go to the next drill down url:
            if (-not $SqlDefinition) {
                # should we automatically create the table and try again?
                Write-CmTraceLog -LogMessage "'$SqlTableName' DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "You can run the following to create the table(s):`r`n$(Get-SqlTableCreateStatementsFromUrl -UriPart $UriPart -UriVersion $UriVersion -SqlTableName $SqlTableName <#-UriExpandCols $ExpandParam#>)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Skipping DrillDown Url '$UriPart'..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;

                ## Log the 'skip' to Sql:
                if ($SqlLogByTblId) {
                    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -9;ErrorMessage = 'TABLE DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!'} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                    ##Check results?:
                    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "Successfully logged the skipping of the DrillDown URL to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# failure
                        Write-CmTraceLog -LogMessage "Failed to log the skipping of the DrillDown URL to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                }

                Remove-Variable -Name ParentCols,RplcmntIds,ReplacementVarName,UriVersion,UriPart,ExpandParam,SqlTableName,SqlLogByTblId -ErrorAction SilentlyContinue;

                continue; # go to the next Url...
            }
            Remove-Variable -Name UriPart -ErrorAction SilentlyContinue;

            #region GraphMetaData & SqlMetaData Comparison
            ######################################################################## COMPARISON SECTION ########################################################################
            ## Get MetaData Column Definition for Comparisons:
            $EntityColDef = New-Object -TypeName System.Collections.ArrayList;
            ## Create the Parent Columns:
            foreach ($pc in $ParentCols.Keys) {
                $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = "$pc";"Name" = "$pc";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
                [void]$EntityColDef.Add($CCO);
                Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name pc -ErrorAction SilentlyContinue;
    
            #region DrillDown: Graph MetaData Check
            ## Get Graph Property/Column definition:
            if ($DrillDown.SkipGraphMetaDataCheck -eq "TRUE")
            {
                Write-CmTraceLog -LogMessage "Skipping the MetaData Check for '$($DrillDown.UriPart)'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            else
            {
                if ($ExpandParam) {
                    $tmpColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion -ExpandedColumns $ExpandParam;
                    Remove-Variable -Name ExpandParam -ErrorAction SilentlyContinue;
                }
                else {
                    $tmpColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $GraphMetaDataEntityName -Version $UriVersion;
                }
                Remove-Variable -Name GraphMetaDataEntityName -ErrorAction SilentlyContinue;
    
                ## Alert if we don't have any metadata info and skip to the next item...:
                if (-not $tmpColDef) {
                    Write-CmTraceLog -LogMessage "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! If this is a valid call then consider using the 'SkipGraphMetaDataCheck' flag for this URI." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Skipping DrillDown Url '$($DrillDown.UriPart)'..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    
                    ## Log the 'skip' to Sql:
                    if ($SqlLogByTblId) {
                        [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -8;ErrorMessage = "COULD NOT FIND METADATA FOR '$GraphMetaDataEntityName'! If this is a valid call then consider using the 'SkipGraphMetaDataCheck' flag for this URI."} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                        $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                        ##Check results?:
                        if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                            Write-CmTraceLog -LogMessage "Successfully logged the skipping of the DrillDown Url to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                        else {# failure
                            Write-CmTraceLog -LogMessage "Failed to log the skipping of the DrillDown Url to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        }
                        Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                    }
                    
                    Remove-Variable -Name ParentCols,RplcmntIds,ReplacementVarName,UriVersion,SqlTableName,SqlLogByTblId,SqlDefinition,EntityColDef,tmpColDef -ErrorAction SilentlyContinue;
                
                    continue; # go to the next url...
                }
    
                ## Now add all the Graph properties/columns from the temp object to the final object:
                foreach ($c in $tmpColDef) {
                    $CCO = New-Object -TypeName PSCustomObject -Property @{"DataName" = $c.DataName;"Name" = $c.Name;"Type" = $c.Type;"Nullable" = $c.Nullable;"IsCollection" = $c.IsCollection};
                    [void]$EntityColDef.Add($CCO);
                    Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
                }
                Remove-Variable -Name c,tmpColDef -ErrorAction SilentlyContinue;
            }
            #endregion DrillDown: Graph MetaData Check
    
            ## Compare the SQL and Graph properties to create a new SqlDefinition (containing the DataName and IsCollection properties found in the Graph properties) and alert on any property differences (removed/added).
            $SqlDefinition = Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition $EntityColDef -SqlColumnDefinition $SqlDefinition -LogFullPath $LogFullPath -Verbose:$isVerbose;
    
            Remove-Variable -Name EntityColDef -ErrorAction SilentlyContinue;
            ######################################################################## END COMPARISON SECTION ####################################################################
            #endregion GraphMetaData & SqlMetaData Comparison

            #region DrillDown: Create/Get ReplacementIds Variable for looping
            ## If there isn't already a variable created for this DrillDown Url (with all the 'replacement ids') then create it now:
            if (-not (Get-Variable -Name $ReplacementVarName -ErrorAction SilentlyContinue)) {
                ## Create and Run the Select statement to get the data from SQL:
                [string]$SqlSelectCmd = "SELECT DISTINCT $($RplcmntIds.Substring(1)) FROM $SqlSchemaName.$($DrillDown.ReplacementTable);";
                $SqlDataObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlSelectCmd -ReturnTableData;
                ##Check results:
                if ($SqlDataObj.Value -eq 0) {#successful
                    Write-CmTraceLog -LogMessage "Creating variable '$ReplacementVarName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    New-Variable -Name $ReplacementVarName -Value $SqlDataObj.SqlTableData;
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
    
                    Remove-Variable -Name ParentCols,RplcmntIds,ReplacementVarName,UriVersion,SqlTableName,SqlLogByTblId,SqlDefinition,SqlDataObj,SqlSelectCmd -ErrorAction SilentlyContinue;
                    
                    continue; # need to stop processing this DrillDown URL...
                }
            } # End creating the "Replacement Ids" variable (the object with all the replacements in it for looping)
            Remove-Variable -Name RplcmntIds -ErrorAction SilentlyContinue;
    
            ## Get the 'Replacement Ids' object into a current variable:
            $CurReplacementObj = Get-Variable -Name $ReplacementVarName -ValueOnly;
            #endregion DrillDown: Create/Get ReplacementIds Variable for looping

            #################################################### THIS IS WHERE WE PROCESS EACH URL IN THE DISTINCT COLUMNS RETURNED ############################################

            ## Set some variables to use for the DrillDown URL Group/Table:
            $IsFirstUrl = $true;
            $TruncateSqlTable = if ($NoTruncate) {$false;} else {$true;};
            [string]$DrillDownGrpErrorMessage = "";

            foreach ($DrillUrl in $CurReplacementObj) {
                <# # For testing purposes:
                $DrillUrl = $CurReplacementObj[1];
                #>
                $CurUriPart = $DrillDown.UriPart;
                foreach ($kvp in $DrillUrl.GetEnumerator()) {
                    ## Update the Uri with the values:
                    $CurUriPart = $CurUriPart.Replace("{$($kvp.Name)}","$($kvp.Value.Replace('#',''))");
                    ## Update the Parent Column(s)' Values:
                    $ParentCols["Parent$($kvp.Name)"] = $kvp.Value;
                }
                Remove-Variable -Name kvp -ErrorAction SilentlyContinue;
                Write-CmTraceLog -LogMessage "Working with UriPart '$CurUriPart'; getting the information for this URI..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                ## Log the "DrillDown URL" information as XML elements for more granular logging...
                if ($SqlLogByTblId) {
                    if ($IsFirstUrl) {
                        [string]$SqlXmlLogTxt = Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $CurUriPart;UriVersion = $UriVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                        [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -IsFirstXml -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                        $IsFirstUrl = $false;
                    }
                    else {
                        [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{UriPart = $CurUriPart;UriVersion = $UriVersion};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                        [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    }
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "Successfully logged the start of the Specific DrillDown URL refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# failure
                        Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the Specific DrillDown URL refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
                }
    
                ## Create the Uri to call:
                $OdataURL = "$BaseURL$($UriVersion)/$CurUriPart";
    
                ## Set some variables in preparation for the while loop:
                $CurRecordCount = 0;
                $RetriesOccurred = $false;
    
                ## If we get data in batches this while loop will handle that:
                while ($OdataURL) {
                    ## Get the data from Graph:
                    Write-CmTraceLog -LogMessage "Getting data for '$CurUriPart' from Graph..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    $DtaObjFrmDS = Get-IntuneOpStoreData -OdataUrl $OdataURL -WriteBatchSize $WriteBatchSize -GetAuthStringCmd $GetAuthStringCmd -VerboseRecordCount $VerboseRecordCount -CurNumRecords $CurRecordCount -LogFullPath $LogFullPath -Verbose:$isVerbose;
                
                    $OdataURL = $DtaObjFrmDS.URL;
                    $CurRecordCount = $DtaObjFrmDS.RecordCount;
                    [string]$CurErrorMessage = $DtaObjFrmDS.ErrorMessage;
                    if ($DtaObjFrmDS.RetriesOccurred -eq $true) {
                        $RetriesOccurred = $true;
                    }
    
                    ## if we don't have any records let's break out of the loop; otherwise keep processing...
                    if ($CurRecordCount -eq 0) {
                        Write-CmTraceLog -LogMessage "No Records returned; Moving to next URL/table..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        
                        ## Create the CurErrorMessage for logging purposes:
                        if ($CurErrorMessage) {
                            $CurErrorMessage = "No Records returned; Moving to next URL/table...`r`n$CurErrorMessage";
                        }
                        else {
                            [string]$CurErrorMessage = "No Records returned; Moving to next URL/table...";
                        }

                        $RecordsNotImported = 0;
                        $RecordsImported = 0;
                        
                        $DrillDownGrpErrorMessage += $CurErrorMessage;
                        break; # break out of the while loop...
                    }

                    ### Add the Parent Column(s) values to each item in the DataObject so that we can create the data in the DataTable:
                    foreach ($pc in $ParentCols.Keys) {
                        foreach ($itm in $DtaObjFrmDS.DataObject) {
                            $itm | Add-Member -MemberType NoteProperty -Name $pc -Value $ParentCols.$pc;
                        }
                        Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                    }
                    Remove-Variable -Name pc -ErrorAction SilentlyContinue;
    
                    # Convert the data we got from the service to a DataTable so that we can import it into SQL:
                    Write-CmTraceLog -LogMessage "Converting the data to a DataTable for SQL importing..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    $DtaTbl = ConvertTo-DataTable -InputObject $DtaObjFrmDS.DataObject -ColumnDef $SqlDefinition;
                    Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                
                    #### Do a check on the datatable???
    
                    #region DrillDown: Table Truncate Logic
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
                            Remove-Variable -Name DtaObjFrmDS,DtaTbl,SqlTruncTblObj -ErrorAction SilentlyContinue;
                            break; # break out of the while loop
                        }
                        Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                    }
                    else {
                        Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    #endregion DrillDown: Table Truncate Logic
    
                    #region Write DataTable to SQL
                    ## Write the data to SQL:
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
                        $RecordsImported = $CurRecordCount;
                        Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $($DtaTbl.Rows.Count)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        if ($SqlImportRetObj.RetryOccurred) {
                            Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            $ImportRetriesOccurred = $true;
                        }
                        ## Cleanup for the next item in the while loop:
                        Remove-Variable -Name DtaTbl,SqlImportRetObj,DtaObjFrmDS -ErrorAction SilentlyContinue;
    
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
                        $RecordsImported = $CurRecordCount - $RecordsNotImported;
                        $ImportError = $true;
                
                        ## Create the CurErrorMessage for logging purposes:
                        if ($CurErrorMessage) {
                            $CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)`r`n$CurErrorMessage";
                        }
                        else {
                            [string]$CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)";
                        }
                        $DrillDownGrpErrorMessage += $CurErrorMessage;
                        Remove-Variable -Name DtaObjFrmDS,DtaTbl,SqlImportRetObj,ErrorMsgRetryPortion -ErrorAction SilentlyContinue;
                        break; # break out of the while loop
                    }
    
                    ## If there was an error caught we're going to move to the next item in the loop:
                    if ($CurErrorMessage) {
                        break; # stop processing the While OdataURL loop
                    }
                            
                } #End While loop for Specific DrillDown URLs
                Remove-Variable -Name OdataURL,CurRecordCount -ErrorAction SilentlyContinue;
                        
                ## Log the completion of the Specific DrillDown URL:
                if ($SqlLogByTblId) {
                    # Build the xml insert string with all the information we want to store for the URI:
                    [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{EndDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));RecordsImported = $RecordsImported;RecordsNotImported = $RecordsNotImported;ImportErrorOccurred = $ImportError;ImportRetriesOccurred = $ImportRetriesOccurred;RetriesOccurred = $RetriesOccurred;ErrorDetails = $CurErrorMessage});
                    [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -AttrName "UriPart" -AttrValue $CurUriPart -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    # Try to update the xml for the current URI:
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) {#successful
                        Write-CmTraceLog -LogMessage "Successfully logged the completion of the Specific DrillDown URL refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else {# failure to log
                        Write-CmTraceLog -LogMessage "Logging the completion of the Specific DrillDown URL to SQL failed! The script will continue but the information won't be properly logged" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
                }
                Remove-Variable -Name CurUriPart,RetriesOccurred,CurErrorMessage,RecordsImported,RecordsNotImported,ImportError,ImportRetriesOccurred -ErrorAction SilentlyContinue;
    
            } # End Foreach DrillUrl
    
            ## Log the completion of the DrillDown Url Group/TargetTable:
            if ($SqlLogByTblId) {
                ## Create and Run the update statement:
                $PropValues =
                    @{
                      EndDateUTC = "SYSUTCDATETIME()"
                      ErrorNumber = if ($DrillDownGrpErrorMessage -ne "") {-1;} else {$null;}
                      ErrorMessage = if ($DrillDownGrpErrorMessage -ne "") {$DrillDownGrpErrorMessage;} else {$null;}
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
                Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
            } # End: logging the refresh of the DrillDown URL Group/TargetTable
    
            ## Cleanup:
            Remove-Variable -Name DrillUrl,ParentCols,ReplacementVarName,UriVersion,SqlTableName,SqlLogByTblId,SqlDefinition,CurReplacementObj,IsFirstUrl,TruncateSqlTable,DrillDownGrpErrorMessage -ErrorAction SilentlyContinue;
        
        } # End if it's a DrillDown url type
    } # End foreach DrillDown url group
    Remove-Variable -Name DrillDown -ErrorAction SilentlyContinue;
    ## cleanup dynamically created variables:
    foreach ($var in (Get-Variable -Name 'RplcmntIdsVar_*').Name) {
        Remove-Variable -Name $var -ErrorAction SilentlyContinue;
    }
} # End: Process DrillDown URLs

Remove-Variable -Name ProcessDrillDownURLs -ErrorAction SilentlyContinue;


#region Process ReportExports
if ($ProcessReportExports)
{
    Write-CmTraceLog -LogMessage "Processing the 'Report Exports' in the 'TablesToSync' Object" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    foreach ($ReportExport in $TablesToSync)
    {
        #region If UriPartType is 'ReportExport'
        if ($ReportExport.UriPartType -eq 'ReportExport')
        {
            ## Get current report items for proper processing:
            [string]$ReportName = $ReportExport.ReportName;
            [string]$UriPart = "deviceManagement/reports/exportJobs"; #maybe we just hardcode this and not include it in the hashtable? $ReportExport.UriPart;
            [string]$UriVersion = $ReportExport.Version;
            [string]$BodySelect = $ReportExport.SelectColumns;
            [string]$BodyFilter = $ReportExport.ReportFilter;
            [string]$ReplacementTable = $ReportExport.ReplacementTable;
    
            ## Determine the SQL Table name to use to store the data:
            if (-Not [String]::IsNullOrWhiteSpace($ReportExport.TargetTable))
            {
                [string]$SqlTableName = $ReportExport.TargetTable;
            }
            else
            {
                [string]$SqlTableName = $ReportName;
            }
    
            ## Create the URL to use for the POST:
            $URL = "$BaseURL$($UriVersion)/$UriPart";
    
            #region Log to SQL Table - start of table
            # Build and Run the insert command:
            [string]$SqlLogCmd = Set-LogToSqlCommand -TableToLog $SqlTableName -BatchId $SqlLogTblId -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
            $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
            ## Check results:
            if ($SqlLogByTblIdObj.Value -eq 0) #successful
            {
                $SqlLogByTblId = $SqlLogByTblIdObj.SqlColVal;
                Write-CmTraceLog -LogMessage "Successfully logged the start of the refresh of table '$SqlTableName' to SQL table; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
            }
            else # failure to log
            {
                Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
            }
            Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
            #endregion Log to SQL Table - start of table
    
            #region Get Sql Table Def and Check
            ## Get Sql Table Definition:
            $SqlTableDefinition = Get-SqlTableColumnDefinition @SqlConnSplat -SqlSchemaName $SqlSchemaName -SqlTableName $SqlTableName;
             
            ## Make sure we have a table to work with; if not alert and go to the next entity:
            if (-Not $SqlTableDefinition)
            {
                Write-CmTraceLog -LogMessage "'$SqlTableName' DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                Write-CmTraceLog -LogMessage "Skipping '$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                
                ## Log the 'skip' to Sql:
                if ($SqlLogByTblId)
                {
                    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -9;ErrorMessage = 'TABLE DOES NOT EXIST! CREATE THE TABLE AND TRY AGAIN!'} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) #successful
                    {
                        Write-CmTraceLog -LogMessage "Successfully logged the skipping of the table to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else # failure to log skip
                    {
                        Write-CmTraceLog -LogMessage "Failed to log the skipping of the table to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                }
            
                # cleanup the variables we've created thus far:
                Remove-Variable -Name ReportName,UriPart,UriVersion,BodySelect,BodyFilter,ReplacementTable,SqlTableName,URL,SqlTableDefinition -ErrorAction SilentlyContinue;
                continue; # go to the next report export
            }
            #endregion Get Sql Table Def and Check
    
            #region Determine whether the current report has drill down filter items or is just a simple reoprt and create proper objects:
            if (-Not [String]::IsNullOrWhiteSpace($ReplacementTable))
            {
                ## Determine what distinct Ids we need to get from SQL to create the 'foreach' object we'll use:
                [string]$RplcmntIds = "";
                
                $tmpRegEx = '{[\s\S]*?}';
            
                foreach ($i in ([regex]::Matches($BodyFilter,$tmpRegEx,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture).Value))
                {
                    $RplcmntIds += ",$($i.Replace('{','[').Replace('}',']'))";
                }
                Remove-Variable -Name i,tmpRegEx -ErrorAction SilentlyContinue;
            
                ## Now that we know the 'replacement ids' we'll create a unique variable name:
                [string]$ReplacementVarName = "RplcmntIdsVar_$($RplcmntIds.Substring(1).Replace(',','_').Replace('[','').Replace(']',''))__$ReplacementTable";
            
                ## If there isn't already a variable created for this DrillDown Url (with all the 'replacement ids') then create it now:
                if (-Not (Get-Variable -Name $ReplacementVarName -ErrorAction SilentlyContinue))
                {
                    ## Create/Get the Select statement to get the data from SQL:
                    [string]$SqlSelectCmd = "SELECT DISTINCT $($RplcmntIds.Substring(1)) FROM $SqlSchemaName.$ReplacementTable;";
                    $SqlDataObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlSelectCmd -ReturnTableData;
                    ##Check results:
                    if ($SqlDataObj.Value -eq 0) #successful
                    {
                        Write-CmTraceLog -LogMessage "Creating variable '$ReplacementVarName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        New-Variable -Name $ReplacementVarName -Value $SqlDataObj.SqlTableData;
                        Remove-Variable -Name SqlDataObj,SqlSelectCmd -ErrorAction SilentlyContinue;
                    }
                    else # failure to get 'replacement ids'
                    {
                        Write-CmTraceLog -LogMessage "Failed to get data from SQL." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Select statement used: $SqlSelectCmd" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlDataObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        
                        ## Log the failure and 'skip' to Sql:
                        if ($SqlLogByTblId)
                        {
                            [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -5;ErrorMessage = "FAILED TO RETRIEVE DRILL DOWN IDs FROM SQL USING SELECT STATEMENT '$SqlSelectCmd'. Error Captured: $($SqlDataObj.ErrorCaptured)"} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                            $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                            ##Check results?:
                            if ($SqlLogByTblIdObj.Value -eq 0) #successful
                            {
                                Write-CmTraceLog -LogMessage "Successfully logged the skipping of the DrillDown Url to SQL" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            }
                            else # failure to log skip
                            {
                                Write-CmTraceLog -LogMessage "Failed to log the skipping of the DrillDown Url to SQL; the error was:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                            }
                            Remove-Variable -Name SqlDataObj,SqlSelectCmd,SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
                        } # end logging the skip to Sql
            
                        Remove-Variable -Name ReportName,UriPart,UriVersion,BodySelect,BodyFilter,ReplacementTable,SqlTableName,URL,SqlTableDefinition,RplcmntIds,ReplacementVarName -ErrorAction SilentlyContinue;
                        continue; # go to the next report export
                    }
                } # End creating the "Replacement Ids" variable (the object with all the replacements in it for looping)
                Remove-Variable -Name RplcmntIds -ErrorAction SilentlyContinue;
            
                ## Get the 'Replacement Ids' object into a current variable:
                $CurReplacementObj = Get-Variable -Name $ReplacementVarName -ValueOnly;
            } # End ReplacementTable is not null or empty
            else
            {
                ## Create an array with one dummy hashtable entry so we go through the same 'foreach' loop
                $CurReplacementObj = New-Object System.Collections.ArrayList;
                [void]$CurReplacementObj.Add(@{NoDrillDownReport = "";});
            }
            #endregion Determine whether the current report has drill down filter items or is just a simple reoprt and create proper objects
    
            ## Set some variables to use in the foreach drill coming up:
            $IsFirstReport = $true;
            $TruncateSqlTable = if ($NoTruncate) {$false;} else {$true;};
            [string]$RptDrillGroupErrorMessage = "";
            $CurRecordCount = 0;
    
            #region Process each drilldown if exists or just run once for the reports that aren't a drilldown type (aka report filter includes dynamic values from a view/table)
            foreach ($DrillReport in $CurReplacementObj)
            {
                $CurFilter = $BodyFilter;
                $CurReportName = $ReportName;
                
                ## if this is an actual drilldown type of report update the filter:
                if (-Not $DrillReport.ContainsKey("NoDrillDownReport")) # this is the key we created if the report is not a drill down type of report
                {
                    foreach ($kvp in $DrillReport.GetEnumerator())
                    {
                        ## Update the filter with the substitue values:
                        $CurFilter = $CurFilter.Replace("{$($kvp.Name)}","$($kvp.Value)");
                        $CurReportName += "-$($kvp.Value)";
                    }
                    Remove-Variable -Name kvp -ErrorAction SilentlyContinue;
                }
    
                #region Log the "DrillDown Report" information as XML elements for more granular logging...
                if ($SqlLogByTblId)
                {
                    ## Create and Run the insert command:
                    if ($IsFirstReport)
                    {
                        [string]$SqlXmlLogTxt = Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{ReportName = $CurReportName;UriVersion = $UriVersion;Select = $BodySelect;Filter = $CurFilter};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                        [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -IsFirstXml -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                        $IsFirstReport = $false;
                    }
                    else
                    {
                        [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{ReportName = $CurReportName;UriVersion = $UriVersion;Select = $BodySelect;Filter = $CurFilter};StartDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))});
                        [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    }
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) #successful
                    {
                        Write-CmTraceLog -LogMessage "Successfully logged the start of the Specific DrillDown Report refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else # failure
                    {
                        Write-CmTraceLog -LogMessage "Logging to SQL table failed! Will continue running script but the Specific DrillDown Report refresh will not be logged!" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
                }
                #endregion Log the "DrillDown Report" information as XML elements for more granular logging...
    
                # Variables to handle retries in the while loop:
                [int]$NoUrlRetry = 0;
                [int]$NoUrlRetryThreshold= 3;
                
                #region WHILE loop for handling the logging of errors at the end and provide structure for a future retry if necessary
                while (1 -eq 1)
                {
                    ## Issue the POST to the service to run the report and get a download url (to get actual data)
                    $StatusResponseObject = Get-ReportExportResponse -ExportUrl $URL -ReportName $ReportName -Select $BodySelect -Filter $CurFilter;
    
                    #region Successful report export
                    if (((-Not ($null -eq $StatusResponseObject.StatusResponse.status) -and ($StatusResponseObject.StatusResponse.status = 'completed')) -and (-Not [String]::IsNullOrWhiteSpace($StatusResponseObject.StatusResponse.url))))
                    {
                        ## Build the DataTable (download, unzip, and process the csv in memory):
                        $DtaTbl = ConvertTo-DataTable -ZipFileUrl $StatusResponseObject.StatusResponse.url -ColumnDef $SqlTableDefinition -Verbose;
                        Write-CmTraceLog -LogMessage "DataTable created: Columns = $($DtaTbl.Columns.Count); Rows = $($DtaTbl.Rows.Count)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
        
                        $CurRecordCount = $DtaTbl.Rows.Count;
            
                        ## Move to next item if no records returned:
                        if ($CurRecordCount -eq 0)
                        {
                            Write-CmTraceLog -LogMessage "No Records returned; Moving to next table..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
    
                            ## Create an error number/message which we'll use at the end of the while loop:
                            [string]$CurErrorNumber = "-3";
                            [string]$CurErrorMessage = "No Records captured from the csv. StatusResponseObject Json: $($StatusResponseObject | ConvertTo-Json -Compress)";
                            $RecordsNotImported = 0;
                            $RecordsImported = 0;
                            $RptDrillGroupErrorMessage += $CurErrorMessage;
    
                            break; # break out of the while loop...
                        }
            
                        #region Only try to Truncate the table if it is the first or only batch of data:
                        if ($TruncateSqlTable)
                        {
                            Write-CmTraceLog -LogMessage "Truncating the table '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            $SqlTruncTblObj = Invoke-SqlTruncate @SqlConnSplat -SchemaName $SqlSchemaName -TableName $SqlTableName;
                            ## Check to make sure we were able to truncate the table:
                            if ($SqlTruncTblObj.Value -eq 0)
                            {
                                Write-CmTraceLog -LogMessage "Table Truncated." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                if ($SqlTruncTblObj.RetryOccurred)
                                {
                                    Write-CmTraceLog -LogMessage " Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                }
                                $TruncateSqlTable = $false;
                                Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                            }
                            else # failure to truncate
                            {
                                Write-CmTraceLog -LogMessage "There was an error trying to truncate the table. We'll need to skip this URL/Table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlTruncTblObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                if ($SqlTruncTblObj.RetryOccurred)
                                {
                                    Write-CmTraceLog -LogMessage "Retries occurred while trying to truncate. Additional Info: NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                                }
                        
                                ## Make sure to subtract the records that didn't get imported from the total records so we log the count accurately:
                                $RecordsNotImported = $CurRecordCount;
                                $RecordsImported = 0;
                                
                                ## Create an error number/message which we'll use at the end of the while loop:
                                [string]$CurErrorNumber = "-7";
                                if ($SqlTruncTblObj.RetryOccurred)
                                {
                                    [string]$CurErrorMessage = "There was an error trying to truncate the table; however, we did retry the truncate (NumberOfRetries = $($SqlTruncTblObj.NumberOfRetries); RetryThreshold = $($SqlTruncTblObj.RetryThreshold)). Record Count NOT imported: $RecordsNotImported. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                                }
                                else
                                {
                                    [string]$CurErrorMessage = "There was an error trying to truncate the table. The error we caught is:`r`n$($SqlTruncTblObj.ErrorCaptured)";
                                }
                                $RptDrillGroupErrorMessage += $CurErrorMessage;
                                Remove-Variable -Name SqlTruncTblObj -ErrorAction SilentlyContinue;
                                break; # break out of the while loop
                            }
                        }
                        else {
                            Write-CmTraceLog -LogMessage "Writing data in batches...no need to truncate '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        }
                        #endregion Only try to Truncate the table if it is the first or only batch of data:
    
                        ## Create the Column Mapping to ensure the import succeeds:
                        [System.Collections.ArrayList]$ColMapCollArrayList = Get-ColumnMapping -DtaTblColumns $($DtaTbl.Columns.GetEnumerator().ColumnName) -ColumnDef $SqlTableDefinition;
                        
                        #region Write the data to SQL
                        ## Write the data to SQL:
                        ## Create the 'splat' object from combining the base SqlConnSplat and ImportSplatParams objects and adding our custom items needed to import:
                        $ImportSplat = $SqlConnSplat + $ImportSplatParams + @{SchemaName = $SqlSchemaName; TableName = $SqlTableName};
                        if ($DtaTbl.Rows.Count -ge 200000 -and $null -eq $BulkCopyBatchSize) {
                            $ImportSplat.Add("BulkCopyBatchSize", 200000);
                        }
                        elseif ($null -ne $BulkCopyBatchSize) {
                            $ImportSplat.Add("BulkCopyBatchSize", $BulkCopyBatchSize);
                        }
                        # this can't or shouldn't be empty...if it is the import probably won't work
                        if ($ColMapCollArrayList.Count -gt 0)
                        {
                            $ImportSplat.Add("ColumnMapping", $ColMapCollArrayList);
                        }
                        
                        Write-CmTraceLog -LogMessage "Starting an import of the DataTable for '$SqlSchemaName.$SqlTableName'..." -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                        $SqlImportRetObj = Import-SqlTableData @ImportSplat -ImportData $DtaTbl -LogFullPath $LogFullPath -Verbose:$isVerbose;
                        Remove-Variable -Name ImportSplat -ErrorAction SilentlyContinue;
            
                        ## Check if we were successful importing the data:
                        if ($SqlImportRetObj.Value -eq 0)
                        {
                            ## Make sure we have the RecordsImported for proper logging
                            $RecordsImported = $CurRecordCount;
                            Write-CmTraceLog -LogMessage "Finished importing data for '$SqlSchemaName.$SqlTableName'. Records Imported: $RecordsImported" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                            if ($SqlImportRetObj.RetryOccurred)
                            {
                                Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                $ImportRetriesOccurred = $true;
                            }
                            # Cleanup:
                            Remove-Variable -Name SqlImportRetObj,DtaTbl -ErrorAction SilentlyContinue;
                            
                            ## All is successful in the while loop so issue the break to move out and to the next steps
                            break;
                        }
                        else # failure to import
                        {
                            Write-CmTraceLog -LogMessage "Error Importing the records into SQL. Original Error is:`r`n$($SqlImportRetObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                            if ($SqlImportRetObj.RetryOccurred)
                            {
                                Write-CmTraceLog -LogMessage "Retries occurred while trying to write the data to SQL. Additional Info: NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                                $ImportRetriesOccurred = $true;
                                [string]$ErrorMsgRetryPortion = "However, we did retry writing the data (NumberOfTimeoutRetries = $($SqlImportRetObj.NumberOfTimeoutRetries); TimeoutRetryThreshold = $($SqlImportRetObj.TimeoutRetryThreshold); NumberOfTransportRetries = $($SqlImportRetObj.NumberOfTransportRetries); TransportRetryThreshold = $($SqlImportRetObj.TransportRetryThreshold)). ";
                            }
                            else
                            {
                                [string]$ErrorMsgRetryPortion = "";
                            }
                            
                            # Technically the bulkcopy could write some batches (if a batch is smaller than the total records) but not all of them, so the only way for this to be truly accurate is to do a rowcount on the table but I don't care enough:
                            $RecordsNotImported = $CurRecordCount;
                            $RecordsImported = 0;
                            $ImportError = $true;
                            
                            ## Create the CurErrorNumber/CurErrorMessage for logging purposes:
                            [string]$CurErrorNumber = "-6";
                            [string]$CurErrorMessage = "Error Importing the records into SQL. $($ErrorMsgRetryPortion)Record Count NOT imported: $RecordsNotImported.`r`nOriginal Error is:`r`n$($SqlImportRetObj.ErrorCaptured)";
                            $RptDrillGroupErrorMessage += $CurErrorMessage;
        
                            ## Cleanup:
                            Remove-Variable -Name SqlImportRetObj,DtaTbl,ErrorMsgRetryPortion -ErrorAction SilentlyContinue;
                            break; # break out of the while loop
                        }
                        #endregion Write the data to SQL
                    }
                    #endregion Successful report export
                    #region Successful report export but the URL is missing - retry 3 times
                    elseif ((-Not ($null -eq $StatusResponseObject.StatusResponse.status) -and ($StatusResponseObject.StatusResponse.status = 'completed')) -and [String]::IsNullOrWhiteSpace($StatusResponseObject.StatusResponse.url))
                    {
                        ### Retry in this scenario? Most likely won't hit this issue but if we do it's probably because the url expired:
                        ## iterate the retry counter since we'll retry on this scenario a few times:
                        $NoUrlRetry += 1;
                        if ($NoUrlRetry -le $NoUrlRetryThreshold)
                        {
                            # retry after 3 minutes
                            Write-Warning "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : No Report Download URL returned! Will try again in 3 minutes. Retry: $NoUrlRetry of $NoUrlRetryThreshold.";
                            Start-Sleep -Seconds 180;
                            continue; # this continues the while loop...goes to the start of the while loop
                        }
                        else
                        {
                            [string]$CurErrorNumber = "-2";
                            [string]$CurErrorMessage = "No Report Download URL returned for the last number of retries ($NoUrlRetryThreshold). StatusResponseObject Json: $($StatusResponseObject | ConvertTo-Json -Compress)";
                            $RptDrillGroupErrorMessage += $CurErrorMessage;
                            $RecordsImported = 0;
                            break; # this breaks out of the while loop
                        }
                    }
                    #endregion Successful report export but the URL is missing - retry 3 times
                    #region Report Export not successful
                    else
                    {
                        ## there was a failure; prepare to log it and move next
                        Write-CmTraceLog -LogMessage "Report Export for '$ReportName' did not complete successfully; It reported a status of '$($StatusResponseObject.StatusResponse.status)'. Moving to next table..." -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        
                        ## create specific error number/message for this scenario
                        [string]$CurErrorNumber = "-5";
                        [string]$CurErrorMessage = "Report Export did not complete successfully. StatusResponseObject Json: $($StatusResponseObject | ConvertTo-Json -Compress)";
                        $RptDrillGroupErrorMessage += $CurErrorMessage;
                        $RecordsImported = 0;
                        break; # break out of the while loop...
                    }
                    #endregion Report Export not successful
                } # End: while (1=1)
                #endregion WHILE loop for handling the logging of errors at the end and provide structure for a future retry if necessary
                
                #region Log the completion of the Specific DrillDown Report (ExtendedInfo):
                if ($SqlLogByTblId)
                {
                    # Build and Run the xml insert string with all the information we want to store for the Report:
                    [string]$SqlXmlLogTxt = Get-HashToXml -HashOrDictionary $([ordered]@{EndDateTimeUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));RecordsImported = $RecordsImported;RecordsNotImported = $RecordsNotImported;ImportErrorOccurred = $ImportError;ImportRetriesOccurred = $ImportRetriesOccurred;RetriesOccurred = $RetriesOccurred;ErrorDetails = $CurErrorMessage;StatusResponse = [ordered]@{LastClientRequestId = $StatusResponseObject.LastClientRequestId;Duration = $StatusResponseObject.Duration;id = $StatusResponseObject.StatusResponse.id;status = $StatusResponseObject.StatusResponse.status;requestDateTime = $StatusResponseObject.StatusResponse.requestDateTime;expirationDateTime = $StatusResponseObject.StatusResponse.expirationDateTime;ErrorCaught = $StatusResponseObject.ErrorCaught;ErrorMessage = $StatusResponseObject.ErrorMessage}});
                    [string]$SqlXmlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -AttrName "ReportName" -AttrValue $CurReportName -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt} -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                    $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlXmlLogCmd;
                    ##Check results:
                    if ($SqlLogByTblIdObj.Value -eq 0) #successful
                    {
                        Write-CmTraceLog -LogMessage "Successfully logged the completion of the Specific DrillDown Report refresh in xml for table '$SqlTableName' with ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                    }
                    else # failure to log
                    {
                        Write-CmTraceLog -LogMessage "Logging the completion of the Specific DrillDown Report to SQL failed! The script will continue but the information won't be properly logged" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                        Write-CmTraceLog -LogMessage "Error Captured:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    }
                    Remove-Variable -Name SqlLogByTblIdObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
                }
                #endregion Log the completion of the Specific DrillDown Report (ExtendedInfo)
                Remove-Variable -Name CurFilter,CurReportName,StatusResponseObject,DtaTbl,CurErrorMessage,RecordsNotImported,RecordsImported,ColMapCollArrayList,ImportSplat,SqlImportRetObj,ImportRetriesOccurred,ErrorMsgRetryPortion,ImportError -ErrorAction SilentlyContinue;
            
            } # End: foreach ($DrillReport in $CurReplacementObj)
            Remove-Variable -Name DrillReport,CurReplacementObj,IsFirstReport,TruncateSqlTable,CurRecordCount -ErrorAction SilentlyContinue;
            #endregion Process each drilldown if exists or just run once for the reports that aren't a drilldown type (aka report filter includes dynamic values from a view/table)
    
            #region Log the completion of the DrillDown Report Group/TargetTable:
            if ($SqlLogByTblId)
            {
                ## Create and Run the update statement:
                $PropValues =
                    @{
                      EndDateUTC = "SYSUTCDATETIME()"
                      ErrorNumber = if ($RptDrillGroupErrorMessage -ne "") {$CurErrorNumber;} else {$null;}
                      ErrorMessage = if ($RptDrillGroupErrorMessage -ne "") {$RptDrillGroupErrorMessage;} else {$null;}
                    }
                
                [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogByTblId -PropertyValues $PropValues -LogToTable "$SqlSchemaName.$SqlLoggingByTableName";
                $SqlLogByTblIdObj = Invoke-SqlCommand @SqlConnSplat -SqlCommandText $SqlLogCmd;
                ##Check results:
                if ($SqlLogByTblIdObj.Value -eq 0) #successful
                {
                    Write-CmTraceLog -LogMessage "Successfully logged the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
                }
                else {# failure to log
                    Write-CmTraceLog -LogMessage "There was an error trying to log the completion of the refresh for '$SqlSchemaName.$SqlTableName'; Log ID = $SqlLogByTblId" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                    Write-CmTraceLog -LogMessage "Error Returned from the Call:`r`n$($SqlLogByTblIdObj.ErrorCaptured)" -LogFullPath $LogFullPath -Component $scriptName -MessageType Error -Verbose:$isVerbose;
                }
                Remove-Variable -Name SqlLogByTblIdObj,SqlLogCmd -ErrorAction SilentlyContinue;
            } # End: logging the refresh of the DrillDown Report Group/TargetTable
            #endregion Log the completion of the DrillDown Report Group/TargetTable

        } # End: if ($ReportExport.UriPartType -eq 'ReportExport')
        #endregion If UriPartType is 'ReportExport'
    
    } # End: foreach ($ReportExport in $TablesToSync)
    Remove-Variable -Name ReportExport,ReportName,UriPart,UriVersion,BodySelect,BodyFilter,ReplacementTable,SqlTableName,URL,SqlTableDefinition,RplcmntIds,ReplacementVarName,CurReplacementObj,IsFirstReport,TruncateSqlTable,RptDrillGroupErrorMessage,CurRecordCount,CurFilter,CurReportName,StatusResponseObject,DtaTbl,CurErrorNumber,CurErrorMessage,RecordsNotImported,RecordsImported,ColMapCollArrayList,ImportSplat,SqlImportRetObj,ImportRetriesOccurred,ErrorMsgRetryPortion,ImportError,i,tmpRegEx,SqlDataObj,SqlSelectCmd,SqlLogByTblIdObj,SqlLogCmd,kvp,SqlTruncTblObj,SqlXmlLogTxt,SqlXmlLogCmd -ErrorAction SilentlyContinue;
    ## Cleanup dynamically created variables:
    foreach ($var in (Get-Variable -Name 'RplcmntIdsVar_*').Name)
    {
        Remove-Variable -Name $var -ErrorAction SilentlyContinue;
    }
    Write-CmTraceLog -LogMessage "Finished processing the 'Report Exports' in the 'TablesToSync' Object" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
} # End: Process ReportExport URLs
#endregion Process ReportExports

Remove-Variable -Name ProcessUrisWithoutPartType,ProcessSpecificURLs,ProcessDrillDownURLs,ProcessReportExports -ErrorAction SilentlyContinue;


## Log to SQL Table - completion of the script:
if ($SqlLogTblId) { # Currently this isn't logging any errors...
    ## Create and Run the update statement:
    [string]$SqlLogCmd = Set-LogToSqlCommand -LogTableRowId $SqlLogTblId -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()'} -LogToTable "$SqlSchemaName.$SqlLoggingTableName";
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
Remove-Variable -Name SqlLogTblObj,SqlLogCmd,SqlLogTblId -ErrorAction SilentlyContinue;


## Final Cleanup:
#Remove-Variable -Name BaseURL,SqlServerName,SqlDatabaseName,SqlSchemaName,SyncMgdDvcCertStatesData,SyncDeviceStatusesData,SynchardwareInformation,WriteBatchSize,VerboseRecordCount,SqlConnTimeout,ApplicationId,User,RedirectUri,SqlLoggingTableName,UseTestTables,TablesToSync,SecureSQLConnString,GetAuthStringCmd,Enums,Entities,Table,DrillDownInfo,SqlLogTblObj,SqlLogTblId,SpecificURLsGrouped,SpecificURLs,SqlKeyVaultName,SqlKeyVaultSecretName,SqlConnectionString,SqlCredentialsFile,SqlLoggingByTableName,SqlUser,tenantId,Versions,KeyVaultApplicationId,GraphUser,GraphKeyVaultSecretName,GraphKeyVaultName,GraphCreds,GraphCredentialsFile,DrillDowns,certThumbprint -ErrorAction SilentlyContinue;
#Remove-Variable -Scope Global -Name $((Get-Variable -Scope Global -Include "Entities_*","Enums_*","MetaData_*").Name) -ErrorAction SilentlyContinue;
#Clear-Authentication;

Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "******************************************   Script Finished   ****************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
