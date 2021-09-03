# Get-ExpandedColDefWithInheritedProps; check this for optimization?
function Get-ExpandedColDefWithInheritedProps {
<#
.SYNOPSIS
    This function creates a 'column definition' for a Graph entity using $metadata to determine all properties. (several assumptions used in this).
    This is very similar to "Get-ColumnDefWithInheritedProps". However, this returns a column definition for each of the 'expanded columns'.
.DESCRIPTION
    This function basically does what "Get-ColumnDefWithInheritedProps" does, but does it for each of the expanded columns passed in. Info from aforementioned function:
     The function finds the properties and inherited properties of a given Graph entity, such as "microsoft.graph.mobileApp". Get-InheritedProperties is
     used to get the main properties and inherited properties. In addition to these properties the function tries to determine if there are derived types
     by finding any entities that have a "BaseType" equal to the entity name. For example, "microsoft.graph.mobileApp" is found as a base type for numerous
     entities. Some examples of some are "webApp", "AndroidStoreApp", etc. Thus, mobileApp has derived types defined in the metadata.
     When an entity has derived typs we assume there will be a "@odata.type" column/property returned so we add that to the 'column definition'.
     If the "ExpandedColumns" parameter is passed in then we make sure to include these properties in the column definition if they are found as "NavigationProperty"s.
.PARAMETER GraphMetaDataEntityName
    This is the entity name for which we want to find the column definition.
.PARAMETER ExpandedColumns
    Each of the properties in this parameter (column separated) found as a "NavigationProperty" of the entity will get a column definition created
    (so that separate tables could be created if desired).
.PARAMETER Version
    This is the version of $metadata to use when traversing the schema to find all this information.
.EXAMPLE
    Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName 'microsoft.graph.mobileApp' -Version 'v1.0';
    This creates a column definition for the metadata entity "mobileApp" from version 1.0 of the service.
.EXAMPLE
    Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName 'microsoft.graph.mobileApp' -ExpandedColumns 'assignments' -Version 'v1.0';
    This creates a column definition for the metadata entity "mobileApp" from version 1.0 of the service and will include a column named "assignments_JSON".
.NOTES
    NAME: Get-ExpandedColDefWithInheritedProps
    HISTORY:
        Date          Author                    Notes
        04/02/2018    Benjamin Reynolds         Initial Creation; to handle expanded columns into their own tables.
        08/09/2018    Benjamin Reynolds         Added Version handling.
        10/22/2018    Benjamin Reynolds         Updated to handle inherited properties dynamically so that any properties returned will be added.
                                                Added max length from enums. Updated logic to handle when ExpandedColumns is "*" rather than a list of properties.
        01/29/2020    Benjamin Reynolds         Updated the logic to strip off information in the "Type" or "BaseType" to be more dynamic to account
                                                for any change in metadata. Ex: "microsoft.graph.something" and "graph.something" now correctly result in "something".

    ISSUES/THOUGHTS:
        This could probably be simplified by calling "Get-ColumnDefWithInheritedProps" for each of the expanded properties rather than doing essentially the same thing within...
#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true)][String]$GraphMetaDataEntityName
       ,[Parameter(Mandatory=$true)][String]$ExpandedColumns
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
    $ExpColsGraphMetaDataEntityNames = New-Object -TypeName System.Collections.ArrayList;
    $ExpandColDefinition = New-Object -TypeName System.Collections.ArrayList;

    ## Create the $GraphEntityNameInfo object we'll be using:
    foreach ($Ent in $VerEntities) {
        if ($Ent.Name -eq $GraphMetaDataEntityName.Substring($GraphMetaDataEntityName.LastIndexOf('.')+1)) { ## this will turn both "microsoft.graph.something" and "graph.something" into "something"
            $GraphEntityNameInfo = $Ent;
            break; # stop this foreach as soon as we find it
        }
    }
    Remove-Variable -Name Ent -ErrorAction SilentlyContinue;

    ## Create the array of GraphMetaDataEntityNames for each of the expanded columns passed in:
    if ($ExpandedColumns -eq '*') {
        foreach ($xcol in $GraphEntityNameInfo.NavigationProperty) {
            $CurColObj = New-Object -TypeName PSObject -Property @{"Name" = $NavPrp.Name;"EntityName" = $NavPrp.Type.Replace('Collection(','').Replace(')','')};
            [void]$ExpColsGraphMetaDataEntityNames.Add($CurColObj);
            Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name xcol -ErrorAction SilentlyContinue;
    }
    else {
        foreach ($NavPrp in  $GraphEntityNameInfo.NavigationProperty) {
            if ($NavPrp.Name -in ($ExpandedColumns -split ",")) { # Should we create an object for the split columns?
                $CurColObj = New-Object -TypeName PSObject -Property @{"Name" = $NavPrp.Name;"EntityName" = $NavPrp.Type.Replace('Collection(','').Replace(')','')};
                [void]$ExpColsGraphMetaDataEntityNames.Add($CurColObj);
                Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
            }
        }
        Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;
    }

    ## Get the properties for each of the expanded columns passed in:
    foreach ($ExpCol in $ExpColsGraphMetaDataEntityNames) {
        ## Create objects to use for current expanded column:
        $CurDerivedTypes = New-Object -TypeName System.Collections.ArrayList;
        $CurColumnDefinition = New-Object -TypeName System.Collections.ArrayList;
        
        # 
        foreach ($Ent in $VerEntities) {
            if (-Not [String]::IsNullOrEmpty($ExpCol.EntityName)) {
                if ($Ent.Name -eq $ExpCol.EntityName.Substring($ExpCol.EntityName.LastIndexOf('.')+1)) { # EntityName already has "Collection()" stripped off
                    $CurEntInfo = $Ent;
                    break; # stop looking once we find it (break out of the foreach)
                }
            }
        }
        Remove-Variable -Name Ent -ErrorAction SilentlyContinue;

        ## Get the inherited properties:
        if ($Version) {
            $CurInheritedProps = Get-InheritedProperties -BaseTypeName $CurEntInfo.BaseType -Version $Version;
        }
        else {
            $CurInheritedProps = Get-InheritedProperties -BaseTypeName $CurEntInfo.BaseType;
        }
        
        foreach ($Ent in $VerEntities) {
            if (-Not [String]::IsNullOrEmpty($Ent.BaseType)) {
                if ($Ent.BaseType.Replace('Collection(','').Replace(')','') -eq $ExpCol.EntityName) { # $ExpCol.EntityName already has "Collection()" removed
                    [void]$CurDerivedTypes.Add($Ent);
                }
            }
        }
        Remove-Variable -Name Ent -ErrorAction SilentlyContinue;

        if ($CurDerivedTypes) {
            $CurWillHaveOdataType = $true;
        }
        else {
            $CurWillHaveOdataType = $false;
        }

        # Let's hardcode a "ParentOdataType" and a "ParentId" since that wouldn't be included otherwise:
          # Not my favorite way to do things, but...gotta do what we gotta do...
        $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "ParentOdataType";"Name" = "ParentOdataType";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
        [void]$CurColumnDefinition.Add($CurColObj);
        Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "ParentId";"Name" = "ParentId";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
        [void]$CurColumnDefinition.Add($CurColObj);
        Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        ############################# End hardcoding the parent columns

        ## if it has an '@odata.type' then we want that to be the first column (after the parent columns):
         # I don't think this will ever be the case but leaving just in case...not sure how it could work since the DataName would be the same as above!
        if ($CurWillHaveOdataType) {
            $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = "@odata.type";"Name" = "odatatype";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
            [void]$CurColumnDefinition.Add($CurColObj);
            Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
        }
        
        ## Next add the inherited properties in order of highest parent down in the order they exist in the metadata:
        if ($CurInheritedProps) {
            # We'll sort the Inherited Properties in the order they should be and add each one to our ArrayList:
              # Not sure if there is a more efficient way to do the sorting instead of using pipes and "Sort-Object"...
            foreach ($Prop in ($CurInheritedProps | Sort-Object -Property ParentOrder -Descending | Sort-Object -Property PropertyOrder)) {
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
                
                # add the hashtable to the array list:
                $CurColObj = New-Object -TypeName PSObject -Property $CurHash;
                [void]$CurColumnDefinition.Add($CurColObj);
                Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name Prop -ErrorAction SilentlyContinue;
        }
        
        ## Now add all the properties for the 'class' (i.e., not the derived column properties):
        foreach ($Prop in ($CurEntInfo.Property)) {
            
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
                [void]$CurColumnDefinition.Add($CurColObj);
                Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue;
            }
        }
        Remove-Variable -Name Prop -ErrorAction SilentlyContinue;
        
        # Add a Column for all derived properties as a JSON column?
        
        <# ## This would only be necessary if we wanted to deal with something like '$expand=Something($expand=AnotherLevelofExpansion)'...and would need to be fixed up so it would work:
        # Lastly, add a property for the expanded columns (if there are any):
        $CurEntInfo.NavigationProperty | ? {$_.Name -in ($ExpandedColumns -split ",")} | % {
            $CurColObj = New-Object -TypeName PSObject -Property @{"DataName" = $_.Name;"Name" = "$($_.Name)_JSON";"Type" = "String";"Nullable" = "true";"IsCollection" = "true"}
            [void]$CurColumnDefinition.Add($CurColObj)
            Remove-Variable -Name CurColObj -ErrorAction SilentlyContinue
            }
        #>

        ## Add the current expanded column information to the return object:
        $CurExpObj = New-Object -TypeName PSObject -Property @{"ExpandedColName" = $ExpCol.Name; "ExpandedColEntityName" = $ExpCol.EntityName; "ColumnDefinition" = $CurColumnDefinition};
        [void]$ExpandColDefinition.Add($CurExpObj);

        Remove-Variable -Name CurEntInfo,CurInheritedProps,CurDerivedTypes,CurWillHaveOdataType,CurColumnDefinition,CurExpObj -ErrorAction SilentlyContinue;
    } # End: foreach expanded column

    ## return the object:
    return $ExpandColDefinition;

    ## Cleanup??:
    Remove-Variable -Name ExpColsGraphMetaDataEntityNames,GraphEntityNameInfo,ExpandColDefinition,VerEnums,VerEntities,VerEnumName,VerEntName -ErrorAction SilentlyContinue;

} # End Function: Get-ExpandedColDefWithInheritedProps
