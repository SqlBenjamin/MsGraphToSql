<#
.SYNOPSIS
    This script creates the database and all objects for the MsGraphSyncToSql solution.
.DESCRIPTION
    This script runs all the SQL scripts that exist in the "DatabaseFiles" folder. The scripts will be run in order of the subfolders listed in the "Folders" parameter.
    This is a basic and crude installation method currently so use with care or knowing that errors aren't necessarily handled or accounted for. Make sure to use a log file
    and review the log to ensure everything ran as expected.
.PARAMETER SqlServerName
    The name of the SQL Server to connect to and on which to run the scripts.
.PARAMETER SqlDatabaseName
    The name of the Database to connect to. The default is "master" and should not ever need to be changed except in some very rare circumstances.
.PARAMETER NewScriptDb
    If the database to create or run the scripts on is not going to be "Intune" then this parameter should be used to define the name of the database to create/use.
    The USE statement in the scripts will use this value if it exists or will just use "Intune".
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
    If used (highly recommended) it is the full path name and must end with ".log".
.PARAMETER Folders
    The SQL scripts are grouped into folders of the same type (tables, views, etc), this parameter tells the script which folders to get scripts from and in what order they should be run.
     The default value: @('InstallScripts','Tables','Functions','Views','Procedures','Jobs')
      -This tells the script to run the scripts found in "InstallScripts" first, then run the scripts found in "Tables", then "Functions", and so on.
     If one wants to recreate all the views they can run this script passing only "Views" in this parameter and the script will only run the scripts found in "...\DatabaseFiles\Views"
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection.
.PARAMETER SqlCommandTimeout
    The SQL command timeout (in seconds) to use while running a command/query against SQL.
.PARAMETER ConfirmUpdates
    Using this switch will bypass the prompt that ensures all the files have been updated with the environment variables/values.
.EXAMPLE
    InstallDatabase.ps1 -SqlServerName MyServer -LogFullPath "D:\Test\InstallingMsGraphToSqlSolution.log" -Verbose;
    This will try to create a database named "Intune" on "MyServer", then create all tables, functions, views, and procedures in the "Intune" database, and finally create the SQL Agent jobs for the solution.
    Information will be written to the log file "D:\Test\InstallingMsGraphToSqlSolution.log" and to the host because of the "Verbose" flag.
.EXAMPLE
    InstallDatabase.ps1 -SqlServerName MyServer -NewScriptDb Intune_TEST -LogFullPath "D:\Test\InstallingMsGraphToSqlSolution.log" -Verbose;
    This will try to create a database named "Intune_TEST" on "MyServer", then create all tables, functions, views, and procedures in the "Intune_TEST" database, and finally create the SQL Agent jobs for the solution.
    Information will be written to the log file "D:\Test\InstallingMsGraphToSqlSolution.log" and to the host because of the "Verbose" flag.
.EXAMPLE
    InstallDatabase.ps1 -SqlServerName MyServer -NewScriptDb Intune_TEST -Folders @('Tables','Functions','Views','Procedures') -LogFullPath "D:\Test\InstallingMsGraphToSqlSolution.log" -Verbose;
    This will try to create a database named "Intune_TEST" on "MyServer", then create all tables, functions, views, and procedures in the "Intune_TEST" database.
    Information will be written to the log file "D:\Test\InstallingMsGraphToSqlSolution.log" and to the host because of the "Verbose" flag.
.EXAMPLE
    InstallDatabase.ps1 -SqlServerName MyServer -Folders @('Jobs') -LogFullPath "D:\Test\InstallingMsGraphToSqlSolution.log" -Verbose;
    This will create/recreate all the SQL Agent Jobs for this solution on "MyServer" using the database name "Intune" where needed.
    Information will be written to the log file "D:\Test\InstallingMsGraphToSqlSolution.log" and to the host because of the "Verbose" flag.
.NOTES
    There are a few functions within this script to ensure that even if this is run on a machine not having the "MsGraphToSql" PowerShell module it will work correctly.
    The functions "Write-CmTraceLog" and "Invoke-SqlScript" are very similar to those in the module but ensure this works correctly AND have some specific changes for this
    script.
.NOTES
    NAME: InstallDatabase.ps1
    HISTORY:
        Date          Version    Author                    Notes
        06/04/2021    0.0        Benjamin Reynolds         Initial Creation.
        09/01/2021    0.0        Benjamin Reynolds         Added functionality to popup to ask the user if they are truly ready to install (for sharing externally)

    NOTES:
        - 
#>
[cmdletbinding(PositionalBinding=$false)]
param (
    [Parameter(Mandatory=$true)][ValidateScript({-not [string]::IsNullOrEmpty($PSItem)})][Alias("SqlServer")][string]$SqlServerName
   ,[Parameter(Mandatory=$false)][Alias("DatabaseName","Database")][string]$SqlDatabaseName = 'master'
   ,[Parameter(Mandatory=$false)][AllowNull()][String]$NewScriptDb
   ,[Parameter(Mandatory=$false)][ValidateScript({(Test-Path -Path (Split-Path $PSItem)) -and ((Split-Path -Path $PSItem -Leaf).EndsWith(".log"))})][string]$LogFullPath
   ,[Parameter(Mandatory=$false)][System.Collections.ArrayList]$Folders = @('InstallScripts','Tables','Functions','Views','Procedures','Jobs')
   ,[Parameter(Mandatory=$false)][Alias("ConnectionTimeout","ConnTimeout")][int]$SqlConnTimeout = 240
   ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
   ,[Parameter(Mandatory=$false)][switch]$ConfirmUpdates
)

[bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;
[string]$scriptName = Split-Path $PSCmdlet.MyInvocation.MyCommand.Source -Leaf;

<###############################################################################################################################################################
            START FUNCTIONS
<###############################################################################################################################################################>
# Write-CmTraceLog
function Write-CmTraceLog {
<#
.SYNOPSIS
    This function writes information to a log file in cmtrace format.
.DESCRIPTION
    The function writes information to a log file in cmtrace format.
.PARAMETER LogMessage
    The message to be written to the log file.
.PARAMETER LogFullPath
    The name of the log file to write to - the full path. The path to the file must already exist, the file name doesn't have to exist but the file does need to end in ".log".
.PARAMETER MessageType
    One of "Informational","Warning","Error", or "None". Cmtrace will highlight lines appropriately.
.PARAMETER UtcTime
    If this switch is used then the log will write in UTC time rather than local.
.PARAMETER Component
    The component is required for proper highlighting - if one is not passed in a "default" one will be used.
.PARAMETER Thread
    The thread will be logged as well - if one is passed in that will be used otherwise the current "PID" will be.
.PARAMETER Source
    The source can be passed in as well if desired; in this script's case, that should be the name of the file being run.
.EXAMPLE
    Write-CmTraceLog -LogMessage "Write this message to the log." -LogFullPath "c:\someFolder\MyLogFile.log";
    This will write "Write this message to the log." to a log file named "MyLogFile.log" in the path "c:\someFolder\".
.EXAMPLE
    Write-CmTraceLog -LogMessage "Write this message to the log." -LogFullPath "c:\someFolder\MyLogFile.log" -MessageType Error;
    This will write "Write this message to the log." to a log file named "MyLogFile.log" in the path "c:\someFolder\" and will be highlighted red by cmtrace.
.NOTES
    NAME: Write-CmTraceLog
    HISTORY:
        Date          Author                    Notes
        02/08/2019    Benjamin Reynolds         Initial Creation.
        03/16/2021    Benjamin Reynolds         Updated to allow writing to host only and logic to do nothing if the path is empty (and writetohost is false).
        03/24/2021    Benjamin Reynolds         Removed WriteToHost switch and relying on "Verbose" instead.

    NOTES:
        The function doesn't test for the existence of the log file, that should be done within the calling script.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({$PSItem.Length -lt 4096})][string]$LogMessage
       ,[Parameter(Mandatory=$true)][AllowNull()][AllowEmptyString()][string]$LogFullPath
       ,[Parameter(Mandatory=$false)][ValidateSet("Informational","Warning","Error","None")][string]$MessageType = "Informational"
       ,[Parameter(Mandatory=$false)][switch]$UtcTime
       ,[Parameter(Mandatory=$false)][string]$Component = "default" # This is required for CMTrace to highlight correctly
       ,[Parameter(Mandatory=$false)][int]$Thread
       ,[Parameter(Mandatory=$false)][string]$Source = ""
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;
    
    if ([String]::IsNullOrWhiteSpace($LogFullPath) -and -Not $isVerbose)
    {
        return;
    }

    if ($UtcTime) {
        $CurDate = (Get-Date).ToUniversalTime();
        [string]$Offset = "+000";
    }
    else {
        $CurDate = Get-Date;
        [string]$Offset = (Get-TimeZone).BaseUtcOffset.TotalMinutes;
    }

    ## Write to Host if switch set:
    if ($isVerbose) {
        #Write-Host "$($CurDate.ToString("yyyy-MM-ddTHH:mm:ss.fff")) : $LogMessage" -ForegroundColor Cyan;
        Write-Verbose "$($CurDate.ToString("yyyy-MM-ddTHH:mm:ss.fff")) : $LogMessage";
        if ([String]::IsNullOrWhiteSpace($LogFullPath)) {return;}
    }
    
    [string]$date = $CurDate.ToString("MM-dd-yyyy");
    [string]$time = $CurDate.ToString("hh:mm:ss.fff")+$Offset;
    
    [string]$LogType = switch ($MessageType) {
                           "Informational" {"1";break;}
                           "Warning" {"2";break;}
                           "Error" {"3";break;}
                           default {"";break;}
                       };

    if (-not $Thread) {
        [int]$Thread = $PID;
    }

    ## Format the message for CMTrace type log line:
     # log.h says this should do this, but we'll just leave carriage returns/new lines alone (which seems like what LogParser.cs does):
     #$LogEntry = "<![LOG[$($LogMessage.Replace("\r\n","~").Replace("\r","~").Replace("\n","~"))]LOG]!><time=""$time"" date=""$date"" component=""$Component"" context="""" type=""$LogType"" thread=""$Thread"" file=""$Source"">";
    $LogEntry = "<![LOG[$LogMessage]LOG]!><time=""$time"" date=""$date"" component=""$Component"" context="""" type=""$LogType"" thread=""$Thread"" file=""$Source"">";

    ## Write to the log:
    Out-File -FilePath $LogFullPath -InputObject $LogEntry -Append -Encoding default;

} # End: Write-CmTraceLog

# Publish-SqlInfoMessage
function Publish-SqlInfoMessage {
<#
.SYNOPSIS
    The function processes the event objects from a message handler.
.DESCRIPTION
    The function processes the event objects from a message handler. The messages are sent to another
    function to write to a log file. The other function called is "Write-CmTraceLog".
.PARAMETER SqlInfoMessage
    The event object from a SqlInfoMessageEventHandler.
.PARAMETER Source
    The source of the Sql execution - script file name or sproc name.
.NOTES
    NAME: Publish-SqlInfoMessage
    HISTORY:
        Date          Author                    Notes
        02/08/2019    Benjamin Reynolds         Initial Creation.
        06/04/2021    Benjamin Reynolds         Updated due to changes in Write-CmTraceLog.
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][System.Data.SqlClient.SqlInfoMessageEventArgs]$SqlInfoMessage
       ,[Parameter(Mandatory=$false)][string]$Source
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    ## Let's see if we can determine the options for writing to the log
    if ($SqlInfoMessage.Message -notlike "Changed database context to*")
    {
        if ($SqlInfoMessage.Errors.Number -ne 0) {
            Write-CmTraceLog -LogMessage $SqlInfoMessage.Message -LogFullPath $Script:LogFullPath -MessageType Error -Component $Source -Verbose:$isVerbose;
        }
        elseif ($SqlInfoMessage.Message -like "WARNING:*") {
            Write-CmTraceLog -LogMessage $SqlInfoMessage.Message -LogFullPath $Script:LogFullPath -MessageType Warning -Component $Source -Verbose:$isVerbose;
        }
        else {
            Write-CmTraceLog -LogMessage $SqlInfoMessage.Message -LogFullPath $Script:LogFullPath -Component $Source -Verbose:$isVerbose;
        }
    }

    ####if ($SqlInfoMessage.Message -like "!Stop Processing!*") {
    ####    # Update the global variable so we know we need to stop the script:
    ####    $Global:StopProcessingInstallScript = $true;
    ####}

} # End: Publish-SqlInfoMessage

# Invoke-SqlScript
function Invoke-SqlScript {
<#
.SYNOPSIS
    This function executes a SQL script against a server/db and logs any information to a log file.
    No data is ever captured - the commands are simply executed using "ExecuteNonQuery".
.DESCRIPTION
    The function executes a provided SQL script and returns whether it was successful or not along with any error that was captured.
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
.PARAMETER SqlScriptFilePath
    This is the complete path (folder and file name) of the sql file to execute.
.PARAMETER SqlScriptText
    This is sql command to execute.
.PARAMETER SqlCommandTimeout
    This is CommandTimeout property to use instead of the default.
.PARAMETER ReturnValue
    If this switch is used then ExecuteScalar will be used and the first column/first row information will be returned to the caller.
    Note: if multiple commands will be run only the last command's information will be returned.
.EXAMPLE
    Invoke-SqlScript -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlScriptFilePath "C:\SqlScripts\Create Tables and Views.sql";
    This will get the text from the file "C:\SqlScripts\Create Tables and Views.sql" and run all the commands within it - running each portion found between any "GO" statements
    separately but within the same Sql connection (aka session) against the SQL Server "MySqlServer" and Database "MyDb". Any RAISERROR or PRINT statements will be written to a log file.
.EXAMPLE
    Invoke-SqlScript -SqlServerName "MySqlServer" -SqlDatabaseName "MyDb" -SqlScriptFilePath "C:\SqlScripts\Create Tables and Views.sql";
    This will get the text from the file "C:\SqlScripts\Create Tables and Views.sql" and run all the commands within it - running each portion found between any "GO" statements
    separately but within the same Sql connection (aka session) against the SQL Server "MySqlServer" and Database "MyDb". Any RAISERROR or PRINT statements will be written to a log file.
.OUTPUTS
    None (unless ReturnValue is used). However, PRINT and RAISERROR statements will be captured and handled by the function Publish-SqlInfoMessage.
    When ReturnValue is used then the first column/row information is returned to the caller.
.NOTES
    NAME: Invoke-SqlScript
    HISTORY:
        Date          Author                    Notes
        02/08/2019    Benjamin Reynolds         Initial Creation.
        02/18/2019    Benjamin Reynolds         Added "ReturnValue" parameter and logic.
        07/30/2019    Benjamin Reynolds         Updated default "Source" to use the name of the current file (so this can be re-used in other scripts).
        06/04/2021    Benjamin Reynolds         Updated and simplified for this current usage scenario. Added NewScriptDb as well.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='NoConnStringFile')]
        [Parameter(Mandatory=$true,ParameterSetName='NoConnStringText')]
        [Alias("SqlServer")]
        [string]$SqlServerName
       ,[Parameter(Mandatory=$false,ParameterSetName='NoConnStringFile')]
        [Parameter(Mandatory=$false,ParameterSetName='NoConnStringText')]
        [Alias("DatabaseName","Database")]
        [string]$SqlDatabaseName = 'master'
       ,[Parameter(Mandatory=$true,ParameterSetName='ConnStringFile')]
        [Parameter(Mandatory=$true,ParameterSetName='ConnStringText')]
        [string]$SqlConnString
       ,[Parameter(Mandatory=$false,ParameterSetName='ConnStringFile')]
        [Parameter(Mandatory=$false,ParameterSetName='ConnStringText')]
        [Alias("SqlCreds")]
        [System.Data.SqlClient.SqlCredential]$SqlCredentials
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnStringFile')]
        [Parameter(Mandatory=$true,ParameterSetName='ConnStringFile')]
        [ValidateScript({Test-Path -Path $PSItem})]
        [String]$SqlScriptFilePath
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnStringText')]
        [Parameter(Mandatory=$true,ParameterSetName='ConnStringText')]
        [string]$SqlScriptText
       ,[Parameter(Mandatory=$false)][AllowNull()][String]$NewScriptDb
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
       ,[Parameter(Mandatory=$false)][switch]$ReturnValue
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;
    [bool]$StopFunction = $false;
    
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
        $SqlErrorCaptured = $PSItem;
        [string]$LogText = "Error Captured trying to create the SQL Connection. Error Captured:`n$SqlErrorCaptured";
        if ($LogText.Length -gt 4095)
        {
            $LogText = $LogText.Substring(0,4092)+"...";
        }
        Write-CmTraceLog -LogMessage $LogText -LogFullPath $Script:LogFullPath -MessageType Error -Component 'Invoke-SqlScript' -Verbose:$isVerbose;
        $StopFunction = $true;
    }

    if (-Not $StopFunction)
    {
        if ($PsCmdlet.ParameterSetName -like '*ConnStringFile')
        {
            ## Get the .sql file to run and create an object with all the commands split by 'GO' batch terminator for handling:
            [string]$SqlScriptFile = Get-Content -Path $SqlScriptFilePath -Raw;
            [string]$Source = (Split-Path $SqlScriptFilePath -Leaf);
    
            # Update Script code to new db if necessary:
            if (-Not [String]::IsNullOrWhiteSpace($NewScriptDb))
            {
                if ((Split-Path -Path $SqlScriptFilePath -Leaf) -eq 'CreateDatabase.sql')
                {
                    $SqlScriptFile = $SqlScriptFile.Replace("@DatabaseName  sysname = N'Intune'","@DatabaseName  sysname = N'$NewScriptDb'")
                }
                elseif ((Split-Path -Path $SqlScriptFilePath) -like '*\DatabaseFiles\Jobs*') #(Split-Path -Path (Split-Path -Path $SqlScriptFilePath) -Leaf) -eq 'Jobs'
                {
                    $SqlScriptFile = $SqlScriptFile.Replace("       ,@database_name = N'Intune'","       ,@database_name = N'$NewScriptDb'");
                }
                else
                {
                    $SqlScriptFile = $SqlScriptFile.Replace("USE [Intune];","USE [$NewScriptDb];");
                }
            }
        }
        else
        {
            ## Just use the text that was sent in:
            [string]$SqlScriptFile = $SqlScriptText;
            [string]$Source = 'Custom SQL Command Passed In';
        }

        # Split the commands by the 'GO' batch terminator:
        $regex = New-Object -TypeName System.Text.RegularExpressions.Regex -ArgumentList '^[\t ]*GO[\t ]*\d*[\t ]*;*(?:--.*)*[\r]*$',@('IgnoreCase','Multiline');
        $SqlCommands = $SqlScriptFile -split "$regex",0,@("$($regex.Options)");
        
        ## Add a SqlInfoMessageEventHandler to capture info messages:
        $SqlInfoMessageEventHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender,$event) Publish-SqlInfoMessage -SqlInfoMessage $event -Source $Source -Verbose:$isVerbose};
        $SqlConn.add_InfoMessage($SqlInfoMessageEventHandler);
        $SqlConn.FireInfoMessageEventOnUserErrors = $true;

        ## Connect to SQL and run the commands as batches - no data will be captured, only info messages will be saved:
        $SqlConn.Open();
        try
        {
            ## First, let's set quoted_identifier on before running the rest of the statements:
            $SqlCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList "SET QUOTED_IDENTIFIER ON;", $SqlConn;
            if ($null -ne $SqlCommandTimeout)
            {
                $SqlCmd.CommandTimeout = $SqlCommandTimeout;
            }
            $null = $SqlCmd.ExecuteNonQuery();
            Remove-Variable -Name SqlCmd -ErrorAction SilentlyContinue;
            ## Now, run each command found in the file/text:
            foreach ($SqlStatement in $SqlCommands)
            {
                if (-not [string]::IsNullOrWhiteSpace($SqlStatement))
                { 
                    $SqlCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList $SqlStatement.Trim(), $SqlConn;
                    if ($null -ne $SqlCommandTimeout)
                    {
                        $SqlCmd.CommandTimeout = $SqlCommandTimeout;
                    }
                    if ($ReturnValue -eq $false)
                    {
                        $null = $SqlCmd.ExecuteNonQuery();
                    }
                    else
                    {
                        $SqlColVal = $SqlCmd.ExecuteScalar();
                    }
                    Remove-Variable -Name SqlCmd -ErrorAction SilentlyContinue;
                }
            }
            Remove-Variable -Name SqlStatement -ErrorAction SilentlyContinue;
        }
        catch
        {
            $SqlErrorCaptured = $PSItem;
            [string]$LogText = "Error Captured trying to execute a command. Error Captured:`n$SqlErrorCaptured`n***************************`nErrorStatement:`n$SqlStatement";
            if ($LogText.Length -gt 4095)
            {
                $LogText = $LogText.Substring(0,4092)+"...";
            }
            Write-CmTraceLog -LogMessage $LogText -LogFullPath $Script:LogFullPath -MessageType Error -Component $Source -Verbose:$isVerbose;
        }
        finally
        { # Make sure to close the connection whether successful or not
            if ($SqlConn.State -ne [System.Data.ConnectionState]::Closed) {$SqlConn.Close();}
        }
    }
    
    ## If we wanted to return a value then do it here:
    if ($ReturnValue -eq $true)
    {
        return $SqlColVal;
    }

} # End: Invoke-SqlScript

<###############################################################################################################################################################
            END FUNCTIONS
<###############################################################################################################################################################>

## Check that the user has updated scripts for their environment:
if ($ConfirmUpdates -eq $false)
{
    $bullet = [char]0x2022;
    $scriptsToCheck = @"
Scripts to check/Update:

1. ALL .sql scripts in the "Jobs" folder
  $bullet These will fail without updating the variables (DB Mail,etc)
2. usp_IntuneSyncToSqlMonitor.sql (in the "Procedures" folder)
  $bullet This makes use of DB Mail; update vars so it doesn't fail.
3. usp_JobFailureEmailAlert.sql (in the "Procedures" folder)
  $bullet This makes use of DB Mail; update vars so it doesn't fail.
4. AadGroups.sql (in the "Tables" folder)
  $bullet Add any AAD Groups for which you want to sync membership.
5. v_deviceConfigurations_For_deviceStatuses.sql (in the "Views" folder)
  $bullet Update with desired/valid ids for which to get data.
6. v_deviceCompliancePolicies_For_deviceSettingStateSummaries (in the "Views" folder)
  $bullet Update with desired/valid ids for which to get data.
7. v_deviceCompliancePolicies_For_devicesStatuses (in the "Views" folder)
  $bullet Update with desired/valid ids for which to get data.

The following have defaults but could use some adjustments if desired:
1. LongRunningJobThresholds (in the "Tables" folder)
  $bullet Alert Thresholds can be updated/added here
2. usp_PopulateDCPDeviceStatusOverviewHistoryTable.sql (in the "Procedures" folder)
  $bullet Update to only look at a specific compliancePolicy?
"@
    $msg = @"
DID YOU UPDATE THE SCRIPTS FOR YOUR ENVIRONMENT?

$scriptsToCheck
"@;
    $wShell = New-Object -ComObject Wscript.Shell;
    $intChoice = $wShell.Popup($msg,0,"Important!",48+4);
    if ($intChoice -eq 7) # user chose "No"
    {
        $LogMsg = "User confirmed that scripts have not been updated with the environment variables! Script Aborting. $scriptsToCheck";
        Write-CmTraceLog -LogMessage $LogMsg -LogFullPath $Script:LogFullPath -MessageType Error -Component 'InstallDatabase' -Verbose;
        break;
    }
}

##
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "******************************************   Script Starting   ****************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;

## Create SQL ConnectionString (use builder to ensure everything is good to go):
$SqlConnStringBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
$SqlConnStringBuilder['Server'] = $SqlServerName;
$SqlConnStringBuilder['Database'] = $SqlDatabaseName;
if ($null -ne $SqlConnTimeout)
{
    $SqlConnStringBuilder['Connection Timeout'] = $SqlConnTimeout;
}
$SqlConnStringBuilder['Integrated Security'] = $true; # Windows Auth

## Create Sql Connection Splatter:
$SqlConnSplat = @{SqlConnString = $SqlConnStringBuilder.ConnectionString};
$SqlConnSplat.Add("SqlConnTimeout",$SqlConnTimeout);
if ($null -ne $SqlCommandTimeout)
{
    $SqlConnSplat.Add("SqlCommandTimeout",$SqlCommandTimeout);
}

##
[string]$rootdir = $PSScriptRoot.Substring(0,$PSScriptRoot.IndexOf('MsGraphToSql')+12);


## 
$dependencies = @(
                  @{ScriptName = 'v_groupPolicyConfigurations_PresentationInformation.sql'; Dependencies = @('v_groupPolicyDefinitionsFlat','v_groupPolicyConfigurationPresentationValues','v_groupPolicyConfigurations_definitionValues')}
                 ,@{ScriptName = 'v_Autopilot_AadInfo.sql'; Dependencies = @('v_WindowsAutopilotDevices','v_AzureAdDevices_PhysicalIds','v_AzureAdDevices','v_managedDevices')}
                  );
$comebacktothese = New-Object -TypeName System.Collections.ArrayList;

##
foreach ($dir in $Folders)
{
    foreach ($script in (Get-ChildItem -Path "$rootdir\DatabaseFiles\$dir" -Attributes !Directory).FullName)
    {
        if ((Split-Path -Path $script -Leaf) -notin ($dependencies.GetEnumerator()).ScriptName)
        {
            Invoke-SqlScript @SqlConnSplat -SqlScriptFilePath $script -NewScriptDb:$NewScriptDb -Verbose:$isVerbose;
        }
        else
        {
            [void]$comebacktothese.Add($script);
        }
    }
    Remove-Variable -Name script -ErrorAction SilentlyContinue;

    ## Loop through the "comebacktothese" array up to 3 times checking that the dependencies exist and if so run the script
    for ($l = 0; $l -lt 3; $l++)
    {
        if ($comebacktothese.Count -eq 0)
        {
            break;
        }
        else
        {
            for ($i = $comebacktothese.Count-1; $i -ge 0; $i--)
            {
                ## get the dependency object and check to see if the dependencies have been created already and if so run the dependant script
                $curDepend = $dependencies[[array]::IndexOf($dependencies.GetEnumerator().ScriptName,(Split-Path -Path $comebacktothese[$i] -Leaf))];
                [string]$sqlString = "USE [$(if ([String]::IsNullOrWhiteSpace($NewScriptDb)) {'Intune'} else {$NewScriptDb})]; SET NOCOUNT ON; SELECT $($curDepend['Dependencies'].Count)-COUNT(1) FROM sys.objects WHERE name IN (N'$($curDepend['Dependencies'] -join "',N'")');";
                [int]$dependRemaining = Invoke-SqlScript @SqlConnSplat -SqlScriptText $sqlString -ReturnValue -Verbose:$isVerbose;        
                if ($dependRemaining -eq 0)
                {
                    # Run the command and then remove from the array
                    Invoke-SqlScript @SqlConnSplat -SqlScriptFilePath $comebacktothese[$i] -NewScriptDb:$NewScriptDb -Verbose:$isVerbose;
                    $comebacktothese.RemoveAt($i);
                }
                #else
                #{
                #    # skip it
                #}
                Remove-Variable -Name curDepend,sqlString,dependRemaining -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name i -ErrorAction SilentlyContinue;
        }
    }
    Remove-Variable -Name l -ErrorAction SilentlyContinue;
}

## Loop through the "comebacktothese" array up to 5 more times checking that the dependencies exist and if so run the scripts
for ($l = 0; $l -lt 5; $l++)
{
    if ($comebacktothese.Count -eq 0)
    {
        break;
    }
    else
    {
        for ($i = $comebacktothese.Count-1; $i -ge 0; $i--)
        {
            ## get the dependency object and check to see if the dependencies have been created already and if so run the dependant script
            $curDepend = $dependencies[[array]::IndexOf($dependencies.GetEnumerator().ScriptName,(Split-Path -Path $comebacktothese[$i] -Leaf))];
            [string]$sqlString = "USE [$(if ([String]::IsNullOrWhiteSpace($NewScriptDb)) {'Intune'} else {$NewScriptDb})]; SET NOCOUNT ON; SELECT $($curDepend['Dependencies'].Count)-COUNT(1) FROM sys.objects WHERE name IN (N'$($curDepend['Dependencies'] -join "',N'")');";
            [int]$dependRemaining = Invoke-SqlScript @SqlConnSplat -SqlScriptText $sqlString -ReturnValue -Verbose:$isVerbose;        
            if ($dependRemaining -eq 0)
            {
                # Run the command and then remove from the array
                Invoke-SqlScript @SqlConnSplat -SqlScriptFilePath $comebacktothese[$i] -NewScriptDb:$NewScriptDb -Verbose:$isVerbose;
                $comebacktothese.RemoveAt($i);
            }
            #else
            #{
            #    # skip it
            #}
            Remove-Variable -Name curDepend,sqlString,dependRemaining -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name i -ErrorAction SilentlyContinue;
    }
}
Remove-Variable -Name l -ErrorAction SilentlyContinue;

if ($comebacktothese.Count -gt 0)
{
    Write-CmTraceLog -LogMessage "Not all dependencies have been created!`r`nDependencies Remaining:`r`n$comebacktothese" -LogFullPath $LogFullPath -MessageType Error -Component $scriptName -Verbose:$isVerbose;
}
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "******************************************   Script Finished   ****************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
Write-CmTraceLog -LogMessage "*******************************************************************************************************" -LogFullPath $LogFullPath -Component $scriptName -Verbose:$isVerbose;
