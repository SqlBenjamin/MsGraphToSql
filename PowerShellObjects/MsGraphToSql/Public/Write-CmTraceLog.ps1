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
        Date                Author                    Notes
        02/08/2019          Benjamin Reynolds         Initial Creation.
        03/16/2021          Benjamin Reynolds         Updated to allow writing to host only and logic to do nothing if the path is empty (and writetohost is false).
        03/24/2021          Benjamin Reynolds         Removed WriteToHost switch and relying on "Verbose" instead.

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
