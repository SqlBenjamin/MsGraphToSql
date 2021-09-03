# Test-ADAssembliesLoaded
function Test-ADAssembliesLoaded {
<#
.SYNOPSIS
    This function is used to test whether the ADAL assemblies are loaded.
.DESCRIPTION
    The function will return true/false based on whether the assemblies are found to be currently loaded.
.EXAMPLE
    Test-ADAssembliesLoaded
.NOTES
    NAME: Test-ADAssembliesLoaded
    HISTORY:
        Date                Author                    Notes:
        07/19/2018          Benjamin Reynolds         Initial Creation
#>

    $AssembliesFound = New-Object System.Collections.ArrayList;

    $LoadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies();
    foreach ($Assembly in $LoadedAssemblies) {
        [String]$AssemblyName = ($Assembly.FullName -split ',')[0];
        if (($AssemblyName -eq 'Microsoft.IdentityModel.Clients.ActiveDirectory') -or ($AssemblyName -eq 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform')) {
            [void]$AssembliesFound.Add($AssemblyName)
        }
    }

    if (($AssembliesFound | Group-Object).Count -eq 2) { # is there a better way to do this; meaning get the unique items without using a pipe?
        return $true;
    }
    else {
        return $false
    }
} # End: Test-ADAssembliesLoaded
