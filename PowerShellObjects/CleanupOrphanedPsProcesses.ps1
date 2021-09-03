<#
.SYNOPSIS
    This kills any orphaned powershell processes still running.
.DESCRIPTION
    SQL Agent Jobs that kick off IntuneSync processes and then get stopped leave PowerShell processes still running.
    This script will determine any orphaned PowerShell processes and kill/stop them.
.NOTES
    NAME: CleanupOrphanedPsProcesses
    HISTORY:
        Date          Author                    Notes
        03/15/2021    Benjamin Reynolds         Initial Creation
#>
[cmdletbinding()]

# Get the cmd and PowerShell processes associated with IntuneSync stuff:
$CmdProcs = Get-CimInstance win32_process -Filter "(Name = 'cmd.exe') AND (CommandLine LIKE '%IntuneSyncToSql.ps1%' OR CommandLine LIKE '%AadRegisteredOwnersSyncToSql.ps1%')";
$PsProcs = Get-CimInstance win32_process -Filter "(Name = 'powershell.exe') AND (CommandLine LIKE '%IntuneSyncToSql.ps1%' OR CommandLine LIKE '%AadRegisteredOwnersSyncToSql.ps1%')";
## For testing:
#$CmdProcs = Get-CimInstance win32_process -Filter "(Name = 'cmd.exe')";
#$PsProcs = Get-CimInstance win32_process -Filter "(Name = 'powershell.exe')";

# Create the parent/child relationship of the cmd and PS processes:
$ProcessesHt = New-Object System.Collections.Hashtable;
foreach ($PsProc in $PsProcs)
{
    foreach ($CmdProc in $CmdProcs)
    {
        if ($CmdProc.ProcessId -eq $PsProc.ParentProcessId)
        {
            $AssocCmd = $CmdProc.ProcessId;
        }
    }
    $ProcessesHt.Add($PsProc.ProcessId,$AssocCmd);
    Remove-Variable -Name AssocCmd -ErrorAction SilentlyContinue;
}
Remove-Variable -Name CmdProc,PsProc,CmdProcs,PsProcs -ErrorAction SilentlyContinue;

[int]$i = 0;

# Kill orphaned Powershell processes:
foreach ($prid in $ProcessesHt.GetEnumerator())
{
    if ($null -eq $prid.Value)
    {
        if ($null -ne (Get-Process -Id $prid.Key -ErrorAction SilentlyContinue))
        {
            Stop-Process -Id $prid.Key -Force;
            Write-Host "Process $($prid.Key) killed.";
            $i++;
        }
    }
}
Remove-Variable -Name prid -ErrorAction SilentlyContinue;

if ($i -gt 0)
{
    Write-Host "[[$i Processes Killed]]";
}

# Final Cleanup
Remove-Variable -Name CmdProcs,PsProcs,CmdProc,PsProc,AssocCmd,prid,ProcessesHt -ErrorAction SilentlyContinue;
