# Get-IntuneOpStoreData
function Get-IntuneOpStoreData {
<#
.SYNOPSIS
    This function is used to get data from MS Graph from a specified URI/URL.
.DESCRIPTION
    The function returns all data from a given URI/URL (via paging when needed). It has the ability to get data in batches if that is desired.
.PARAMETER OdataUrl
    Required.
    This is the URI/URL from which to start collecting data.
.PARAMETER GetAuthStringCmd
    Not Required.
    This is the command used to create the authentication token - it needs to start with "Get-Authentication".
    This is used to re-authenticate to the service in the event the access token has expired. This is especially
    helpful if the process to get data runs longer than the auth token duration - rather than having the process
    stop in the middle of getting data the authentication token is renewed automatically and the process can
    continue getting data from where it last left off. This string parameter will look like one of the following:
    "Get-Authentication -User user@example.com -SecurePassword $Global:ASecureStringParameter -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
    "Get-Authentication -User user@example.com -UserPasswordCredentials $Global:ACredentialsParameter -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
.PARAMETER WriteBatchSize
    Not Required. Default = 50,000
    This is the point in which the function will stop collecting data and send the data back to the caller for processing.
    The data is sent along with the "next URL" in order to be handled by the caller and if desired, the rest of the data
    can be obtained by calling this function again with the link previously provided in the output object.
.PARAMETER CurNumRecords
    This parameter is used when doing batching. It is a way to help control host output information as well as keep track of record counts.
.PARAMETER VerboseRecordCount
    This helps control the amount of information returned to the host. Note: this is currently broken. It use to work but got messed up in one of the latest changes that were made.
.PARAMETER TopCount
    This is part of the ParameterSet "UseSkipCounts". This was created to work around some bugs with certain URLs. It should work, but may not be great...this functionality should
    be removed at a future date but is being left in case another URL is found to have not implemented 'next link' correctly/fully.
    Avoid using this workaround at all costs. :)
.PARAMETER ReconnRetryThreshold
    This is used to control how many times the function will try to re-authenticate to Azure AD (Graph). The default is 3 times.
.PARAMETER GatewayTimeoutRetryThreshold
    This is used to control how many times the function will retry a GET from a URL that returns a "Gateway Timeout" error. The default is 5.
.PARAMETER ServerUnavailableRetryThreshold
    This is used to control how many times the function will retry a GET from a URL that returns a "Server Unavailable" error. The default is 5.
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.EXAMPLE
    Get-IntuneOpStoreData -OdataUrl "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices" -GetAuthStringCmd "Get-Authentication -User user@example.com -SecurePassword $Global:ASecureStringParameter -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
    Returns all devices from the Operational Store in a batch of 50,000 records (or all records if less than this amount)
.EXAMPLE
    Get-IntuneOpStoreData -OdataUrl "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices" -GetAuthStringCmd "Get-Authentication -User user@example.com -UserPasswordCredentials $Global:ACredentialsParameter -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee" -WriteBatchSize 99999999 -VerboseInfo $true;
    Returns all devices from the Operational Store in a batch of 99,999,999 records (or all records if less than this amount) and writes to the host the time of the call and how many records received
.EXAMPLE
    Get-IntuneOpStoreData -OdataUrl "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices" -GetAuthStringCmd $AuthStringCreatedBefore -TopCount 1000;
    Returns all devices from the Operational Store in a batch of 50,000 records (or all records if less than this amount) using a custom paging of data rather than using 'nextlink'.
.OUTPUTS
    A PSObject containing the data and the "Next URL" if one exists (or is required to get the rest of the data from the collection).
    The data is contained in the "DataObject" object and the next url in "URL" (a string).
.NOTES
    NAME: Get-IntuneOpStoreData
    HISTORY:
        Date          Author                                       Notes
        12/04/2017    Benjamin Reynolds         Adapted from Nick Ciaravella's "Get-IntuneDataWarehouseCollection"
        04/02/2018    Benjamin Reynolds         Changed to Invoke-RestMethod instead of Invoke-WebRequest (for automation - avoids some issues)
        04/05/2018    Benjamin Reynolds         Updated WriteBatchSize logic to account for multi-url calls to the function
        05/23/2018    Benjamin Reynolds         Updating to ArrayList for addition of data. Added Server Unavailable catching logic.
        07/26/2018    Benjamin Reynolds         Updating the ArrayList to be an ArrayList of all the items rather than an ArrayList of Arrays...
        08/10/2018    Benjamin Reynolds         Added retry thresholds, comments, updated WriteBatchSize/VerboseRecordCount logic
        08/10/2018    Benjamin Reynolds         Incorporated 'SkipCount' logic from separate function ("Get-IntuneOpStoreDataUsingSkipCounts") created previously. History of that function (where different):
                                                04/20/2018 - Benjamin Reynolds - Adapted from "Get-IntuneOpStoreData" to use SkipCounts as a workaround for when nextLink isn't working correctly
                                                04/27/2018 - Benjamin Reynolds - Added TopCount to account for API silliness...
        09/06/2018    Benjamin Reynolds         Parameterized the threshold values. Added "RetriesOccurred" and "ErrorMessage" to Return Object for better error handling/logging.
        09/20/2018    Benjamin Reynolds         Added logic to handle when the service doesn't return a "value" object (an object of all the data/records) but rather just the direct properties as one record.
                                                For example: "...deviceCompliancePolicies/{id}/userStatusOverview" doesn't return a value object but rather just data; whereas "...managedDevices" will return a value object.
        10/04/2018    Benjamin Reynolds         Fixed the logic that handles when the service returns a "value" object with no data in it. The check for the value existence needed updating for this scenario.
        09/03/2020    Benjamin Reynolds         Updated the catch block to use 'Exception' as well as 'ErrorDetails' since sometimes the 'ErrorDetails' is blank but the 'Exception' isn't...
        03/23/2021    Benjamin Reynolds         Added retry logic for the "The operation has timed out" error.
        03/24/2021    Benjamin Reynolds         Updated Write-Host info to write to the log file if it exists - added LogFullPath parameter and logic.
                                                Removed "VerboseInfo" since "Verbose" flag should do that instead

    ISSUES:
        ?? The 'WriteBatchSize' doesn't work when the records returned are not exactly the count - i.e., if 50,000 is the WriteBatchSize/VerboseRecordCount and 50,050 records are gotten then we don't hit the logic to write the info out...
        ?? The 'VerboseRecordCount' doesn't work anymore...
        08/10/2018 - Not checking to see if the VerboseRecordCount and/or WriteBatchSize logic is still an issue as described above.
                   - If GraphCreds are used in the GetAuthStringCmd (referencing the credential object) will the re-authentication work? This needs to be tested.
                   - Should I look at handling when a "Top=" is sent in? Currently if that top number is larger than the paging count you'll end up getting all records because the nextlink will just keep going...
        08/22/2018 - Should I change the skipCount URL format since it fails in some instances?? (mobileApps doesn't like "skiptoken=skipcount%d[x]" but rather "skip%3d[x]" or "skipCount=[x]")

    TO DO:
        04/23/2021 - [ ] Remove the UseSkipCounts/TopCount logic/variables since this is no longer a needed workaround.
                   - [ ] ? Update AuthStringCmd stuff for an object rather than a string?

#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true)][String]$OdataUrl
       ,[Parameter(Mandatory=$false,HelpMessage="This should be the command used to create the auth token - it needs to start with Get-Authentication")][String]$GetAuthStringCmd
       ,[Parameter(Mandatory=$false)][int64]$WriteBatchSize=50000
       ,[Parameter(Mandatory=$false)][int64]$CurNumRecords=0
       ,[Parameter(Mandatory=$false)][int]$VerboseRecordCount=0
       ,[Parameter(Mandatory=$false,ParameterSetName='UseSkipCounts')][int]$TopCount=100
       ,[Parameter(Mandatory=$false)][int]$ReconnRetryThreshold=3
       ,[Parameter(Mandatory=$false)][int]$GatewayTimeoutRetryThreshold=5
       ,[Parameter(Mandatory=$false)][int]$ServerUnavailableRetryThreshold=5
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    ## Make sure we have authenticated to AD/Graph already and if not try to:
    if (-Not $Global:ADAuthResult) {
        if ($GetAuthStringCmd) {
            Invoke-Expression $GetAuthStringCmd;
        }
        else {
            try {
                Get-Authentication -User "$env:USERNAME@$($env:USERDNSDOMAIN.Substring($env:USERDNSDOMAIN.LastIndexOf('.',$env:USERDNSDOMAIN.LastIndexOf('.')-1)+1).ToLower())"; # My best guess at the current user's UPN
            }
            catch {
                Write-CmTraceLog -LogMessage "No authentication context. Authenticate first by running 'Get-Authentication'" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;                
                throw "No authentication context. Authenticate first by running 'Get-Authentication'";
            }
        }
    }
    
    ## We need to build the URL we'll be using to get data from Graph:
    if ($PsCmdlet.ParameterSetName -eq 'UseSkipCounts' -and $OdataUrl -notlike '*skiptoken*') {
        # This handles instances when we hit the writebatchsize before all the records have been collected and a new call to this function is required to get the rest of the records...
        if ($OdataUrl.IndexOf('?') -eq -1) {        
            $URL = "$($OdataUrl)?`$top=$TopCount&`$skiptoken=skipCount%3d$CurNumRecords";
        }
        else { # don't add another '?' if it already has one...
            $URL = "$($OdataUrl)&`$top=$TopCount&`$skiptoken=skipCount%3d$CurNumRecords";
        }
    }
    else {
        # Otherwise, just use the URL that was passed in:
        $URL = $OdataUrl;
    }
    
    ## Variables to handle output:
    [int]$WriteCounter = 0;
    [int]$SkipCountNum = $CurNumRecords;
    
    ## Variables to handle retries:
    [int]$ReconnRetry = 0;
    [int]$GatewayTimeoutRetry = 0;
    [int]$ServerUnavailableRetry = 0;
    [int]$TimeoutRetry = 0;
    [int]$TimeoutRetryThreshold = 5;
    $RetriesOccurred = $false;

    ## Create the object we'll be storing data in:
    $JsonResponse = New-Object -TypeName System.Collections.ArrayList;
    
    ## We need to get data in loops in case the service is paging the results:
    while ($URL) {
        ## Create the header we'll use in the Invoke-RestMethod call:
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
        
        try {
            ## Determine whether we want to write to the host the current iteration's information or not...
            if (($isVerbose) -and ($GatewayTimeoutRetry -ne 0) -and ($ServerUnavailableRetry -ne 0) -and (($VerboseRecordCount -eq 0) -or ($WriteCounter -eq 0) -or ($TotalRecordsReceived -ge ($WriteCounter * $VerboseRecordCount)))) { # PrevIfLogic: (($VerboseInfo) -and (($VerboseRecordCount -eq 0) -or ($(if ($VerboseRecordCount -gt 0) {($CurNumRecords % $VerboseRecordCount -eq 0) -or ($CurNumRecords % $WriteBatchSize -eq 0)} else {$CurNumRecords -eq $VerboseRecordCount}))))
                Write-CmTraceLog -LogMessage "Getting Records Greater Than: $CurNumRecords | With a batch size of $($WriteBatchSize.ToString("###,###"))" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;
                # don't iterate $WriteCounter yet...
            }
            
            ## Make the rest call to get the data from Graph:
            $Response = Invoke-RestMethod -Uri $URL -Method Get -Headers $headers;
            
            ## Iterate the counts used in the logic:
            # if the service doesn't return a 'value' object then the properties returned are the object and we'll just set the record count to 1:
            if (Get-Member -InputObject $Response -Name value) {
                [int]$CurRecordsReceived = $Response.value.Count;  # current call's record count (if no records returned in 'value' then it will be 0)
            }
            else {
                #"'value' does not exist"
                [int]$CurRecordsReceived = 1;  # current call's record count
            }

            [int]$TotalRecordsReceived += $CurRecordsReceived; # current batch's record count
            $CurNumRecords += $CurRecordsReceived;             # total record count across all batches
            $SkipCountNum += $TopCount;                        # used to create the next URL if we're using skip counts
            
            ## Determine whether we need to write to the host the records received at this time or not; we'll iterate the WriteCounter when we do:
            if (($isVerbose) -and (($VerboseRecordCount -eq 0) <#-or ($WriteCounter -eq 0)#> -or ($(if ($WriteCounter -gt 0) {($TotalRecordsReceived -ge ($WriteCounter * $VerboseRecordCount))} else {$false})))) { # PrevIfLogic: (($VerboseInfo) -and (($VerboseRecordCount -eq 0) -or ($(if ($VerboseRecordCount -gt 0) {$CurNumRecords % $VerboseRecordCount -eq 0} else {$CurNumRecords -eq $VerboseRecordCount}))))
                Write-CmTraceLog -LogMessage "Records Received = $TotalRecordsReceived" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;
                ## iterate the write counter...
                $WriteCounter += 1;
            }

            ## if the service doesn't return a 'value' object then the properties are the 'value object':
            # for example userStatusOverview doesn't return a value but rather the the values whereas managedDevices returns a value object of the values/properties
            if (Get-Member -InputObject $Response -Name value) { # this is needed in the event that 'value' is returned but no records/objects/items exist in it!
                ## Add the items to the ArrayList (so that it is a true ArrayList):
                foreach ($itm in $Response.value) {
                    [void]$JsonResponse.Add($itm);
                }
                Remove-Variable -Name itm -ErrorAction SilentlyContinue;
            }
            else {
                ## Add the properties as one item/record in the ArrayList:
                $itm = New-Object -TypeName PSCustomObject;
                foreach ($prp in (Get-Member -InputObject $Response -MemberType NoteProperty).Name) {
                    $itm | Add-Member -MemberType NoteProperty -Name $prp -Value $($Response.$prp);
                }
                ## Add the record to the JsonResponse:
                [void]$JsonResponse.Add($itm);
                Remove-Variable -Name prp,itm -ErrorAction SilentlyContinue;
            }
    
            ## Create/Get the new URL:
            if ($PsCmdlet.ParameterSetName -eq 'UseSkipCounts') {
                ## Create the new URL - the SkipToken (or 'nextLink') - if we received records:
                if ($CurRecordsReceived -gt 0) { # Change to '-ge $TopCount' to account for when we've gotten all the records? Prob not necessary...
                    $URL = "$($URL.Substring(0,$URL.IndexOf('skipCount%3d')+12))$SkipCountNum";
                }
                else { # this will be the last iteration of the while loop since URL won't exist any longer:
                    $URL = $null;
                }
            }
            else {
                ## Get the new URL (if services have onboarded the service correctly the 'nextlink' will be there if there are more records to get):
                $URL = $Response.'@odata.nextLink';
            }
    
            ## If we successfully got here then we can safely reset the gateway timeout and server unavailable retry count...
            $GatewayTimeoutRetry = 0;
            $ServerUnavailableRetry = 0;
            $TimeoutRetry = 0;

            ## Check to see if we've hit the batch size:
             # the gt 0 records is in the event the URL returned 0 records; If so we don't want to hit this
            if ($TotalRecordsReceived -ge $WriteBatchSize -and $CurRecordsReceived -gt 0) { # PrevIfLogic: ($CurNumRecords % $WriteBatchSize -eq 0 -and $CurNumRecords -gt 0 -and $CurRecordsReceived -gt 0)
                if ($isVerbose) {
                    Write-CmTraceLog -LogMessage "We've hit the BatchSize so sending data back for processing..." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;
                }
                break; # stop the while loop and return the object to the caller for processing
            }
            
            ### Old logic for WriteBatchSize:
            #if ($TotalRecordsReceived % $WriteBatchSize -eq 0 -and $CurNumRecords -gt 0) { ## ($TotalRecordsReceived % $WriteBatchSize -eq 0 -and $CurNumRecords -gt 0) -or ($CurNumRecords % $WriteBatchSize -eq 0) # should use $CurRecordsReceived instead of $CurNumRecords???
            #    if ($VerboseInfo) {Write-Host "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : We've hit the Write BatchSize so sending data back for processing..." -ForegroundColor Cyan}
            #    break # stop the while loop and return the object to the caller for processing
            #}
        }
        catch [System.Net.WebException] { # For some reason some errors have ErrorDetails and sometimes they don't, so we use ErrorDetails and Exception to check:
            ## Check for authentication expiry issues:
            if ((($PSItem.ErrorDetails -like "*Access token has expired*") -eq $true) -or (($PSItem.Exception -like "*Access token has expired*") -eq $true) -or (($PSItem.ErrorDetails -like "*(401) Unauthorized*") -eq $true) -or (($PSItem.Exception -like "*(401) Unauthorized*") -eq $true)) {
                ## this reconnection retry stuff works because the URL is the same at this point and is retried when the loop continues on...
                $ReconnRetry += 1;
                #if ($isVerbose) {
                Write-CmTraceLog -LogMessage "We Need to Handle the timeout of the Access Token; Going to try to re-authenticate after 5 seconds..." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Warning -Verbose:$isVerbose;
                #}
                Start-Sleep -Seconds 5;
                ## Re-Authenticate to get a new access token:
                if ($GetAuthStringCmd) {
                    Invoke-Expression $GetAuthStringCmd;
                }
                else {
                    Get-Authentication -User "$env:USERNAME@microsoft.com"; # Should this be somehow dynamic to account for other companies/users?
                }
                # Check to see if we were able to authenticate but let's wait a few seconds first:
                Start-Sleep -Seconds 5;
                # if ExpiresOn exists then it is a user/app auth, if it's "expires_on" then it's MSI auth:
                if (    ($null -ne $Global:ADAuthResult.ExpiresOn -and ($Global:ADAuthResult.ExpiresOn.datetime - $((Get-Date).ToUniversalTime())).Minutes -ge 10) `
                    -or ($null -ne $Global:ADAuthResult.expires_on -and ([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Global:ADAuthResult.expires_on)) - (Get-Date)).Minutes -ge 10) `
                    ) {
                    $ReconnRetry = 0;
                    continue; # this continues the while loop...goes to the start of the while loop with the URL we just tried (same as not having it here really)
                }
                else {
                    if ($ReconnRetry -le $ReconnRetryThreshold) {
                        Write-CmTraceLog -LogMessage "Unable to get a new AccessToken will try again. Retry: $ReconnRetry of $ReconnRetryThreshold." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Warning -Verbose:$isVerbose;
                        # don't do anything so it tries again...no explicit retry of the connection but the URL is the same and will try again in the loop...
                        continue; # this continues the while loop...goes to the start of the while loop with the URL we just tried (same as not having it here really)
                    }
                    else {
                        $CatchEndLoop = $true;
                        [string]$ReturnErrorInfo = "Unable to get a new AccessToken for the last number of retries ($ReconnRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                        Write-CmTraceLog -LogMessage "Unable to get a new AccessToken for the last number of retries ($ReconnRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                        break; # this breaks out of the while loop
                    }
                }
            } #End AccessToken Expiration if block
            ## If not expiry, check for known errors and handle appropriately:
            elseif (($PSItem.Exception -like "*(504) Gateway Timeout*") -eq $true) {
                ## iterate the gateway timeout counter since we'll retry on this error a few times:
                $GatewayTimeoutRetry += 1;
                $RetriesOccurred = $true;
                if ($GatewayTimeoutRetry -le $GatewayTimeoutRetryThreshold) {
                    # this retry works because the URL is the same at this point and is retried when the loop continues on...
                    Write-CmTraceLog -LogMessage "Gateway Timed out! (Records Received thus far: $(if (-Not $TotalRecordsReceived) {"0"} else {$TotalRecordsReceived})); will try again. Retry: $GatewayTimeoutRetry of $GatewayTimeoutRetryThreshold." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Warning -Verbose:$isVerbose;
                    continue; # this continues the while loop...goes to the start of the while loop with the URL we just tried (same as not having it here really)
                }
                else {
                    $CatchEndLoop = $true;
                    [string]$ReturnErrorInfo = "Gateway Timed out for the last number of retries ($GatewayTimeoutRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-CmTraceLog -LogMessage "Gateway Timed out for the last number of retries ($GatewayTimeoutRetryThreshold); returning to caller." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                    break; # this breaks out of the while loop
                }
            } #End: Gateway Timeout error catch
            elseif (($PSItem.Exception -like "*(503) Server Unavailable*") -eq $true) {
                ## iterate the server unavailable counter since we'll retry on this error a few times:
                $ServerUnavailableRetry += 1;
                $RetriesOccurred = $true;
                if ($ServerUnavailableRetry -le $ServerUnavailableRetryThreshold) {
                    # this retry works because the URL is the same at this point and is retried when the loop continues on...
                    Write-CmTraceLog -LogMessage "Server Unavailable! (Records Received thus far: $(if (-Not $TotalRecordsReceived) {"0"} else {$TotalRecordsReceived})); will try again in 5 minutes. Retry: $ServerUnavailableRetry of $ServerUnavailableRetryThreshold." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Warning -Verbose:$isVerbose;
                    Start-Sleep -Seconds 300;
                    continue; # this continues the while loop...goes to the start of the while loop with the URL we just tried (same as not having it here really)
                }
                else {
                    $CatchEndLoop = $true;
                    [string]$ReturnErrorInfo = "Server Unavailable for the last number of retries ($ServerUnavailableRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-CmTraceLog -LogMessage "Server Unavailable for the last number of retries ($ServerUnavailableRetryThreshold); returning to caller." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                    break; # this breaks out of the while loop
                }
            } #End: Server Unavailable error catch
            elseif (($PSItem.Exception -like "*(400) Bad Request*") -eq $true) {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Bad Request Error Caught; Better check the URL you tried to use! Will return to caller.`r`nBad Request URL: $URL`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-CmTraceLog -LogMessage "Bad Request Error Caught; Better check the URL you tried to use! Will return to caller.`r`nBad Request URL: $URL`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                break; # this breaks out of the while loop
            } #End: Bad Request error catch
            elseif (($PSItem.Exception -like "*(403) Forbidden*") -eq $true) {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Forbidden Error Caught; will return to caller.`r`nForbidden URL (need to get access to this resource): $URL`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-CmTraceLog -LogMessage "Forbidden Error Caught; will return to caller.`r`nForbidden URL (need to get access to this resource): $URL`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                break; # this breaks out of the while loop
            } #End: Forbidden URL error catch
            elseif (($PSItem.Exception -like "*(500) Internal Server Error*") -eq $true) {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Internal Server Error Caught; not sure what this is but it seems bad. Will return to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-CmTraceLog -LogMessage "Internal Server Error Caught; not sure what this is but it seems bad. Will return to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                break; # this breaks out of the while loop
            } #End: Internal Server Error catch
            elseif (($PSItem.Exception -like "*The operation has timed out*") -eq $true) {
                ## iterate the timeout retry counter since we'll retry on this error a few times:
                $TimeoutRetry += 1;
                $RetriesOccurred = $true;
                if ($TimeoutRetry -le $TimeoutRetryThreshold) {
                    # this retry works because the URL is the same at this point and is retried when the loop continues on...
                    Write-CmTraceLog -LogMessage "Operation Timeout Occurred! (Records Received thus far: $(if (-Not $TotalRecordsReceived) {"0"} else {$TotalRecordsReceived})); will try again in 1 minute. Retry: $TimeoutRetry of $TimeoutRetryThreshold." -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Warning -Verbose:$isVerbose;
                    Start-Sleep -Seconds 60;
                    continue; # this continues the while loop...goes to the start of the while loop with the URL we just tried (same as not having it here really)
                }
                else {
                    $CatchEndLoop = $true;
                    [string]$ReturnErrorInfo = "Operation Timeout Occurred for the last number of retries ($TimeoutRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                    Write-CmTraceLog -LogMessage "Operation Timeout Occurred for the last number of retries ($TimeoutRetryThreshold); returning to caller.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                    break; # this breaks out of the while loop
                }
            } #End: Operation Timeout error catch
            else {
                $CatchEndLoop = $true;
                [string]$ReturnErrorInfo = "Unhandled WebException Error Encountered.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
                Write-CmTraceLog -LogMessage "Unhandled WebException Error Encountered.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
                break; # this breaks out of the while loop
            } #End: unhandled error catch
        } # End Catch WebException block
        catch { # Catch any other type of exception here (shouldn't ever get here but just in case):
            $CatchEndLoop = $true;
            [string]$ReturnErrorInfo = "Unhandled Error Encountered.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())";
            Write-CmTraceLog -LogMessage "Unhandled Error Encountered.`r`nFull Error Information:`r`n$($PSItem.Exception.ToString())" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -MessageType Error -Verbose:$isVerbose;
            break; # this breaks out of the while loop
        } # End Catch 'all other exceptions' block
    } # End While Loop
    
    if (-Not $TotalRecordsReceived) {
        $TotalRecordsReceived = 0;
    }
    
    ## URL doesn't exist (we got all data), we've hit the WriteBatchSize, OR we caught an error in the catch block so...
     # Create the return object and return it:
    if ($CatchEndLoop) { # We broke the loop due to exceptions
        #if ($VerboseInfo) {
        #    Write-Host "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Records Received (before error encountered): Total Count = $CurNumRecords ; Batch Count = $TotalRecordsReceived" -ForegroundColor Cyan;
            Write-CmTraceLog -LogMessage "Records Received (before error encountered): Total Count = $CurNumRecords ; Batch Count = $TotalRecordsReceived" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;
        #}
        if ($JsonResponse.Count -gt 0) {
            $ReturnObj = New-Object -TypeName PSObject -Property @{"DataObject"=$JsonResponse;"URL"=$URL;"RecordCount"=$CurNumRecords;"BatchRecordCount"=$TotalRecordsReceived;"ErrorCaught"="true";"RetriesOccurred"=$RetriesOccurred;"ErrorMessage"=$ReturnErrorInfo}; # use $true instead of string?
        }
        else {
            $ReturnObj = New-Object -TypeName PSObject -Property @{"URL"=$URL;"RecordCount"=$CurNumRecords;"BatchRecordCount"=$TotalRecordsReceived;"ErrorCaught"="true";"RetriesOccurred"=$RetriesOccurred;"ErrorMessage"=$ReturnErrorInfo}; # use $true instead of string?
        }
    }
    else { # No break used in the catch block: We got all data or hit the WriteBatchSize (hopefully) :)
        #if ($VerboseInfo) {
            Write-CmTraceLog -LogMessage "Records Received: Total Count = $CurNumRecords ; Batch Count = $TotalRecordsReceived" -LogFullPath $LogFullPath -Component 'Get-IntuneOpStoreData' -Verbose:$isVerbose;
        #}
        $ReturnObj = New-Object -TypeName PSObject -Property @{"DataObject"=$JsonResponse;"URL"=$URL;"RecordCount"=$CurNumRecords;"BatchRecordCount"=$TotalRecordsReceived;"ErrorCaught"="false";"RetriesOccurred"=$RetriesOccurred}; # use $false instead of string?
    }

    ## Return the object:
    return $ReturnObj;

    ## Cleanup?

} #End: Get-IntuneOpStoreData
