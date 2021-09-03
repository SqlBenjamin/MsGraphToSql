# Get-ColumnDefWithInheritedProps; check this for optimization?
function Get-ColumnDefWithInheritedProps {
<#
.SYNOPSIS
    This function creates a 'column definition' for a Graph entity using $metadata to determine all properties. (several assumptions used in this)
.DESCRIPTION
    The function finds the properties and inherited properties of a given Graph entity, such as "microsoft.graph.mobileApp". Get-InheritedProperties is
    used to get the main properties and inherited properties. In addition to these properties the function tries to determine if there are derived types
    by finding any entities that have a "BaseType" equal to the entity name. For example, "microsoft.graph.mobileApp" is found as a base type for numerous
    entities. Some examples of some are "webApp", "AndroidStoreApp", etc. Thus, mobileApp has derived types defined in the metadata.
    When an entity has derived typs we assume there will be a "@odata.type" column/property returned so we add that to the 'column definition'.
    If the "ExpandedColumns" parameter is passed in then we make sure to include these properties in the column definition if they are found as "NavigationProperty"s.
.PARAMETER GraphMetaDataEntityName
    This is the entity name for which we want to find the column definition.
.PARAMETER ExpandedColumns
    If there are properties in this parameter we'll check to see which of these (column separated) items are found as a "NavigationProperty" of the entity. If it's found
    then a column is created for the property as an nvarchar(max) column and "_JSON" is appended to the column name since when this property is expanded in Graph it will
    be JSON data.
.PARAMETER Version
    This is the version of $metadata to use when traversing the schema to find all this information.
.EXAMPLE
    Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName 'microsoft.graph.mobileApp' -Version 'v1.0';
    This creates a column definition for the metadata entity "mobileApp" from version 1.0 of the service.
.EXAMPLE
    Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName 'microsoft.graph.mobileApp' -ExpandedColumns 'assignments' -Version 'v1.0';
    This creates a column definition for the metadata entity "mobileApp" from version 1.0 of the service and will include a column named "assignments_JSON".
.NOTES
    NAME: Get-ColumnDefWithInheritedProps
    HISTORY:
        Date          Author                    Notes
        03/27/2018    Benjamin Reynolds         Initial Creation
        04/02/2018    Benjamin Reynolds         Added Expanded Column handling.
        08/09/2018    Benjamin Reynolds         Added Version handling.
        10/19/2018    Benjamin Reynolds         Updated to handle inherited properties dynamically so that any properties returned will be added.
                                                Added max length from enums.
        10/22/2018    Benjamin Reynolds         Updated logic to handle when ExpandedColumns is "*" rather than a list of properties.
        01/29/2020    Benjamin Reynolds         Updated the logic to strip off information in the "Type" or "BaseType" to be more dynamic to account
                                                for any change in metadata. Ex: "microsoft.graph.something" and "graph.something" now correctly result in "something".
#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true)][String]$GraphMetaDataEntityName
       ,[Parameter(Mandatory=$false)][String]$ExpandedColumns
       ,[Parameter(Mandatory=$false)][Alias("MetaDataVersion")][String]$Version
    )

    ## Determine what global variables we're going to use:
    if (-Not $Version) {
        ## Legacy (v2 backward compatability):
        ##Write-Verbose "No Version provided: legacy/backward compatibility logic being used...";
        if (-Not $Global:Entities) {
            ##Write-Verbose "The global variable containing all the entities does not exist so we'll try to create it...";
            $Global:Entities = Get-EntityTypeMetaData -EntityName "EntityTypes";
        }
        if (-Not $Global:Enums) {
            $Global:Enums = Get-EntityTypeMetaData -EntityName "Enums";
        }
        $VerEntName = "Entities";
        $VerEnumName = "Enums";
    }
    else {
        # New logic/functionality:
        ##Write-Verbose "Version provided: new logic being used...";
        $VerEntName = "Entities_$($Version.Replace('.','dot'))";
        $VerEnumName = "Enums_$($Version.Replace('.','dot'))";
    }

    ## Get the global variable information into local variables:
    $VerEntities = Get-Variable -Name $VerEntName -Scope Global -ValueOnly -ErrorAction SilentlyContinue; #use "-ErrorAction Stop" if we want to use a try/catch block
    $VerEnums = Get-Variable -Name $VerEnumName -Scope Global -ValueOnly -ErrorAction SilentlyContinue; #use "-ErrorAction Stop" if we want to use a try/catch block

    ## Check to make sure we have the entity and enum variables we need (necessary for the new logic really):
    if (-Not $VerEntities) {
        ##Write-Verbose "We didn't get a local copy of the global variable for the right version of metadata...";
        if ($Version) {
            #Get-EntityTypeMetaData -EntityName "EntityTypes" -Version $Version;
            throw "Entity MetaData does not exist for the version '$Version'! You must use 'Get-EntityTypeMetaData -EntityName ""EntityTypes"" -Version ""$Version""'!";
        }
        else {
            #Get-EntityTypeMetaData -EntityName "EntityTypes";
            throw "Entity MetaData does not exist (for the legacy versioning method)! You must use 'Get-EntityTypeMetaData -EntityName ""EntityTypes""'!";
        }
    }
    if (-Not $VerEnums) {
        ##Write-Verbose "We didn't get a local copy of the global variable for the right version of metadata...";
        if ($Version) {
            #Get-EntityTypeMetaData -EntityName "Enums" -Version $Version;
            throw "Enum MetaData does not exist for the version '$Version'! You must use 'Get-EntityTypeMetaData -EntityName ""Enums"" -Version ""$Version""'!";
        }
        else {
            #Get-EntityTypeMetaData -EntityName "Enums";
            throw "Enum MetaData does not exist (for the legacy versioning method)! You must use 'Get-EntityTypeMetaData -EntityName ""Enums""'!";
        }
    }

    ## Create the ArrayLists we'll be using later:
    $DerivedTypes = New-Object -TypeName System.Collections.ArrayList;
    $ColumnDefinition = New-Object -TypeName System.Collections.ArrayList;

    ## Create the $GraphEntityNameInfo object we'll be using:
    foreach ($Ent in $VerEntities) {
        if ($Ent.Name -eq $GraphMetaDataEntityName.Substring($GraphMetaDataEntityName.LastIndexOf('.')+1)) { ## this will turn both "microsoft.graph.something" and "graph.something" into "something"
            $GraphEntityNameInfo = $Ent;
            break; # stop the foreach as soon as we find it...
        }
    }
    Remove-Variable -Name Ent -ErrorAction SilentlyContinue;

    ## Get the inherited properties for the current Entity:
    if ($Version) {
        $InheritedProps = Get-InheritedProperties -BaseTypeName $GraphEntityNameInfo.BaseType -Version $Version;
    }
    else {
        $InheritedProps = Get-InheritedProperties -BaseTypeName $GraphEntityNameInfo.BaseType;
    }

    ## Get the DerivedTypes for the current entity:
    foreach ($Ent in $VerEntities) {
        if (-Not [String]::IsNullOrEmpty($Ent.BaseType)) {
            if ($Ent.BaseType.Replace('Collection(','').Replace(')','') -eq $GraphMetaDataEntityName) { # GraphMetaDataEntityName comes in with "Collection()" removed
                [void]$DerivedTypes.Add($Ent);
            }
        }
    }
    Remove-Variable -Name Ent -ErrorAction SilentlyContinue;

    ## Create/Set a flag to specify whether the current entity will (or most likely will) have an 'odata.type' property added:
    if ($DerivedTypes) {
        $WillHaveOdataType = $true;
    }
    else {
        $WillHaveOdataType = $false;
    }

    ### Start creating the column definition:
    ## if it has an Odata.Type then we want that to be the first column in the column definition:
    if ($WillHaveOdataType) {
        $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "@odata.type";"Name" = "odatatype";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
        [void]$ColumnDefinition.Add($CurColObj);
        Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
    }

    ## Next add the inherited properties in order of highest parent down in the order they exist in the metadata:
    if ($InheritedProps) {
        # We'll sort the Inherited Properties in the order they should be and add each one to our ArrayList:
          # Not sure if there is a more efficient way to do the sorting instead of using pipes and "Sort-Object"...
        foreach ($Prop in ($InheritedProps | Sort-Object -Property ParentOrder -Descending | Sort-Object -Property PropertyOrder)) {
            #dynamically build the hash table to use for the PSObject:
            $CurHash = New-Object -TypeName System.Collections.Hashtable;
            foreach ($itm in $Prop.PSObject.Properties) {
                if ($itm.Name -notin ('ParentOrder','PropertyOrder')) {
                    $CurHash[$itm.Name] = $itm.Value;
                }
            }
            Remove-Variable -Name itm -ErrorAction SilentlyContinue;
            # Make sure each column has IsCollection set:
            if (-not $CurHash.IsCollection) {
                $CurHash["IsCollection"] = "false";
            }

            $CurColObj = New-Object -TypeName PSObject -Property $CurHash;
            [void]$ColumnDefinition.Add($CurColObj);
            Remove-Variable -Name CurHash,CurColObj -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name Prop -ErrorAction SilentlyContinue;
    }

    ## Now add all the properties for the 'class' (i.e., not the derived column properties):
    foreach ($Prop in ($GraphEntityNameInfo.Property)) {
        # The use of Substring and LastIndexOf here allows the type to be determined a little more dynamically - "microsoft.graph.something" and "graph.something" correctly result in "something" now:
        if (-Not [String]::IsNullOrEmpty($Prop.Type)) {
            if ($Prop.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($Prop.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1) -in $($VerEnums.Name)) {
                # Determine the MaxLength of the property based on the values in the enum:
                foreach ($enm in $VerEnums) {
                    if ($enm.Name -eq $Prop.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($Prop.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1)) {
                        $MaxLen = 0;
                        foreach ($len in $enm.Member.Name.GetEnumerator().Length) {
                            if ($len -gt $MaxLen) {
                                $MaxLen = $len;
                            }
                        }
                        Remove-Variable -Name len -ErrorAction SilentlyContinue;
                        break;
                    }
                }
                Remove-Variable -Name enm -ErrorAction SilentlyContinue;
                if ($MaxLen -gt 0) {
                    $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $($Prop.Name);"Name" = $($Prop.Name);"Type" = "String";"MaxLength" = $MaxLen;"Nullable" = $(if (-not $Prop.Nullable) {"true"} else {$Prop.Nullable});"IsCollection" = "false"}; # should we use $true/$false rather than text
                }
                else {
                    $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $($Prop.Name);"Name" = $($Prop.Name);"Type" = "String";"Nullable" = $(if (-not $Prop.Nullable) {"true"} else {$Prop.Nullable});"IsCollection" = "false"};# should we use $true/$false rather than text
                }
                Remove-Variable -Name MaxLen -ErrorAction SilentlyContinue;
            }
            elseif ($Prop.Type -like 'Edm.*') {
                $CurType = $Prop.Type.Replace('Edm.','').Replace("DateTimeOffset","DateTime").Replace("TimeOfDay","DateTime").Replace("Binary","String").Replace("bool","Boolean").Replace("int","Int32").Replace("guid","uniqueidentifier");
                $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $($Prop.Name);"Name" = $($Prop.Name);"Type" = $CurType;"Nullable" = $(if (-not $Prop.Nullable) {"true"} else {$Prop.Nullable});"IsCollection" = "false"};# should we use $true/$false rather than text
                Remove-Variable -Name CurType -ErrorAction SilentlyContinue;
            }
            else {
                # This is if we wanted to do something about the collection/complex types...
                $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $($Prop.Name);"Name" = "$($Prop.Name)_JSON";"Type" = "String";"Nullable" = "true";"IsCollection" = "true"};# should we use $true/$false rather than text
            }
            # Add the property/column to the definition:
            [void]$ColumnDefinition.Add($CurColObj);
            Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        }
    }
    Remove-Variable -Name Prop -ErrorAction SilentlyContinue;
    
    # Add a Column for all derived properties as a JSON column?

    ## Lastly, add a property for the expanded columns (if there are any):
    if ($ExpandedColumns -eq '*') {
        foreach ($xcol in $GraphEntityNameInfo.NavigationProperty) {
            $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $xcol.Name;"Name" = "$($xcol.Name)_JSON";"Type" = "String";"Nullable" = "true";"IsCollection" = "true"};
            [void]$ColumnDefinition.Add($CurColObj);
            Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name xcol -ErrorAction SilentlyContinue;
    }
    elseif (-not [string]::IsNullOrEmpty($ExpandedColumns)) {
        foreach ($NavPrp in $GraphEntityNameInfo.NavigationProperty) {
            if ($NavPrp.Name -in ($ExpandedColumns -split ",")) { # Should we create an object for the split columns?
                $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $NavPrp.Name;"Name" = "$($NavPrp.Name)_JSON";"Type" = "String";"Nullable" = "true";"IsCollection" = "true"};
                [void]$ColumnDefinition.Add($CurColObj);
                Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
            }
        }
        Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;
    }

    ## Return the Column Definition we've created:
    return $ColumnDefinition;

    #Cleanup??:
    Remove-Variable -Name VerEntName,VerEnumName,VerEntities,VerEnums,DerivedTypes,InheritedProps,GraphEntityNameInfo,WillHaveOdataType,ExpandedColumns,ColumnDefinition -ErrorAction SilentlyContinue;

} # End Function: Get-ColumnDefWithInheritedProps
