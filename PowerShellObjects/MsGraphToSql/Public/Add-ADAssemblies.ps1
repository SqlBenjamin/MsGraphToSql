# Add-ADAssemblies
function Add-ADAssemblies {
<#
.SYNOPSIS
    This function loads the ADAL assemblies which are needed to connect to Graph.
.DESCRIPTION
    The environment is checked to see if the AzureAD module is available. If more than
    one version is available then the most recent version is used when loading.
.EXAMPLE
    Add-ADAssemblies
.NOTES
    NAME: Add-ADAssemblies
    HISTORY:
        Date                Author                    Notes
        07/19/2018          Benjamin Reynolds         Initial Creation
#>
    
    ## Find and import the AzureAD cmdlets so that we can make the connection:
    # Find the AzureAD cmdlets that can be used for authentication.
    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {
        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    }

    if ($AadModule -eq $null) {
        throw "AzureAD Powershell module not installed...Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt"
    }

    # Getting path to Active Directory Assemblies
    # If the module count is greater than 1 find the latest version
    if ($AadModule.count -gt 1) {

        # I know that pipes are evil but this is easy and fast enough not to optimize for now...
        $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
        $AadModule = $AadModule | Where-Object {$_.version -eq $Latest_Version.version}

        # Checking if there are multiple versions of the same module found
        if ($AadModule.count -gt 1) {
            $aadModule = $AadModule | Select-Object -Unique
        }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }
    else { # there's only one module to worry about
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }

    # Load the assemblies
    $null = [System.Reflection.Assembly]::LoadFrom($adal)
    $null = [System.Reflection.Assembly]::LoadFrom($adalforms)
    ## end of finding and importing AzureAD cmdlets

} # End: Add-ADAssemblies
