# Get-HashToXmlAttributes
function Get-HashToXmlAttributes {
<#
.SYNOPSIS
    This function creates xml attributes (as a string) from the provided hashtable/dictionary.
.DESCRIPTION
    The function will create an xml attribute string to be used in a xml fragment.
.PARAMETER HashOrDictionary
    This must be either a hashtable or a dictionary (i.e., OrderedDictionary).
    The key value pairs will contain the attributes which will be parsed into a string:
    Name or attribute = key; Value of attribute = value; Ex: ReportName = 'MyReport' --> ' ReportName="MyReport"'
.EXAMPLE
    Get-HashToXmlAttributes -HashOrDictionary [ordered]@{ReportName = 'MyReport';UriVersion = 'beta';Select = '';Filter = "blah eq '1234'"}
    This will return the string: ReportName='MyReport' UriVersion='beta' Filter="blah eq '1234'""
.NOTES
    NAME: Get-HashToXmlAttributes
    HISTORY:
        Date                Author                    Notes:
        03/10/2021          Benjamin Reynolds         Initial Creation
        04/13/2021          Benjamin Reynolds         Added logic to check for value type to avoid using the "Replace" method on types that don't have that method.
        06/11/2021          Benjamin Reynolds         Fixed issue with items not properly going into the string type logic.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({$PSItem.GetType().Name -like '*Dictionary*' -or $PSItem.GetType().Name -like '*Hashtable*'})]$HashOrDictionary
    )
    
    [string]$xmlOut = "";

    foreach ($xmlVal in $HashOrDictionary.GetEnumerator())
    {
        $k = $xmlVal.Key;
        $v = $xmlVal.Value;

        if (-Not ([String]::IsNullOrWhiteSpace($v)))
        {
            if ($v.GetType().Name -eq 'String')
            {
                $xmlOut += " $($k)=""$($v.Replace("'","''").Replace('&','&amp;'))""";
            }
            else
            {
                $xmlOut += " $($k)=""$($v)""";
            }
        }
    }
    
    return $xmlOut;
} # End: Get-HashToXmlAttributes
