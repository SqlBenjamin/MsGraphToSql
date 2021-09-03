# Get-UrlsToSync
function Get-UrlsToSync {
<#
.SYNOPSIS
    This function is used to create an ArrayList of hashtables from either a file or string representing the hashtable(s) to use in the "Tables To Sync".
.DESCRIPTION
    The function converts strings representing hashtables into an ArrayList of hashtables, which is used to know what and how to sync data from Graph to SQL.
    The format of the "line" (either in the file or string) should have at least one key/value pair and each key/value pair is separated by a semicolon. The
    key/value pair is defined in this manner: "Key Name" = "Value". The key and value must be enclosed in double quotes, the key on the left side of an equal
    sign, and the value on the right side of the equal sign. Note, a "Value" can also be a hashtable (nested) but needs to start with "@{" and end with "}".
    The hashtable string for a line/string can simply follow the definition above or can also look like it would if creating an array of hashtables in PowerShell.
    For example, the following two lines are essentially the same (and display valid syntax):
    "KeyOne" = "ValueOne"; "KeyTwo" = "ValueTwo"; "SubHashKey" = @{"SubKeyOne" = "SubValueOne"; "SubKeyTwo" = "SubValueTwo"}
    ,@{"KeyOne" = "ValueOne"; "KeyTwo" = "ValueTwo"; "SubHashKey" = @{"SubKeyOne" = "SubValueOne"; "SubKeyTwo" = "SubValueTwo"}}
    In addition any lines commented out with PowerShell comments are ignored.
.PARAMETER Path
    This is the path to the file containing the inforamtion to convert.
.PARAMETER HashString
    This is a string representing the information to convert (rather than a file).
.PARAMETER HasHeaderRow
    If "Path" is used and the first line in the file should not be used then passing this in will ignore/skip the first line.
.EXAMPLE
    Get-UrlsToSync -HashString '@{"UriPart" = "deviceManagement/managedDevices"; "Version" = "v1.0"}';
    This creates a Hashtable with the keys "UriPart" and "Version" and assigns their value pairs. This hashtable is added to an ArrayList which is returned.
.EXAMPLE
    Get-UrlsToSync -HashString '@{"UriPart" = "deviceManagement/managedDevices"; "Version" = "v1.0"} `r`n ,@{"UriPart" = "deviceAppManagement/mobileApps"; "Version" = "v1.0"; "ExpandColumns" = "assignments"; "ExpandTableOrColumn" = "Both"}';
    This creates two Hashtables with the key/value pairs. Each hashtable is added to the ArrayList which is returned.
.EXAMPLE
    Get-UrlsToSync -Path 'c:\MyTextFile.txt';
    This creates a Hashtable for each line in the file "MyTextFile.txt". Each hashtable is created with the key/value pair defined in the line and is added to an ArrayList which is returned.
.EXAMPLE
    Get-UrlsToSync -Path 'c:\MyTextFile.txt' -HasHeaderRow;
    This creates a Hashtable for each line in the file "MyTextFile.txt" except for the first (or header) line/row. Each hashtable is created with the key/value pair defined in the line and is added to an ArrayList which is returned.
.NOTES
    NAME: Get-UrlsToSync
    HISTORY:
        Date                Author                    Notes:
        09/27/2018          Benjamin Reynolds         Initial Creation.
        10/01/2018          Benjamin Reynolds         Added some comment checking/removal logic.
        10/10/2018          Benjamin Reynolds         Added max substring to split functions in order to properly handle when multiple
                                                      equal signs exist in a key/value pair. Example: "UriPart" = "deviceManagement/deviceManagementScripts/{id}/deviceRunStates?$expand=managedDevice($select=id)"
        01/24/2019          Benjamin Reynolds         Added removal of escape characters (backtick) for the dollar sign. `$ turns into $.
#>

    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName='ItemsFromFile')][string]$Path
       ,[Parameter(Mandatory=$true,ParameterSetName='ItemsFromString')][string]$HashString
       ,[Parameter(Mandatory=$false,ParameterSetName='ItemsFromFile')][switch]$HasHeaderRow
    )

    ## Get the information we need to build the Array of Hashtables:
    if ($PsCmdlet.ParameterSetName -eq 'ItemsFromFile') {
        ## Get the content from the path provided:
        [System.Collections.ArrayList]$FileContent = Get-Content -Path $Path;

        ## If there's a header row then remove it from the list of items:
        if ($HasHeaderRow) {
            $FileContent.RemoveAt(0);
        }
    }
    else {
        ## Just use the string that was passed in rather than get it from a file:
        $FileContent = New-Object -TypeName System.Collections.ArrayList;
        ## We'll split the string on return/linefeed and add each of those items as a separate line:
        foreach ($line in $HashString.Split("`r`n")) {
            [void]$FileContent.Add($line);
        }
        Remove-Variable -Name line -ErrorAction SilentlyContinue;
    }
    Remove-Variable -Name Path,HasHeaderRow,HashString -ErrorAction SilentlyContinue;

    ## Create an ArrayList for helping with cleanup to be taken care of next:
    $CmtdOut = New-Object -TypeName System.Collections.ArrayList;
    
    ## Cleanup the items in case the file was formatted like: '@{"Key" = "Value";}' since we expect it to be like: 'Key = Value;'
    for ($i = 0; $i -lt $FileContent.Count; $i++) {
        ## Remove the quotation marks and backticks escaping the dollar signs from the string as well as any leading/trailing spaces:
        $FileContent[$i] = $FileContent[$i].Replace('"','').Replace('`$','$').Trim();
        
        ## Record the lines that we need to remove later (because they're commented out or are blank). They can't be removed now or the index numbers will be messed up...unless we did the array in reverse order...:
        # Handle any blank lines:
        if ($FileContent[$i] -eq '') {
            [void]$CmtdOut.Add($i);
            continue;
        }
        # Handle commented out lines (those that start with # or <#):
        if ($FileContent[$i].IndexOf('#') -eq 0 -and $FileContent[$i].IndexOf('#>') -ne 0) {
            [void]$CmtdOut.Add($i);
            continue;
        }
        elseif ($FileContent[$i].IndexOf('<#') -eq 0) {
            [void]$CmtdOut.Add($i);
            continue;
        }
        
        ## Remove any/all '<#'/'#>' commented portions in case they exist:
        if ($FileContent[$i].IndexOf('<#') -gt 0) {
            while ($FileContent[$i].Length - ($FileContent[$i].Replace('<#','').Length) -gt 0) {
                ## creating multiple variables for readability...
                $CmtStrt = $FileContent[$i].IndexOf('<#');
                $CmtEnd = $FileContent[$i].IndexOf('#>',$CmtStrt)+2;
                $Cmt = $FileContent[$i].Substring($CmtStrt,($CmtEnd-$CmtStrt));
                $FileContent[$i] = $FileContent[$i].Replace($Cmt,'').Trim();
                Remove-Variable -Name CmtStrt,CmtEnd,Cmt -ErrorAction SilentlyContinue;
                
            } #end while 'comment' cleanup
        }

        ## Remove any trailing comment (block comments have been removed so if theres just a hashtag let's remove everything that comes after it):
        if ($FileContent[$i].IndexOf('#') -ne -1) {
            $FileContent[$i] = $FileContent[$i].Substring(0,$FileContent[$i].IndexOf('#')).Trim()
        }
        
        ## Remove any surrounding '@{}' or ',@{}' for any line that may have it:
        if ($FileContent[$i].IndexOf('@{') -le 1 -and $FileContent[$i].IndexOf('@{') -ne -1) { # since there can be 'sub hash tables' we only want to strip these when it's at the beginning of the string
            $FileContent[$i] = $FileContent[$i].Substring($FileContent[$i].IndexOf('@{')+2,$FileContent[$i].Length - ($FileContent[$i].IndexOf('@{')+3));
        }
    }
    Remove-Variable -Name i -ErrorAction SilentlyContinue;

    ## Actually remove the items that were commented out (which were recorded earlier):
    if ($CmtdOut.Count -gt 0) {
        ## we have to sort and reverse the array to make sure we remove the lines in reverse order so that the indexing doesn't get messed up and we remove the wrong lines...
        $CmtdOut.Sort();
        $CmtdOut.Reverse();
        foreach ($i in $CmtdOut) {
            $FileContent.RemoveAt($i);
        }
        Remove-Variable -Name i -ErrorAction SilentlyContinue;
    }
    Remove-Variable -Name CmtdOut -ErrorAction SilentlyContinue;

    ## Create the return object:
    $ReturnObj = New-Object -TypeName System.Collections.ArrayList;

    ## Dynamically build a hashtable for each line in the content and add it to the return object:
    foreach ($itm in $FileContent) {
        ## Create the working variables we'll use in the loop:
        $Hashtbl = New-Object -TypeName System.Collections.Hashtable;
        $SubHashes = New-Object -TypeName System.Collections.ArrayList;
        
        ## Dynamically pull out any "sub" hashtables:
        while ($itm.Length - ($itm.Replace('@{','').Length) -gt 0) {
            $AtSymbolStart = $itm.IndexOf('@{');
            $StartOfKvpHash = $itm.LastIndexOf(';',$AtSymbolStart);
            $EndOfKvpHash = $itm.IndexOf('}',$AtSymbolStart)+1;
            $SubHashKvp = $itm.Substring($StartOfKvpHash,($EndOfKvpHash-$StartOfKvpHash));
            [void]$SubHashes.Add($SubHashKvp.Substring(1).Trim());
            $itm = $itm.Replace($SubHashKvp,'');
            Remove-Variable -Name AtSymbolStart,StartOfKvpHash,EndOfKvpHash,SubHashKvp -ErrorAction SilentlyContinue;
        }

        ## Add all the Key Value Pairs for the record into a hashtable:
        foreach ($kvp in ($itm -split ';')) {
            if ($kvp.Length -le 0) {continue;} # in case the kvp is empty
            $tmpKvp = $kvp -split '=',2;
            $Hashtbl.Add($tmpKvp[0].Trim(),$tmpKvp[1].Trim());
            Remove-Variable -Name tmpKvp -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name kvp;
    
        ## Add all the Key Value Pairs for any "Sub Hashtables" into the same hashtable:
        foreach ($SubHash in $SubHashes) {
            ## Separate the hashtable value from the key:
            $SubHashVal = $SubHash.Substring($SubHash.IndexOf('@{')).Replace('@{','').Replace('}','').Trim();
            $SubHashKey = $SubHash.Substring(0,$SubHash.IndexOf('=')).Trim();
            
            ## Create a hashtable for this 'sub' hashtable:
            $SubHashtbl = New-Object -TypeName System.Collections.Hashtable;
            
            ## Add the key/values into the sub hashtable:
            foreach ($hsh in ($SubHashVal -split ';')) {
                $tmpKvp = $hsh -split '=',2;
                $SubHashtbl.Add($tmpKvp[0].Trim(),$tmpKvp[1].Trim());
                Remove-Variable -Name tmpKvp -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name hsh -ErrorAction SilentlyContinue;
            
            ## Now add this hashtable as the value for the key/property:
            $Hashtbl.Add($SubHashKey,$SubHashtbl);
            Remove-Variable -Name SubHashVal,SubHashKey,SubHashtbl -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name SubHash,SubHashes -ErrorAction SilentlyContinue;

        ## Now add the current hashtable for the record to the return object:
        [void]$ReturnObj.Add($Hashtbl);

        Remove-Variable -Name Hashtbl -ErrorAction SilentlyContinue;
    }
    Remove-Variable -Name itm,FileContent -ErrorAction SilentlyContinue;

    ## Return the object (either an Array or ArrayList):
    return $ReturnObj;

} # End: Get-UrlsToSync
