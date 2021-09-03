# Get-InheritedProperties
function Get-InheritedProperties {
<#
.SYNOPSIS
    This function is used to find all the properties and inherited properties of a given Graph URI "Entity".
.DESCRIPTION
    The function takes an entity name (such as "microsoft.graph.managedDevice") and determines all the properties in this entity as well as
    any properties it inherits (based on the "BaseType").
.PARAMETER BaseTypeName
    This is the name of the entity to find all properties and inherited properties.
.PARAMETER Version
    This is the version of Graph from which to find the information. This is not required for backward compatibility reasons. This will be required in the future.
.PARAMETER ReturnNavProps
    When this switch is used the inherited navigation properties will be returned as well as the inherited properties.
.EXAMPLE
    Get-InheritedProperties -BaseTypeName microsoft.graph.managedDevice -Version beta;
.NOTES
    NAME: Get-InheritedProperties
    HISTORY:
        Date          Author                    Notes:
        03/22/2018    Benjamin Reynolds         Created.
        08/09/2018    Benjamin Reynolds         Updated to handle different Graph versions while keeping backward compatibility as well.
        10/19/2018    Benjamin Reynolds         Updated to not assume inherited properties won't be collecions and added enum max length info.
        10/22/2018    Benjamin Reynolds         Added switch 'ReturnNavProps' to be able to include the navigation properties inherited as well as the properties.
        01/29/2020    Benjamin Reynolds         Updated the logic to strip off information in the "Type" or "BaseType" to be more dynamic to account
                                                for any change in metadata. Ex: "microsoft.graph.something" and "graph.something" now correctly result in "something".
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][String]$BaseTypeName
       ,[Parameter(Mandatory=$false)][Alias("MetaDataVersion")][String]$Version
       ,[Parameter(Mandatory=$false)][switch]$ReturnNavProps
    )
    
    $BaseTypeName = Split-Path -Path $BaseTypeName.Replace(".","\") -Leaf;
    $InheritedProperties = New-Object -TypeName System.Collections.ArrayList;
    $InheritedNavProps = New-Object -TypeName System.Collections.ArrayList;
    [int]$ParentOrder = 1;
    
    if (-Not $Version) {
        ## Legacy (v2 backward compatability):
        ##Write-Verbose "No Version provided: legacy/backward compatibility logic being used...";
        if (-Not $Global:Entities) {
            ##Write-Verbose "The global variable containing all the entities does not exist so we'll try to create it...";
            $Global:Entities = Get-EntityTypeMetaData -EntityName "EntityTypes";
        }
        $VerEntName = "Entities";
        if (-not $Global:Enums) {
            $Global:Enums = Get-EntityTypeMetaData -EntityName "Enums";
        }
        $VerEnmName = "Enums";
    }
    else {
        # New logic/functionality:
        ##Write-Verbose "Version provided: new logic being used...";
        $VerEntName = "Entities_$($Version.Replace('.','dot'))";
        $VerEnmName = "Enums_$($Version.Replace('.','dot'))";
    }

    $VerEntities = Get-Variable -Name $VerEntName -Scope Global -ValueOnly -ErrorAction SilentlyContinue; #use "-ErrorAction Stop" if we want to use a try/catch block
    $VerEnums = Get-Variable -Name $VerEnmName -Scope Global -ValueOnly -ErrorAction SilentlyContinue; #use "-ErrorAction Stop" if we want to use a try/catch block
    Remove-Variable -Name VerEntName,VerEnmName -ErrorAction SilentlyContinue;

    if (-not $VerEntities) {
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
    if (-not $VerEnums) {
        ##Write-Verbose "We didn't get a local copy of the global variable for the right version of metadata...";
        if ($Version) {
            #Get-EntityTypeMetaData -EntityName "EntityTypes" -Version $Version;
            throw "Enum MetaData does not exist for the version '$Version'! You must use 'Get-EntityTypeMetaData -EntityName ""Enums"" -Version ""$Version""'!";
        }
        else {
            #Get-EntityTypeMetaData -EntityName "EntityTypes";
            throw "Enum MetaData does not exist (for the legacy versioning method)! You must use 'Get-EntityTypeMetaData -EntityName ""Enums""'!";
        }
    }

    while ($BaseTypeName) {
        ##Write-Verbose "The 'BaseTypeName' is: $BaseTypeName";
        ## OLD: $ParentObj = ($VerEntities | ? {$_.Name -eq $BaseTypeName});
        foreach ($VerEnt in $VerEntities) {
            if ($VerEnt.Name -eq $BaseTypeName) {
                $ParentObj = $VerEnt;
                break; # stop looping through this foreach...
                ##Write-Verbose "We found the BaseTypeName in the entities and set the ParentObj to it...";
                ##Write-Verbose $ParentObj.Name;
            }
        }

        [int]$PropOrder = 1;
        foreach ($Prp in ($ParentObj.Property)) {
            # The use of Substring and LastIndexOf here allows the type to be determined a little more dynamically - "microsoft.graph.something" and "graph.something" correctly result in "something" now:
            if (-Not [String]::IsNullOrEmpty($Prp.Type)) {
                if ($Prp.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($Prp.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1) -in $($VerEnums.Name)) {
                
                    # Determine the MaxLength of the property based on the values in the enum:
                    foreach ($enm in $VerEnums) {
                        if ($enm.Name -eq $Prp.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($Prp.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1)) {
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
                        $CurPrp = New-Object -TypeName PSObject -Property @{"DataName" = $($Prp.Name);"Name" = $($Prp.Name);"Type" = "String";"MaxLength" = $MaxLen;"Nullable" = $(if (-not $Prp.Nullable) {"true"} else {$Prp.Nullable});"ParentOrder" = $ParentOrder;"PropertyOrder" = $PropOrder}; # should we use $true/$false rather than text for "Nullable"?
                    }
                    else {
                        $CurPrp = New-Object -TypeName PSObject -Property @{"DataName" = $($Prp.Name);"Name" = $($Prp.Name);"Type" = "String";"Nullable" = $(if (-not $Prp.Nullable) {"true"} else {$Prp.Nullable});"ParentOrder" = $ParentOrder;"PropertyOrder" = $PropOrder};# should we use $true/$false rather than text for "Nullable"?
                    }
                    Remove-Variable -Name MaxLen -ErrorAction SilentlyContinue;
                }
                elseif ($Prp.Type -like 'Edm.*') {
                    $CurType = $Prp.Type.Replace('Edm.','').Replace("DateTimeOffset","DateTime").Replace("TimeOfDay","DateTime").Replace("Binary","String").Replace("bool","Boolean").Replace("int","Int32").Replace("guid","uniqueidentifier");
                    $CurPrp = New-Object -TypeName PSObject -Property @{"DataName" = $($Prp.Name);"Name" = $($Prp.Name);"Type" = $CurType;"Nullable" = $(if (-not $Prp.Nullable) {"true"} else {$Prp.Nullable});"ParentOrder" = $ParentOrder;"PropertyOrder" = $PropOrder};# should we use $true/$false rather than text for "Nullable"?
                    Remove-Variable -Name CurType -ErrorAction SilentlyContinue;
                }
                else {
                    # This is if we wanted to do something about the collection/complex types...
                    $CurPrp = New-Object -TypeName PSObject -Property @{"DataName" = $($Prp.Name);"Name" = "$($Prp.Name)_JSON";"Type" = "String";"Nullable" = "true";"IsCollection" = "true";"ParentOrder" = $ParentOrder;"PropertyOrder" = $PropOrder};# should we use $true/$false rather than text for "Nullable"?
                }
                # Add the property to the return object and iterate the property order number:
                [void]$InheritedProperties.Add($CurPrp);
                $PropOrder += 1;
            }
        } # End: foreach property in the ParentObj

        ## Create an ArrayList of the Navigation Properties since inherited ones can be expanded:
        foreach ($NavPrp in $ParentObj.NavigationProperty) {
            $NavPrpObj = New-Object -TypeName PSObject -Property @{"Name" = $($NavPrp.Name);"Type" = $($NavPrp.Type);"ContainsTarget" = $($NavPrp.ContainsTarget);"ParentOrder" = $ParentOrder};
            [void]$InheritedNavProps.Add($NavPrpObj);
            Remove-Variable -Name NavPrpObj -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;

        if (-Not $ParentObj.BaseType) {
            ##Write-Verbose "We hit the 'ParentObj.BaseType doesn't exist' condition and are trying to remove the BaseTypeName variable...";
            Remove-Variable -Name BaseTypeName;
        }
        else {
            ##Write-Verbose "The 'ParentObj.BaseType' does exist so we'll continue looping by setting the 'BaseTypeName' to this value...";
            $BaseTypeName = Split-Path -Path $ParentObj.BaseType.Replace(".","\") -Leaf;
            $ParentOrder += 1;
        }
        Remove-Variable -Name ParentObj;
        ##Write-Verbose "this is the end of the while loop";
    } # End: While loop - BaseTypeName exists
    
    if ($ReturnNavProps) {
        ## Return both objects as a hashtable:
        return @{"InheritedProperties" = $InheritedProperties;"InheritedNavigationProperties" = $InheritedNavProps};
    }
    else {
        ## Return the ArrayList of hashtables:
        return $InheritedProperties;
    }

    # Cleanup?
    Remove-Variable -Name VerEntities,VerEnums -ErrorAction SilentlyContinue;

} # End: Get-InheritedProperties
