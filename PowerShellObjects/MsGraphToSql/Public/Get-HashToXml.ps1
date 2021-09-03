# Get-HashToXml
function Get-HashToXml {
<#
.SYNOPSIS
    This function creates an xml fragment (as a string) from the provided hashtable/dictionary.
.DESCRIPTION
    The function will create a properly formatted xml fragment which will be used in the log table.
.PARAMETER HashOrDictionary
    This must be either a hashtable or a dictionary (i.e., OrderedDictionary).
    The key value pairs will contain the columns to update with the values to update with.
.PARAMETER CreateRootXml
    When this is the only or first time the ExtendedInfo is inserted/updated to the table it should be wrapped in "<SpecificURLs></SpecificURLs>".
.EXAMPLE
    Get-HashToXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{ReportName = 'MyReport';UriVersion = 'beta';Select = '';Filter = "blah eq '1234'"};SelectStartDateTimeUTC = '2021-03-15T23:27:33.516'});
    This will return the string: <SpecificURL ReportName="MyReport" UriVersion="beta" Filter="blah eq '1234'"><SelectStartDateTimeUTC>2021-03-15T23:27:33.516</SelectStartDateTimeUTC></SpecificURL>
.EXAMPLE
    Get-HashToXml -CreateRootXml -HashOrDictionary $([ordered]@{SpecificURL = [ordered]@{ReportName = 'MyReport';UriVersion = 'beta';Select = '';Filter = "blah eq '1234'"};SelectStartDateTimeUTC = '2021-03-15T23:27:33.516'});
    This will return the string: <SpecificURLs><SpecificURL ReportName="MyReport" UriVersion="beta" Filter="blah eq '1234'"><SelectStartDateTimeUTC>2021-03-15T23:27:33.516</SelectStartDateTimeUTC></SpecificURL></SpecificURLs>
.NOTES
    NAME: Get-HashToXml
    HISTORY:
        Date                Author                    Notes
        03/10/2021          Benjamin Reynolds         Initial Creation
        04/13/2021          Benjamin Reynolds         Added logic to check for value type to avoid using the "Replace" method on types that don't have that method.

    NOTES:
        - The string values should not come with the single quotes escaped; if the valus is "this isn't right" it should come in that way not as "this isn''t right".
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({$PSItem.GetType().Name -like '*Dictionary*' -or $PSItem.GetType().Name -like '*Hashtable*'})]$HashOrDictionary
       ,[Parameter(Mandatory=$false)][switch]$CreateRootXml
    )
    
    [string]$xmlOut = "";
    $isSpecUrl = $false;

    foreach ($xmlVal in $HashOrDictionary.GetEnumerator())
    {
        $Key = $xmlVal.Key;
        $Value = $xmlVal.Value;
        
        if ($Key -eq 'SpecificURL')
        {
            $xmlOut += "<$($Key)";
            $xmlOut += Get-HashToXmlAttributes -HashOrDictionary $Value;
            $xmlOut += ">";
            $isSpecUrl = $true;
        }
        elseif (-Not ([String]::IsNullOrWhiteSpace($Value)) -and ($Value.GetType().Name -like '*Dictionary*' -or $Value.GetType().Name -like '*Hashtable*'))
        {
            $xmlOut += "<$($Key)>";
            $xmlOut += Get-HashToXml -HashOrDictionary $Value;
            $xmlOut += "</$($Key)>";
        }
        elseif (-Not ([String]::IsNullOrWhiteSpace($Value)))
        {
            if ($Value.GetType().Name -eq 'String')
            {
                $xmlOut += "<$($Key)>$($Value.Replace("'","''").Replace('&','&amp;'))</$($Key)>";
            }
            else
            {
                $xmlOut += "<$($Key)>$Value</$($Key)>";
            }
            
        }
    }

    if ($isSpecUrl)
    {
        $xmlOut += "</SpecificURL>";
    }

    if ($CreateRootXml)
    {
        $xmlOut = "<SpecificURLs>$xmlOut</SpecificURLs>";
    }
    
    return $xmlOut;
} # End: Get-HashToXml
