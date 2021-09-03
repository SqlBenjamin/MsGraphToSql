# Get-CollectionEntity
function Get-CollectionEntity {
<#
.SYNOPSIS
    This function returns an XmlElement object for the Entity (or class) from Microsoft Graph from the provided URL (in a reversed array).
.DESCRIPTION
    The function will find the Entity/Class for the last portion of the provided URL. This is accomplished by first finding the Entity
    that has the last portion of the URL as a "NavigationPropery". If only one Entity has this information that Entity is returned. If
    multiple Enitities have the same NavigationProperty then the next portion of the URL is used to further narrow down and find the correct Entity for the given URL.
    For example, consider the URL: 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/{some guid here}/deviceStatuses'
    Which will be turned into a reverse order array of: [0] = deviceStatuses; [1] = {some guid here}; [2] = deviceCompliancePolicies; [3] = deviceManagement
     First, this function will find the Entities that have a NavigationProperty of "deviceStatuses" (all the 'EntityType's that have 
     'NavigationProperty Name="deviceStatuses"' in their definition). At this time there are several meeting this criteria.
     Next, because there are multiple Entities with this NavigationProperty, the function will iterate the "UrlPosition" and look for a NavigationProperty
     with the name "{some guid here}". When it doesn't find it it will try to find an EntityType "Name" ('EntityType Name="{some guid here}"') of "{some guid here}".
     Since it won't find this, the EndEntity variable is the same as it was before (having the same multiple entities), the "UrlPosition" will be iterated again and
     it will look again. In this iteration it will do the same thing it did before - look for a NavigationProperty or Name of "deviceCompliancePolicies". When it finds
     this entity, it will look for the associated entity already in "EndEntity" and set EndEntity equal to this entity (or entities if there are still
     multiple). If there are multiple it will continue in this manner until it no longer has multiple or ultimately fails. As soon as there is only
     one item (in our example it is at this point that it only has one) it will return that item (which, now that it is a single entity the object
     is an XmlElement type).
.PARAMETER UrlPartsReversed
    This is an array of a Graph URL split by "/" and then reversed the order of the array. This is what will be used to find the EntityType (class) information.
    If this is used then Url is not.
.PARAMETER Url
    This is a Graph URL that hasn't been split into an array and reversed. This is what will be used to find the EntityType (class) information.
    If this is used then UrlPartsReversed is not.
.PARAMETER Version
    This is used by the function to know which "Entities" global variable to use (to get the class definition from the right version of the service).
.EXAMPLE
    Get-CollectionEntity -UrlPartsReversed $($a = 'deviceManagement/deviceCompliancePolicies/{some guid here}/deviceStatuses' -split "/"; [array]::Reverse($a);)
    This will traverse the URL to find the associated Entity (EntityType Name="deviceCompliancePolicy") and return this entity definition (class?) as an XmlElement.
    This is a legacy (backward compatable) call to this function.
.EXAMPLE
    Get-CollectionEntity -Version 'beta' -UrlPartsReversed $($a = 'deviceManagement/deviceCompliancePolicies/{some guid here}/deviceStatuses' -split "/"; [array]::Reverse($a);)
    This will traverse the URL to find the associated Entity (EntityType Name="deviceCompliancePolicy") and return this entity definition (class?) as an XmlElement
    using the MetaData version "beta".
.EXAMPLE
    Get-CollectionEntity -Url 'deviceManagement/deviceCompliancePolicies/{some guid here}/deviceStatuses' -Version 'beta'
    This will traverse the URL to find the associated Entity (EntityType Name="deviceCompliancePolicy") and return this entity definition (class?) as an XmlElement
    using the MetaData version "beta".
.EXAMPLE
    Get-CollectionEntity -Url 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/{some guid here}/deviceStatuses'
    This will traverse the URL to find the associated Entity (EntityType Name="deviceCompliancePolicy") and return this entity definition (class?) as an XmlElement
    using the MetaData version "beta". Note: this is the same as the above example but because the URL has the full URL it determines the version to use.
.NOTES
    NAME: Get-CollectionEntity
    HISTORY:
        Date              Author                    Notes
        03/26/2018        Benjamin Reynolds         Initial Creation
        08/01/2018        Benjamin Reynolds         Updated to account for Version (dynamic metadata variable to use).
        11/01/2018        Benjamin Reynolds         Optimized function: removed pipes and rather than recursively calling the function kept the looping within
                                                    the function itself so additional function calls aren't necessary. Testing with "Measure-Command" shows a
                                                    marked improvement with this new design.
                                                    Removed the parameters: $EndEntity and $UrlPosition since those were only necessary/used for recursive calls.
                                                    Added the ability to pass a Url rather than an object/array in reversed order.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        #[Parameter(Mandatory=$false)]$EndEntity
        [Parameter(Mandatory=$true,ParameterSetName='UrlObjectReversed')]$UrlPartsReversed
       ,[Parameter(Mandatory=$true,ParameterSetName='UrlOnly')]$Url
       #,[Parameter(Mandatory=$false)]$UrlPosition=0
       ,[Parameter(Mandatory=$false)][Alias("MetaDataVersion")][String]$Version
    )

    if ($PsCmdlet.ParameterSetName -eq 'UrlOnly') {
        
        ## Check the UriPart to see if it contains elements which we need to strip off and/or handle differently:
        if ($Url.IndexOf('graph.microsoft.com/') -ne -1) {
            $UriStartInd = $Url.IndexOf('graph.microsoft.com/')+20;
            $UriVersion = $Url.Substring($UriStartInd,$Url.IndexOf('/',$UriStartInd)-$UriStartInd);
            $UriPart = $Url.Substring($UriStartInd+$UriVersion.Length+1);
        }
        else {
            $UriPart = $Url;
        }
        Remove-Variable -Name UriStartInd,Url -ErrorAction SilentlyContinue;
        
        $UrlPartsReversed = $UriPart -split '/';
        [array]::Reverse($UrlPartsReversed);

        Remove-Variable -Name UriPart -ErrorAction SilentlyContinue;
    }

    if (-not $Version -and $UriVersion) {
        $Version = $UriVersion;
    }
    Remove-Variable -Name UriVersion -ErrorAction SilentlyContinue;
    
    if (-Not $Version) {
        # Legacy (v2 backward compatability):
        #Write-Verbose "Iteration = '$UrlPosition': We don't have a version so we'll use the legacy logic/metadata"
        if (-Not $Global:Entities) {
            $Global:Entities = Get-EntityTypeMetaData -EntityName "EntityTypes"
        }
        
        for ($i = 0; $i -lt $UrlPartsReversed.Count; $i++) {
            $CurPart = $UrlPartsReversed[$i].Substring($UrlPartsReversed[$i].LastIndexOf('.')+1);
            if (-not $EndEntity) {
                $EndEntity = New-Object -TypeName System.Collections.ArrayList;
                #$EndEntity = $Global:Entities | Where-Object {$_.NavigationProperty.Name -eq $CurPart}
                foreach ($Entity in $Global:Entities) {
                    if ($Entity.NavigationProperty.Name -eq $CurPart) {
                        [void]$EndEntity.Add($Entity);
                    }
                }
                Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
            }
            else {
                $Ent = New-Object -TypeName System.Collections.ArrayList;
                #$Ent = $Global:Entities | Where-Object {$_.NavigationProperty.Name -eq $CurPart}
                foreach ($Entity in $Global:Entities) {
                    if ($Entity.NavigationProperty.Name -eq $CurPart) {
                        [void]$Ent.Add($Entity);
                    }
                }
                Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
        
                if ($Ent) {
                    #$EndEntity = $EndEntity | Where-Object {$_.Name -eq (($Ent.NavigationProperty | Where-Object {$_.Name -eq $CurPart} | Select-Object Type -Unique).Type.Replace("Collection(","").Replace(")","")).Replace("microsoft.graph.","")}
                    $CurNewParts = New-Object -TypeName System.Collections.SortedList;
                    foreach ($NavPrp in $Ent.NavigationProperty) {
                        if ($NavPrp.Name -eq $CurPart) {
                            # In case there are duplicates we'll just add the unique items to a list for use:
                            if (-Not [String]::IsNullOrEmpty($NavPrp.Type)) {
                                [string]$itm = $NavPrp.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($NavPrp.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1);
                            }
                            if (-not $CurNewParts.$itm) {
                                [void]$CurNewParts.Add($itm,$itm);
                            }
                            Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                        }
                    }
                    Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;
        
                    ## Remove any items in EndEntity that aren't in Ent; we'll do the for loop in reverse order so we don't have any issues after removing
                    for ($p = $EndEntity.Count-1; $p -ge 0; $p--) {
                        if ($EndEntity[$p].Name -notin ($CurNewParts.Keys)) {
                            $EndEntity.RemoveAt($p);
                        }
                    }
                    Remove-Variable -Name p,CurNewParts -ErrorAction SilentlyContinue;
        
                }
                else {
                    #$Ent = $Global:Entities | Where-Object {$_.Name -eq $CurPart}
                    foreach ($Entity in $Global:Entities) {
                        if ($Entity.Name -eq $CurPart) {
                            [void]$Ent.Add($Entity);
                            break; # we'll stop because there can't be duplicate Entities as far as I'm aware....
                        }
                    }
                    Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
        
                    if ($Ent) {
                        #$EndEntity = $EndEntity | Where-Object {$_.Name -eq ($Ent | Select Name -Unique).Name}
                        ## Remove any items in EndEntity that aren't in Ent; we'll do the for loop in reverse order so we don't have any issues after removing
                        for ($p = $EndEntity.Count-1; $p -ge 0; $p--) {
                            if ($EndEntity[$p].Name -ne $Ent.Name) {
                                $EndEntity.RemoveAt($p);
                            }
                        }
                        Remove-Variable -Name p -ErrorAction SilentlyContinue;
                    }
                }
                Remove-Variable -Name Ent -ErrorAction SilentlyContinue;
            }
        
            if ($EndEntity.Count -eq 1) {
                return $EndEntity;
            }
        } # End: for loop (of all portions of the Url in the UrlPartsReversed object)
        Remove-Variable -Name i,CurPart -ErrorAction SilentlyContinue;
    } # End: No Version provided (legacy/backward compatability portion)
    else {
        # New Logic: A version was passed in:
        # 
        $VerName = "Entities_$($Version.Replace('.','dot'))";
        $VerEntities = Get-Variable -Name $VerName -Scope Global -ValueOnly -ErrorAction SilentlyContinue; #use "-ErrorAction Stop" if we want to use a try/catch block

        if (-Not $VerEntities) {
            #Get-GraphMetaData -Version $Version
            # I don't want to mess with creating the metadata to use so I'm just going to throw an error
            throw "Entity data from MetaData does not exist for the version '$Version'! You must use 'Get-GraphMetaData' and pass in the version!";
        }
        else {
            for ($i = 0; $i -lt $UrlPartsReversed.Count; $i++) {
                $CurPart = $UrlPartsReversed[$i].Substring($UrlPartsReversed[$i].LastIndexOf('.')+1);
                if (-not $EndEntity) {
                    $EndEntity = New-Object -TypeName System.Collections.ArrayList;
                    #$EndEntity = $VerEntities | Where-Object {$_.NavigationProperty.Name -eq $CurPart}
                    foreach ($Entity in $VerEntities) {
                        if ($Entity.NavigationProperty.Name -eq $CurPart) {
                            [void]$EndEntity.Add($Entity);
                        }
                    }
                    Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
                }
                else {
                    $Ent = New-Object -TypeName System.Collections.ArrayList;
                    #$Ent = $VerEntities | Where-Object {$_.NavigationProperty.Name -eq $CurPart}
                    foreach ($Entity in $VerEntities) {
                        if ($Entity.NavigationProperty.Name -eq $CurPart) {
                            [void]$Ent.Add($Entity);
                        }
                    }
                    Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
            
                    if ($Ent) {
                        #$EndEntity = $EndEntity | Where-Object {$_.Name -eq (($Ent.NavigationProperty | Where-Object {$_.Name -eq $CurPart} | Select-Object Type -Unique).Type.Replace("Collection(","").Replace(")","")).Replace("microsoft.graph.","")}
                        $CurNewParts = New-Object -TypeName System.Collections.SortedList;
                        foreach ($NavPrp in $Ent.NavigationProperty) {
                            if ($NavPrp.Name -eq $CurPart) {
                                # In case there are duplicates we'll just add the unique items to a list for use:
                                if (-Not [String]::IsNullOrEmpty($NavPrp.Type)) {
                                    [string]$itm = $NavPrp.Type.Replace('Collection','').Replace('(','').Replace(')','').Substring($NavPrp.Type.Replace('Collection','').Replace('(','').Replace(')','').LastIndexOf('.')+1);
                                }
                                if (-not $CurNewParts.$itm) {
                                    [void]$CurNewParts.Add($itm,$itm);
                                }
                                Remove-Variable -Name itm -ErrorAction SilentlyContinue;
                            }
                        }
                        Remove-Variable -Name NavPrp -ErrorAction SilentlyContinue;
            
                        ## Remove any items in EndEntity that aren't in Ent; we'll do the for loop in reverse order so we don't have any issues after removing
                        for ($p = $EndEntity.Count-1; $p -ge 0; $p--) {
                            if ($EndEntity[$p].Name -notin ($CurNewParts.Keys)) {
                                $EndEntity.RemoveAt($p);
                            }
                        }
                        Remove-Variable -Name p,CurNewParts -ErrorAction SilentlyContinue;
            
                    }
                    else {
                        #$Ent = $VerEntities | Where-Object {$_.Name -eq $CurPart}
                        foreach ($Entity in $VerEntities) {
                            if ($Entity.Name -eq $CurPart) {
                                [void]$Ent.Add($Entity);
                                break; # we'll stop because there can't be duplicate Entities as far as I'm aware....
                            }
                        }
                        Remove-Variable -Name Entity -ErrorAction SilentlyContinue;
            
                        if ($Ent) {
                            #$EndEntity = $EndEntity | Where-Object {$_.Name -eq ($Ent | Select Name -Unique).Name}
                            ## Remove any items in EndEntity that aren't in Ent; we'll do the for loop in reverse order so we don't have any issues after removing
                            for ($p = $EndEntity.Count-1; $p -ge 0; $p--) {
                                if ($EndEntity[$p].Name -ne $Ent.Name) {
                                    $EndEntity.RemoveAt($p);
                                }
                            }
                            Remove-Variable -Name p -ErrorAction SilentlyContinue;
                        }
                    }
                    Remove-Variable -Name Ent -ErrorAction SilentlyContinue;
                }
            
                if ($EndEntity.Count -eq 1) {
                    return $EndEntity;
                }
            } # End: for loop (of all portions of the Url in the UrlPartsReversed object)
            Remove-Variable -Name i,CurPart -ErrorAction SilentlyContinue;
        } # End: else (Entity global variable exists)
    } # End: else (version exists)

}  # End Function: Get-CollectionEntity
