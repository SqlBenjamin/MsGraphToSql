# Get-SqlTableDefinition
function Get-SqlTableDefinition {
<#
.SYNOPSIS
    This function builds a SQL CREATE TABLE command with the provided column definition and table name.
.DESCRIPTION
    The function creates a CREATE TABLE command (string) which can be used to create a table based on the column definition.
.PARAMETER SchemaName
    The name of the schema to use in the CREATE TABLE command. Default is "dbo".
.PARAMETER TableName
    The name of the table to use in the CREATE TABLE command.
.PARAMETER ColumnDefinition
    An object containing the column definition. Expected Properties for this object:
    -Name = The name of the column
    -Type = The data type of the column
    -Nullable = whether the column can be NULL or NOT NULL
    -MaxLength = (optional) if it's a string the length of the string to use; when this is null then 'max' is used. I.E., 36 would be for nvarchar(36).
.EXAMPLE
    Get-SqlTableDefinition -TableName 'MyTable' -ColumnDefinition $ColDefObject;
    This creates a CREATE TABLE statement for dbo.MyTable using the columns defined in "ColDefObject".
.OUTPUTS
    A string.
.NOTES
    NAME: Get-SqlTableDefinition
    HISTORY:
        Date          Author                    Notes
        03/26/2018    Benjamin Reynolds         Initial Creation
        08/29/2018    Benjamin Reynolds         Updated MaxLength logic since it was not working in a test - different input types apparently...
        10/14/2020    Benjamin Reynolds         Added ability to send DataColumnCollection to $ColumnDefinition.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$false)][string]$SchemaName='dbo'
       ,[Parameter(Mandatory=$true)][string]$TableName
       ,[Parameter(Mandatory=$true)]$ColumnDefinition
    )

    # 
    [String]$TableDefinitionSql = "CREATE TABLE $SchemaName.$TableName ("
    $NumSpaces = $TableDefinitionSql.Length
    $FirstLine = $true

    foreach ($Col in $ColumnDefinition) {
        # If the column has a MaxLength property we'll use that, otherwise just use "max": had to use dbnull and regular checks to account for different types...
         # $Col['MaxLength'] -ne [System.DBNull]::Value) ....this used to work but didn't in my most recent test...
        if ($Col.MaxLength -and $Col.MaxLength -notin ($null,'',-1)) {
            [string]$MaxLength = "$($Col.MaxLength)"
        }
        else {
            [string]$MaxLength = "max"
        }
        
        # Create some usable variables based on the datatype of the ColumnDefinition passed in:
        if ($Col.GetType().Name -eq 'DataColumn')
        {
            [string]$colType = $Col.DataType.Name;
            [string]$colName = $Col.ColumnName;
            [bool]$cNullable = $Col.AllowDBNull;

        }
        else
        {
            [string]$colType = $Col.Type;
            [string]$colName = $Col.Name;
            [bool]$cNullable = [System.Convert]::ToBoolean($Col.Nullable);
        }

        # Change the Type to something usable in SQL:
        [string]$SqlType = 
        Switch ($colType) {
                "String" {"nvarchar($MaxLength)";break}
                "DateTime" {"datetime2";break}
                "Int64" {"bigint";break}
                "Int32" {"int";break}
                "Int16" {"smallint";break}
                "Byte" {"tinyint";break}
                "Boolean" {"bit";break}
                "Guid" {"uniqueidentifier";break}
                "Binary" {"varbinary($MaxLength)";break}
                default {$colType;break}
        }

        # Change the Nullable to something usable in SQL:
        [string]$Nullable =
        Switch ($cNullable) {
                $false {"NOT NULL";break}
                default {"NULL";break}
        }

        # Create each of the column lines:
        if ($FirstLine) {
            $TableDefinitionSql += " $colName $SqlType $Nullable`r`n"
            $FirstLine = $false
        }
        else {
            $TableDefinitionSql += "$(" "*$NumSpaces),$colName $SqlType $Nullable`r`n"
        }

    }

    $TableDefinitionSql += "$(" "*$NumSpaces));"

    return $TableDefinitionSql

} # End Function: Get-SqlTableDefinition
