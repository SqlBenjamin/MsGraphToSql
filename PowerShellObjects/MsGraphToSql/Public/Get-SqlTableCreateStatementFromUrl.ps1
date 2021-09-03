# Get-SqlTableCreateStatementsFromUrl; needs a good checking...
function Get-SqlTableCreateStatementsFromUrl {
<#
.SYNOPSIS
    This function builds a SQL CREATE TABLE command with the provided Graph URL.
.DESCRIPTION
    The function creates a CREATE TABLE command (string) which can be used to create a table based on the Graph URL.
.PARAMETER Url
    This is the Graph URL to use to determine the column definition and therefore the CREATE TABLE command.
.PARAMETER UriPart
    This is a portion of the Url. This is really just used for backward compatibility.
.PARAMETER UriVersion
    This is a portion of the Url. This is really just used for backward compatibility.
.PARAMETER UriExpandCols
    This is a portion of the Url. This is really just used for backward compatibility.
.PARAMETER SqlSchemaName
    The name of the schema to use in the CREATE TABLE command. Default is "dbo".
.PARAMETER SqlTableName
    The name of the table to use in the CREATE TABLE command. If not specified the name will be auto determined based on the Url/Graph metadata.
.EXAMPLE
    Get-SqlTableCreateStatementsFromUrl -Url 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$expand=assignments';
    This will create a CREATE TABLE command for 'dbo.mobileApps'. The columns will be based on the schema information from Graph - the beta version of the metadata.
.EXAMPLE
    Get-SqlTableCreateStatementsFromUrl -UriPart 'deviceAppManagement/mobileApps' -UriVersion 'beta' -UriExpandCols 'assignments';
    This will create a CREATE TABLE command for 'dbo.mobileApps'. This is the exact same as the previous example using the full URL.
    The columns will be based on the schema information from Graph - the beta version of the metadata.
.NOTES
    NAME: Get-SqlTableCreateStatementsFromUrl
    HISTORY:
        Date          Author                    Changes
        08/08/2018    Benjamin Reynolds         Initial creation as function from previous ps1 file.
        09/04/2018    Benjamin Reynolds         Fixed special table name creation if a specific table is passed in and the URL is a drill down type of URL
        10/22/2018    Benjamin Reynolds         Updated to handle inherited properties dynamically so that any properties returned will be added.

    ISSUES/THOUGHTS:
        This really needs to be looked at and see if it can just reuse the other functions that do a lot of this.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='FullUrl')][String]$Url
       ,[Parameter(Mandatory=$true,ParameterSetName='UriParts')][String]$UriPart
       ,[Parameter(Mandatory=$true,ParameterSetName='UriParts')][String]$UriVersion
       ,[Parameter(Mandatory=$false,ParameterSetName='UriParts')][String]$UriExpandCols
       ,[Parameter(Mandatory=$false)][String]$SqlSchemaName='dbo'
       ,[Parameter(Mandatory=$false)][String]$SqlTableName
    )

    ##     
    # Create empty/null variables ??
    #if ($UriExpandCols -or $Url -match '[?].*(expand=).*') {
    #    [String]$ExpandParam = $null;
    #}

    if ($PsCmdlet.ParameterSetName -eq 'FullUrl') { ## Need to create UriPart, UriVersion, UriExpandCols, ??
        if ($Url.IndexOf('graph.microsoft.com/') -ne -1) {
            $UriStartInd = $Url.IndexOf('graph.microsoft.com/')+20;
        }
        else {
            $UriStartInd = 0;
        }
        $UriVersion = $Url.Substring($UriStartInd,$Url.IndexOf('/',$UriStartInd)-$UriStartInd);
        $UriPart = $Url.Substring($UriStartInd+$UriVersion.Length+1);    
        if ($UriPart.IndexOf('?') -ne -1) {
            $QryParamPart = $Url.Substring($Url.IndexOf('?'),($Url.Length - $Url.IndexOf('?')));
            #$QryParamParts = $QryParamPart.Replace('?','') -split '&'
            $UriPart = $UriPart.Substring(0,$UriPart.IndexOf('?'));

            foreach ($QryParam in ($QryParamPart.Replace('?','').Replace(' ','').Replace('$','') -split '&')) {
                #
                Switch ($QryParam.Substring(0,$QryParam.IndexOf('='))) {
                        #"count" {'do something?';break;}
                        "expand"  {
                            $UriExpandCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                            break;
                        }
                        #"filter" {'do something?';break;}
                        #"format" {'do something?';break;}
                        #"orderby" {'do something?';break;}
                        #"search" {'do something?';break;}
                        "select" {
                            $UriSelectCols = $QryParam.Substring($QryParam.IndexOf('=')+1);
                            break;
                        }
                        #"skip" {'do something?';break;}
                        #"skipToken" {'do something?';break;}
                        #"top" {'do something?';break;}
                        #default {'do something?';break;}
                }
                
                if ($UriExpandCols.IndexOf('(') -ne -1) {
                    #throw "I'm not going to deal with this type of url just yet...perhaps in a later iteration but not now." Example: categories(select=blah,blah2,blah3),assignments
                    # maybe for now let's just remove all the select crap and keep just the expand portion?
                    foreach ($Parentheses in $UriExpandCols.Split(')')) {
                        if ($Parentheses) {
                            $ExpandParam += $Parentheses.Substring(0,$Parentheses.IndexOf('('));
                        }
                    }
                }
                else {
                    $ExpandParam = $UriExpandCols;
                }
            }
        }

    } # End: ParameterSetName -eq 'FullUrl'
    else {
        if ($UriExpandCols) {
            $ExpandParam = $UriExpandCols;
        }
    }
    
    ## 
    $UriParts = $UriPart -split "/";
    # Reverse the order of the array for now:
    [array]::Reverse($UriParts);

    ## This gets the EntityType Name for the given Uri:
    foreach ($NavPrp in (Get-CollectionEntity -UrlPartsReversed $UriParts -Version $UriVersion).NavigationProperty) {
        if ($NavPrp.Name -eq $UriParts[0]) {
            $MetaDataEntityName = $NavPrp.Type.Replace("Collection(","").Replace(")","");
            break; # stop the foreach as soon as we find it...
        }
    }

    if ($SqlTableName) {
        $TableName = $SqlTableName;
    }
    else {
        $TableName = $UriParts[0];
    }
    
    ## This builds the table name for 'drill down' URL types unless the table name was passed in:
    if ($UriParts.Count -gt 2) {
        # this will take something like this 'deviceManagement/deviceConfigurations/{id}/{odata.type}/managedDeviceCertificateStates' and make the table name 'deviceConfigurations_managedDeviceCertificateStates'
        if (-not $SqlTableName) {
            # put the array back in the original order:
            [array]::Reverse($UriParts);
            $TableName = "$($UriParts[1])_$($TableName)";
            # Reverse the order again to put it back to reverse order in case called again later:
            [array]::Reverse($UriParts);
        }
        # We assume that since the URL has this many 'parts' that it is a drill down type of uri and therefore will have parent columns
        $ParentCols = $true;
    }
    
    # Get MetaData Column Definition:
    if ($ExpandParam) {
        $ColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $MetaDataEntityName -ExpandedColumns $ExpandParam -Version $UriVersion;
        # Get an object with the expanded columns' column definition for use in the batch loop?
        $ExpandParamColDef = Get-ExpandedColDefWithInheritedProps -GraphMetaDataEntityName $MetaDataEntityName -ExpandedColumns $ExpandParam -Version $UriVersion;
        #$ExpandTableName = "$($TableName)_$($ExpandParam)"
    }
    else {
        $ColDef = Get-ColumnDefWithInheritedProps -GraphMetaDataEntityName $MetaDataEntityName -Version $UriVersion;
    }
    
    if ($ParentCols) {
        $CCD = New-Object System.Collections.ArrayList;
        
        # Let's hardcode a "ParentOdataType" and a "ParentId" since that wouldn't be included otherwise:
          # Not my favorite way to do things, but...gotta do what we gotta do...
        $CCO = New-Object -TypeName PSObject -Property @{"DataName" = "ParentOdataType";"Name" = "ParentOdataType";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
        [void]$CCD.Add($CCO);
        Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
        $CCO = New-Object -TypeName PSObject -Property @{"DataName" = "ParentId";"Name" = "ParentId";"Type" = "String";"Nullable" = "false";"IsCollection" = "false"};
        [void]$CCD.Add($CCO);
        Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
        ## End hardcoding the parent columns
        
        foreach ($c in $ColDef) {
            #dynamically build the hash table to use for the PSObject:
            $CurHash = New-Object -TypeName System.Collections.Hashtable;
            foreach ($itm in $c.PSObject.Properties) {
                if ($itm.Name -notin ('ParentOrder','PropertyOrder')) {
                    $CurHash[$itm.Name] = $itm.Value;
                }
            }
            Remove-Variable -Name itm -ErrorAction SilentlyContinue;
            ## Make sure each column has IsCollection set:
            #if (-not $CurHash.IsCollection) {
            #    $CurHash["IsCollection"] = "false";
            #}
            
            $CCO = New-Object -TypeName PSObject -Property $CurHash;
            Remove-Variable -Name CurHash -ErrorAction SilentlyContinue;

            [void]$CCD.Add($CCO);
            Remove-Variable -Name CCO -ErrorAction SilentlyContinue;
        }
        Remove-Variable -Name ColDef,c -ErrorAction SilentlyContinue;
    
        $ColDef = $CCD;
        Remove-Variable -Name CCD -ErrorAction SilentlyContinue;
    }
    
    [String]$SqlCreateTableStatements = Get-SqlTableDefinition -TableName $TableName -ColumnDefinition $ColDef -SchemaName $SqlSchemaName;
    if ($ExpandParamColDef) {
        $SqlCreateTableStatements += "`r`n`r`n";
        foreach ($expCol in $ExpandParamColDef) {
            $ExpTblName = "$($TableName)_$($expCol.ExpandedColName)";
            $SqlCreateTableStatements += Get-SqlTableDefinition -TableName $ExpTblName -ColumnDefinition $expCol.ColumnDefinition -SchemaName $SqlSchemaName;
            $SqlCreateTableStatements += "`r`n`r`n";
        }
        Remove-Variable -Name expCol,ExpTblName -ErrorAction SilentlyContinue
    }
    
    return $SqlCreateTableStatements;

    # Cleanup:
    Remove-Variable -Name QryParamPart,UriPart,UriParts,MetaDataEntityName,TableName,SelectParam,ExpandParam,ExpandParamColDef,ColDef,ParentCols,CCD,CCO -ErrorAction SilentlyContinue

} # End Function: Get-SqlTableCreateStatementFromUrl
