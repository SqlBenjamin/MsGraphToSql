# Get-GraphMetaData
function Get-GraphMetaData {
<#
.SYNOPSIS
    This function creates global variables of Graph Meta Data for use in other funtions.
.DESCRIPTION
    The function will get the $metadata from Graph for the version passed in and create global variables for
    MetaData, Enums, and Entities. These global variables have the format: MetaData_[version], Enums_[version], Entities_[version]
.PARAMETER Version
    This is the version of Graph for which the MetaData should be obtained and from which the variables created.
.EXAMPLE
    Get-GraphMetaData -Version 'v1.0'
    This creates the global variable MetaData_v1dot0 which contains the entire $metadata from version v1.0, and the variables "Enums_v1dot0" and "Entities_v1dot0" which
    contain these elements from the metadata.
.NOTES
    NAME: Get-GraphMetaData
    HISTORY:
        Date              Author                    Notes
        06/22/2018        Benjamin Reynolds         Created based on an earlier version of the function named "Get-OperationalStoreMetaData"
        09/11/2018        Benjamin Reynolds         Added Variable Check before trying to create them.
        09/02/2020        Benjamin Reynolds         Added Variable "BaseUrl" to account for changes in Authentication/SchemaVersions.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][String]$Version
       ,[Parameter(Mandatory=$false)][Alias("Audience")][String]$BaseUrl = 'https://graph.microsoft.com'
    )

    # Create the VersionClean based on the Version provided:
    [String]$VersionClean = $Version.Replace('.','dot');
    # Remove the trailing "/" if it exists:
    if ($BaseUrl.EndsWith('/'))
    {
        $BaseUrl = $BaseUrl.Substring(0,$BaseUrl.Length-1);
    }
        
    # Create the version specific global MetaData variable:
    if (-not (Get-Variable -Name "MetaData_$VersionClean" -ErrorAction SilentlyContinue)) {
        New-Variable -Name "MetaData_$VersionClean" -Scope Global -Value (Invoke-RestMethod -Uri "$BaseUrl/$Version/`$metadata" -Method Get).Edmx.DataServices.Schema
    }
    else {
        Write-Verbose "Global Variable 'MetaData_$VersionClean' already exists; will continue to use existing variable.";
    }

    # Create the version specific objects for the different types that will be used:
    if (-not (Get-Variable -Name "Enums_$VersionClean" -ErrorAction SilentlyContinue)) {
        New-Variable -Name "Enums_$VersionClean" -Scope Global -Value (Get-EntityTypeMetaData -EntityName "Enums" -Version $Version)
        #foreach ($enm in $a) {
        #    $MaxLen = (($enm.Member).Name | Measure-Object -Maximum -Property Length).Maximum;
        #    Add-Member -InputObject $enm -MemberType NoteProperty -Name MaxLength -Value $MaxLen -Force;
        #}
    }
    else {
        Write-Verbose "Global Variable 'Enums_$VersionClean' already exists; will continue to use existing variable.";
    }
    if (-not (Get-Variable -Name "Entities_$VersionClean" -ErrorAction SilentlyContinue)) {
        New-Variable -Name "Entities_$VersionClean" -Scope Global -Value (Get-EntityTypeMetaData -EntityName "EntityTypes" -Version $Version)
    }
    else {
        Write-Verbose "Global Variable 'Entities_$VersionClean' already exists; will continue to use existing variable.";
    }
    # ComplexTypes, Singletons, etc???

} # End: Get-GraphMetaData
