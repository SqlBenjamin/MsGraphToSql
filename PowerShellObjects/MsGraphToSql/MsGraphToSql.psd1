<#
Version History/Notes:
Date          Version    Author                    Notes
05/10/2021    2.0        Benjamin Reynolds         Module split from one file; manifest created.
#>

@{

# Script module or binary module file associated with this manifest.
RootModule = 'MsGraphToSql.psm1'

# Version number of this module.
ModuleVersion = '2.0.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '4761b688-e0d5-485c-a4e7-e66f592cec71'

# Author of this module
Author = 'Benjamin Reynolds'

# Company or vendor of this module
CompanyName = 'Microsoft Internal'

# Copyright statement for this module
Copyright = '(c) 2021 All rights reserved.'

# Description of the functionality provided by this module
Description = ''

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
<##
# Get all "FunctionsToExport":
foreach ($fncName in (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").Name)
{
    ",'$($fncName.Replace('.ps1',''))'";
}
##>
FunctionsToExport = @(
     'Add-ADAssemblies'
    ,'Clear-Authentication'
    ,'ConvertTo-DataTable'
    ,'Get-Authentication'
    ,'Get-CollectionEntity'
    ,'Get-ColumnDefinitionsAndCompare'
    ,'Get-ColumnDefWithInheritedProps'
    ,'Get-ColumnMapping'
    ,'Get-ExpandedColDefWithInheritedProps'
    ,'Get-GraphMetaData'
    ,'Get-HashToXml'
    ,'Get-IntuneOpStoreData'
    ,'Get-ReportExportResponse'
    ,'Get-SqlTableColumnDefinition'
    ,'Get-SqlTableCreateStatementFromUrl'
    ,'Get-UrlsToSync'
    ,'Get-UrlsToSyncFromSql'
    ,'Import-SqlTableData'
    ,'Invoke-SqlCommand'
    ,'Invoke-SqlTruncate'
    ,'Set-LogToSqlCommand'
    ,'Test-ADAssembliesLoaded'
    ,'Write-CmTraceLog'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
<##
# Get all "AliasesToExport":
$AliasesToExport = New-Object -TypeName System.Collections.Hashtable;
foreach ($fnc in (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"))
{
    $fncText = Get-Content $fnc.FullName -Raw;

    foreach ($match in [regex]::Matches($fncText,'(?<=\[Alias\()(.*)(?=\)\])',[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture))
    {
        foreach ($alias in ($match.Value) -split ',')
        {
            if (!$AliasesToExport.ContainsKey($alias))
            {
                $a = $alias.Replace('"','').Replace("'","");
                $AliasesToExport.Add($alias,",'$a'");
            }
        }
    }
}
$AliasesToExport.Values;
     'ReturnAllColsAndRows'
    ,'SqlCreds'
    ,'DataTable'
    ,'ColumnMappingArrayList'
    ,'DatabaseName'
    ,'SqlServer'
    ,'SqlSchemaName'
    ,'BaseURL'
    ,'Database'
    ,'UseReader'
    ,'TableName'
    ,'Audience'
    ,'Authority'
    ,'MetaDataVersion'
    ,'SqlTableName'
    ,'ColumnMappingCollection'
    ,'SchemaName'
##>
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Intune","Graph","IntuneSync","GraphSync","SQL")

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
