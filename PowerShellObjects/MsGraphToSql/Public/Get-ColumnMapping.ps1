# Get-ColumnMapping
function Get-ColumnMapping {
<#
.SYNOPSIS
    This function creates a column mapping for use with writing a DataTable to SQL.
.DESCRIPTION
    The Column Mapping is based on either the "Name" or the "MappedColumnName" information (for SQL)
    compared to the name of the columns found in the DataTable to write to SQL. Each SQL Column looks for a matching
    value in the array of DataTable Columns - first by the SQL Column Name and then by the MappedColumnName. A
    "Source" (the DataTable Column Name) and "Destination" (SQL Column Name) is defined for each SQL column.
.PARAMETER DtaTblColumns
    This is an ArrayList of all the column names found in the DataTable.
.PARAMETER ColumnDef
    This is the table definition which has the "Name" of the column and if defined the "MappedColumnName".
.EXAMPLE
    Get-ColumnMapping -DtaTblColumns @('one','two') -ColumnDef $SqlTableDefinition;
    Creates a column mapping based on the Column Name or if a "MappedColumnName" mapping name exists that matches
.NOTES
    NAME: Get-ColumnMapping
    HISTORY:
        Date              Author                    Notes
        02/25/2021        Benjamin Reynolds         Created
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][System.Collections.ArrayList]$DtaTblColumns
       ,[Parameter(Mandatory=$true)]$ColumnDef
    )

    $ColumnMapping = New-Object System.Collections.ArrayList;
    
    # Create a case insensitive hashtable with the DataTable Column Names:
    $sourceColIndexes = New-Object System.Collections.Hashtable([System.StringComparer]::InvariantCultureIgnoreCase);
    for ($i = 0; $i -lt $DtaTblColumns.Count; $i++)
    {
        $sourceColIndexes.Add($DtaTblColumns[$i],$DtaTblColumns[$i]);
    }
    
    # Now check each of the Sql Columns to create a mapping object based on the Name or MappedColumnName (if one exists):
    foreach ($col in $ColumnDef)
    {
        [string]$sqlName = $col.Name;
        [string]$mapName = $col.MappedColumnName;

        if ($sourceColIndexes.ContainsKey($sqlName))
        {
            [void]$ColumnMapping.Add((New-Object -TypeName PSObject -Property @{"Source" = $sourceColIndexes[$sqlName];"Destination" = $sqlName}));
        }
        elseif ($sourceColIndexes.ContainsKey($mapName))
        {
            [void]$ColumnMapping.Add((New-Object -TypeName PSObject -Property @{"Source" = $sourceColIndexes[$mapName];"Destination" = $sqlName}));
        }
    }

    Write-Output @(,($ColumnMapping));

} #End: Get-ColumnMapping
