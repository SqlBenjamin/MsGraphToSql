# Get-EntityTypeMetaData
function Get-EntityTypeMetaData {
<#
.SYNOPSIS
    This function finds the element(s) from the $metadata desired.
.DESCRIPTION
    The function searches the metadata found in the global variable (created with "Get-GraphMetaData") to get all the entities for the type of entity passed in,
    such as "Enums", or it will get the information for the specific entity passed in, such as "managedDevice".
.PARAMETER EntityName
    This is either the type of elements to return or the specific element to return. For example, "Entities" will return all the "EntityType" elements from metadata,
    whereas, "managedDevice" will return the xml definition from metadata where the "EntityType" @Name equals "managedDevice".
.PARAMETER Version
    This is the version of metadata to use. This variable really should be required, but is currently not in order to account for some backward compatibility of earlier
    versions of the sync scripts.
.EXAMPLE
    Get-EntityTypeMetaData -EntityName "Enums" -Version "beta";
    This will return an object of all the Enums from the beta version of Graph.
.EXAMPLE
    Get-EntityTypeMetaData -EntityName "managedDevice" -Version "v1.0";
    This will return an object of the definition of the EntityType "managedDevice" from the v1.0 version of Graph.
.NOTES
    NAME: Get-EntityTypeMetaData
    HISTORY:
        Date              Author                    Notes
        01/31/2018        Benjamin Reynolds
        05/23/2018        Benjamin Reynolds         Changed to use Invoke-RestMethod instead of Invoke-WebRequest
        06/22/2018        Benjamin Reynolds         Added Version parameter/logic.
        09/11/2020        Benjamin Reynolds         Added Functions to the possible types in case it's ever needed.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)][Alias("Entity")][String]$EntityName
       ,[Parameter(Mandatory=$false)][Alias("MetaDataVersion")][String]$Version
    )

    # Handle the EntityName that was passed in:
    if ($EntityName -in ('Enum','Enums','EnumType','EnumTypes')) {
        $EntityName = "EnumType"
    }
    elseif ($EntityName -in ('ComplexType','ComplexTypes')) {
        $EntityName = "ComplexType"
    }
    elseif ($EntityName -in ('EntityType','EntityTypes')) {
        $EntityName = "EntityType"
    }
    elseif ($EntityName -in ('EntitySet','EntitySets','Sets')) {
        $EntityName = "EntitySet"
    }
    elseif ($EntityName -in ('Singleton','Singletons')) {
        $EntityName = "Singleton"
    }
    elseif ($EntityName -in ('Function','Functions')) {
        $EntityName = "Function";
    }

    # Check for version:
    if (-Not $Version) {
        # Legacy (v2 backward compatability):
        # Check for metadata
        if (-Not $Global:MetaData) {
            #Get-OperationalStoreMetaData
            throw "MetaData does not exist! You must use 'Get-OperationalStoreMetaData' with the right 'MetaDataUri' OR use 'Get-GraphMetaData' with the right 'Version'!"
        }

        # Get the entity information:
        if ($EntityName -in ("ComplexType","EnumType","EntityType","Action","Function","Annotations")) {
            #$EntityMetaData = $Global:MetaData.SelectNodes("/edm:Edmx/edm:DataServices/sch:Schema/sch:$EntityName",$Global:NamespaceMgr)
            $EntityMetaData = $Global:MetaData.$EntityName
        }
        elseif ($EntityName -in ("EntitySet")) {
            #$EntityMetaData = $Global:MetaData.SelectNodes("/edm:Edmx/edm:DataServices/sch:Schema/sch:EntityContainer/sch:$EntityName",$Global:NamespaceMgr)
            $EntityMetaData = $Global:MetaData.EntityContainer.EntitySet
        }
        elseif ($EntityName -in ("Singleton")) {
            $EntityMetaData = $Global:MetaData.EntityContainer.Singleton
        }
        else {
            # First see if the item requested is a specific EntityType:
            #$EntityMetaData = $Global:MetaData.SelectSingleNode("/edm:Edmx/edm:DataServices/sch:Schema/sch:EntityType[@Name=""$EntityName""]",$Global:NamespaceMgr)
            foreach ($ent in $Global:MetaData.EntityType) {
                if ($ent.Name -eq $EntityName) {
                    $EntityMetaData = $ent
                    break
                }
            }
            
            # check to see if that worked, if not let's try the ComplexType instead of EntityType (i.e. hardwareInformation)
            if (-Not $EntityMetaData) {
                #$EntityMetaData = $Global:MetaData.SelectSingleNode("/edm:Edmx/edm:DataServices/sch:Schema/sch:ComplexType[@Name=""$EntityName""]",$Global:NamespaceMgr)
                foreach ($cmpt in $Global:MetaData.ComplexType) {
                    if ($cmpt.Name -eq $EntityName) {
                        $EntityMetaData = $cmpt
                        break
                    }
                }
            }
        } #end: else
    } # end of "-Not $Version" if check (aka backward compatability stuff)
    else {
        # New Logic: A version was passed in:
        # 
        $VerName = "MetaData_$($Version.Replace('.','dot'))"
        $VerMetaData = Get-Variable -Name $VerName -Scope Global -ValueOnly -ErrorAction SilentlyContinue #use "-ErrorAction Stop" if we want to use a try/catch block

        if (-Not $VerMetaData) {
            #Get-GraphMetaData -Version $Version
            # We'll throw an error to stop processing becuase we don't want to get in a loop (since Get-GraphMetaData calls this function):
            throw "MetaData does not exist for the version '$Version'! You must use 'Get-GraphMetaData' and pass in the version!"
        }
        else {
            # Get the entity information:
            if ($EntityName -in ("ComplexType","EnumType","EntityType","Action","Function","Annotations")) {
                $EntityMetaData = $VerMetaData.$EntityName
            }
            elseif ($EntityName -in ("EntitySet")) {
                $EntityMetaData = $VerMetaData.EntityContainer.EntitySet
            }
            elseif ($EntityName -in ("Singleton")) {
                $EntityMetaData = $VerMetaData.EntityContainer.Singleton
            }
            else {
                # First see if the item requested is a specific EntityType:
                foreach ($ent in $VerMetaData.EntityType) {
                    if ($ent.Name -eq $EntityName) {
                        $EntityMetaData = $ent
                        break
                    }
                }
                
                # check to see if that worked, if not let's try the ComplexType instead of EntityType (i.e. hardwareInformation)
                if (-Not $EntityMetaData) {
                    foreach ($cmpt in $VerMetaData.ComplexType) {
                        if ($cmpt.Name -eq $EntityName) {
                            $EntityMetaData = $cmpt
                            break
                        }
                    }
                }
            } #end: else
        } # end: MetaData exists
    } # end: Version exists
    
    return $EntityMetaData
} # End: Get-EntityTypeMetaData
