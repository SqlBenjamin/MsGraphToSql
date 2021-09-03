# Clear-Authentication
function Clear-Authentication {
<#
.SYNOPSIS
    This function removes the global variables created by Get-Authentication. 
.DESCRIPTION
    The function is kinda stupid, but I added it anyway.
.EXAMPLE
    Clear-Authentication
.NOTES
    NAME: Clear-Authentication
    HISTORY:
        Date              Author                    Notes
        03/14/18          Benjamin Reynolds
#>

Remove-Variable -Scope Global -Name ADAuthResult <#,ADAuthUser,OpStoreURL#> -ErrorAction SilentlyContinue;

} #End: Clear-Authentication
