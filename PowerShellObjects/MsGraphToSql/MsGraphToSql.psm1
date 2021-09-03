<#

Version History/Notes:
Date          Version    Author                    Notes
2017 - 2021   0.0 - 1.9  Benjamin Reynolds         Initial Creation; numerous and various changes done but no history recorded.
05/10/2021    2.0        Benjamin Reynolds         Module split from one file and renamed to "MsGraphToSql".

#>

#Requires -Version 5.0

# dot source each of the functions in the folders:
foreach ($directory in @('Private', 'Public'))
{
    foreach ($fncName in (Get-ChildItem -Path "$PSScriptRoot\$directory\*.ps1").FullName)
    {
        . $fncName;
    }
}
