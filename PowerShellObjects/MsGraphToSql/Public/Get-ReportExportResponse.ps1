# Get-ReportExportResponse
function Get-ReportExportResponse {
<#
.SYNOPSIS
    This function posts a request to the reportExport API, checks for the completion of the report and returns the url to download the report.
.DESCRIPTION
    The function creates the POST body and issues the POST to the reportExport API. After the POST, it will check the service every 2 seconds until
    the report is not longer 'inProgress' and return the information back to the caller.
.EXAMPLE
    Get-ReportExportResponse -ExportUrl 'https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs' -ReportName Devices;
    This will request the Devices report from the beta version be created, wait for it to fail or succeed and return the information back.
.NOTES
    NAME: Get-ReportExportResponse
    HISTORY:
        Date                Author                    Notes
        03/01/2021          Benjamin Reynolds         Initial Creation
        03/18/2021          Benjamin Reynolds         Added Connection Closed and ServerUnavailable retry logic.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true)][String]$ExportUrl
       ,[Parameter(Mandatory=$false,HelpMessage="This should be the command used to create the auth token - it needs to start with Get-Authentication")][String]$GetAuthStringCmd
       ,[Parameter(Mandatory=$true)][string]$ReportName
       ,[Parameter(Mandatory=$false)][string]$Select
       ,[Parameter(Mandatory=$false)][string]$Filter
       ,[Parameter(Mandatory=$false)][int]$ReconnRetryThreshold=3
       ,[Parameter(Mandatory=$false)][int]$ConnClosedRetryThreshold=3
       ,[Parameter(Mandatory=$false)][int]$ServerUnavailableRetryThreshold=3
    )

    ## Make sure we have authenticated to AD/Graph already and if not try to:
    if (-Not $Global:ADAuthResult)
    {
        if ($GetAuthStringCmd)
        {
            Invoke-Expression $GetAuthStringCmd;
        }
        else
        {
            try
            {
                Get-Authentication -User "$env:USERNAME@$($env:USERDNSDOMAIN.Substring($env:USERDNSDOMAIN.LastIndexOf('.',$env:USERDNSDOMAIN.LastIndexOf('.')-1)+1).ToLower())"; # My best guess at the current user's UPN
            }
            catch
            {
                throw "No authentication context. Authenticate first by running 'Get-Authentication'";
            }
        }
    }
    
    ## Create the POST body:
    $postHash = @{reportName = $ReportName;};
    if (-Not [String]::IsNullOrWhiteSpace($Filter))
    {
        $postHash.Add('filter',"$Filter");
    }
    if (-Not [String]::IsNullOrWhiteSpace($Select))
    {
        $postHash.Add('select',"$Select");
    }
    $postBody = $postHash | ConvertTo-Json;

    $StartTime = $(Get-Date);

    ## Variables to handle retries:
    [int]$ReconnRetry = 0;
    [int]$ConnClosedRetry = 0;
    [int]$ServerUnavailableRetry = 0;
    [bool]$RetriesOccurred = $false;
    [bool]$CatchEndLoop = $false;
    
    ## use a while to allow for retries:
    while ($ExportUrl)
    {
        try
        {
            if ([String]::IsNullOrWhiteSpace($statusUrl))
            {
                ## Prepare the Post:
                $clientRequestId = [Guid]::NewGuid();
                if ($null -ne $Global:ADAuthResult.AccessToken) {
                    $headers = @{
                                'Content-Type'='application/json'
                                'Authorization'="Bearer " + $Global:ADAuthResult.AccessToken
                                'ExpiresOn'= $Global:ADAuthResult.ExpiresOn
                                'client-request-id'=$clientRequestId
                                }
                }
                else {
                    $headers = @{
                                'Content-Type'='application/json'
                                'Authorization'="Bearer " + $Global:ADAuthResult.access_token
                                'ExpiresOn'= ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on))).ToUniversalTime() # don't think this is required...
                                'client-request-id'=$clientRequestId # don't think this is required...
                                }
                }
                
                ## Issue the Post:
                $Response = Invoke-RestMethod -Uri $ExportUrl -Method Post -Body $postBody -Headers $headers;
                
                $statusUrl = "$ExportUrl('$($Response.id)')";
            }

            ## wait/check for the report to finish being created then return the response:
            do
            {
                Start-Sleep -Seconds 2;
                $clientRequestId = [Guid]::NewGuid();
                if ($null -ne $Global:ADAuthResult.AccessToken) {
                    $headers = @{
                                'Content-Type'='application/json'
                                'Authorization'="Bearer " + $Global:ADAuthResult.AccessToken
                                'ExpiresOn'= $Global:ADAuthResult.ExpiresOn
                                'client-request-id'=$clientRequestId
                                }
                }
                else {
                    $headers = @{
                                'Content-Type'='application/json'
                                'Authorization'="Bearer " + $Global:ADAuthResult.access_token
                                'ExpiresOn'= ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on))).ToUniversalTime() # don't think this is required...
                                'client-request-id'=$clientRequestId # don't think this is required...
                                }
                }
                
                $StatusResponse = Invoke-RestMethod -Uri $statusUrl -Method Get -Headers $headers;
            }
            while ($StatusResponse.status -eq 'inProgress')

            #stop the loop if we get to this point:
            $ExportUrl = $null;
        }
        catch [System.Net.WebException]
        { # For some reason some errors have ErrorDetails and sometimes they don't, so we use ErrorDetails and Exception to check:
            ## Check for authentication expiry issues:
            if ((($PSItem.ErrorDetails -like "*Access token has expired*") -eq $true) -or (($PSItem.Exception -like "*Access token has expired*") -eq $true) -or (($PSItem.ErrorDetails -like "*(401) Unauthorized*") -eq $true) -or (($PSItem.Exception -like "*(401) Unauthorized*") -eq $true))
            {
                # this is to ensure we don't get in an infinite loop with the unauthorized error message:
                if (    ($null -ne $Global:ADAuthResult.ExpiresOn -and ($Global:ADAuthResult.ExpiresOn.DateTime - $((Get-Date).ToUniversalTime())).Minutes -ge 10) `
                    -or ($null -ne $Global:ADAuthResult.expires_on -and ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on)) - (Get-Date)).Minutes -ge 10) `
                    )
                {
                    # the issue isn't with the token being expired
                    $CatchEndLoop = $true;
                    if ($null -ne $Global:ADAuthResult.ExpiresOn)
                    {
                        $MinRemaining = ($Global:ADAuthResult.ExpiresOn.DateTime - $((Get-Date).ToUniversalTime())).Minutes;
                    }
                    else
                    {
                        $MinRemaining = ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on)) - (Get-Date)).Minutes;
                    }
                    [string]$ReturnErrorInfo = "Unauthorized Error returned when the token is still active.`r`nLast Client Request Id: $clientRequestId`r`nMinutes remaining with current token: $MinRemaining`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unhandled Error Encountered. Original Error is:";
                    Write-Verbose $PSItem.Exception;
                    Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
                    Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Minutes remaining with current token: $MinRemaining";
                    Remove-Variable -Name MinRemaining -ErrorAction SilentlyContinue;
                    break; # this breaks out of the while loop
                }

                $ReconnRetry += 1;
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : We Need to Handle the timeout of the Access Token; Going to try to re-authenticate...";
                ## Re-Authenticate to get a new access token:
                if ($GetAuthStringCmd)
                {
                    Invoke-Expression $GetAuthStringCmd;
                }
                else
                {
                    Get-Authentication -User "$env:USERNAME@$($env:USERDNSDOMAIN.Substring($env:USERDNSDOMAIN.LastIndexOf('.',$env:USERDNSDOMAIN.LastIndexOf('.')-1)+1).ToLower())"; # My best guess at the current user's UPN
                }
                # Check to see if we were able to authenticate but let's wait a second or two first:
                Start-Sleep -Seconds 2;
                # if ExpiresOn exists then it is a user/app auth, if it's "expires_on" then it's MSI auth:
                if (    ($null -ne $Global:ADAuthResult.ExpiresOn -and ($Global:ADAuthResult.ExpiresOn.DateTime - $((Get-Date).ToUniversalTime())).Minutes -ge 10) `
                    -or ($null -ne $Global:ADAuthResult.expires_on -and ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on)) - (Get-Date)).Minutes -ge 10) `
                    )
                {
                    $ReconnRetry = 0;
                    continue; # this continues the while loop...goes to the start of the while loop
                }
                else
                {
                    if ($ReconnRetry -le $ReconnRetryThreshold)
                    {
                        Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unable to get a new AccessToken will try again. Retry: $ReconnRetry of $ReconnRetryThreshold.";
                        # don't do anything so it tries again...no explicit retry of the connection but the ExportUrl is the same and will try again in the loop...
                        continue; # this continues the while loop...goes to the start of the while loop with the ExportUrl we just tried (same as not having it here really)
                    }
                    else
                    {
                        $CatchEndLoop = $true;
                        [string]$ReturnErrorInfo = "Unable to get a new AccessToken for the last number of retries ($ReconnRetryThreshold); returning to caller.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                        Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unable to get a new AccessToken for the last number of retries ($ReconnRetryThreshold); returning to caller.";
                        Write-Verbose $PSItem.Exception;
                        break; # this breaks out of the while loop
                    }
                }
            } #End AccessToken Expiration if block
            elseif (($PSItem.Exception -like "*(400) Bad Request*") -eq $true)
            {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Bad Request Error Caught; Better check the URL you tried to use! Will return to caller.`r`nBad Request URL: $ExportUrl`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Bad Request Error Caught; Better check the URL you tried to use! Will return to caller.";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Bad Request URL: $ExportUrl";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
                break; # this breaks out of the while loop
            } #End: Bad Request error catch
            elseif (($PSItem.Exception -like "*(403) Forbidden*") -eq $true)
            {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Forbidden Error Caught; will return to caller.`r`nForbidden URL (need to get access to this resource): $ExportUrl`r`n`r`nLast Client Request Id: $clientRequestIdFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Forbidden Error Caught; will return to caller.";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Forbidden URL (need to get access to this resource): $ExportUrl";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
                break; # this breaks out of the while loop
            } #End: Forbidden URL error catch
            elseif (($PSItem.Exception -like "*(500) Internal Server Error*") -eq $true)
            {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Internal Server Error Caught; not sure what this is but it seems bad. Will return to caller.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Internal Server Error Caught; not sure what this is but it seems bad. Will return to caller.";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
                break; # this breaks out of the while loop
            } #End: Internal Server Error catch
            elseif (($PSItem.Exception -like "*(503) Server Unavailable*") -eq $true)
            {
                ## iterate the server unavailable counter since we'll retry on this error a few times:
                $ServerUnavailableRetry += 1;
                $RetriesOccurred = $true;
                if ($ServerUnavailableRetry -le $ServerUnavailableRetryThreshold)
                {
                    # retry after 5 minutes
                    Write-Warning "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Server Unavailable! Will try again in 3 minutes. Retry: $ServerUnavailableRetry of $ServerUnavailableRetryThreshold.";
                    Start-Sleep -Seconds 180;
                    continue; # this continues the while loop...goes to the start of the while loop
                }
                else
                {
                    $CatchEndLoop = $true;
                    [string]$ReturnErrorInfo = "Server Unavailable for the last number of retries ($ServerUnavailableRetryThreshold); returning to caller.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-Host "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Server Unavailable for the last number of retries ($ServerUnavailableRetryThreshold); returning to caller." -ForegroundColor Red;
                    break; # this breaks out of the while loop
                }
            } #End: Server Unavailable error catch
            elseif (($PSItem.Exception -like "*underlying connection was closed*") -eq $true)
            {
                ## iterate the connection closed counter since we'll retry on this error a few times:
                $ConnClosedRetry += 1;
                $RetriesOccurred = $true;
                if ($ConnClosedRetry -le $ConnClosedRetryThreshold)
                {
                    # retry after 3 minutes
                    Write-Warning "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Connection Closed for some reason! Will try again in 3 minutes. Retry: $ConnClosedRetry of $ConnClosedRetryThreshold.";
                    Start-Sleep -Seconds 180;
                    continue; # this continues the while loop...goes to the start of the while loop
                }
                else
                {
                    $CatchEndLoop = $true;
                    [string]$ReturnErrorInfo = "Connection Closed for some reason for the last number of retries ($ConnClosedRetryThreshold); returning to caller.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-Host "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Connection Closed for some reason for the last number of retries ($ConnClosedRetryThreshold); returning to caller." -ForegroundColor Red;
                    break; # this breaks out of the while loop
                }
            } #End: Connection Closed error catch
            else
            {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Unhandled WebException Error Encountered.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unhandled WebException Error Encountered. Original Error is:";
                Write-Verbose $PSItem.Exception;
                Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
                break; # this breaks out of the while loop
            } #End: unhandled error catch
        } # End Catch WebException block
        catch
        { # Catch any other type of exception here (shouldn't ever get here but just in case):
            $CatchEndLoop = $true;
            [string]$ReturnErrorInfo = "Unhandled Error Encountered.`r`nLast Client Request Id: $clientRequestId`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Unhandled Error Encountered. Original Error is:";
            Write-Verbose $PSItem.Exception;
            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Last Client Request Id: $clientRequestId";
            break; # this breaks out of the while loop
        } # End Catch 'all other exceptions' block
    } # End While Loop

    $ElapsedTime = $(Get-Date) - $StartTime;
    Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Report Export Job Completed in $("{0:HH:mm:ss.fff}" -f [datetime]$ElapsedTime.Ticks)";

    $ReturnObj = New-Object -TypeName PSObject -Property @{"StatusURL"=$statusUrl;"StatusResponse"=$StatusResponse;"LastClientRequestId"=$clientRequestId;"Duration"=$("{0:HH:mm:ss.fff}" -f [datetime]$ElapsedTime.Ticks);"ErrorCaught"=$CatchEndLoop;"RetriesOccurred"=$RetriesOccurred;"ErrorMessage"=$ReturnErrorInfo};
    Remove-Variable -Name statusUrl,StatusResponse,clientRequestId,ElapsedTime,CatchEndLoop,RetriesOccurred,ReturnErrorInfo -ErrorAction SilentlyContinue;

    return $ReturnObj;

} # End: Get-ReportExportResponse
