# Get-ColumnDefinitionsAndCompare; check this for optimization?
function Get-ColumnDefinitionsAndCompare {
<#
.SYNOPSIS
    This function compares the column definition from SQL and Graph. 
.DESCRIPTION
    The function uses the definitions captured from SQL and Graph in order to create a definition that will be used to create the final
    DataTable (using ConvertTo-DataTable). This is helpful because this allows us to define a "DataName" for properties. If we define a
    column named "odatatype" without a DataName (of "@odata.type") then we wouldn't be able to pick up this data in the data table from the data captured.
    Thus, we add a DataName to each property so that the data table can be created appropriately.
    If there are properties found in Graph but not found in SQL, we alert that but only the properties for which there is a SQL column are preserved.
    Before returning the new column definition (combining the properties from SQL and Graph) we alert (to the host) the properties that have been added or removed.
.PARAMETER GraphMetaDataColumnDefinition
    This is an object containing the 'column definition' or property definition from Graph. For example, using "Get-ColumnDefWithInheritedProps" to create the object. 
.PARAMETER SqlColumnDefinition
    This is an object containint the column definition from a SQL table. For example, using "Get-SqlTableColumnDefinition" to create the object.
.PARAMETER LogFullPath
    This is the path to a log file if we should be writing to a log. This can be null/empty and nothing will be written.
.EXAMPLE
    Get-ColumnDefinitionsAndCompare -GraphMetaDataColumnDefinition [An Object From Calling "Get-ColumnDefWithInheritedProps"] -SqlColumnDefinition [An Object From Calling "Get-SqlTableColumnDefinition"];
    This will combine and compare the two column definition objects from Sql and Graph into one column definition.
.NOTES
    NAME: Get-ColumnDefinitionsAndCompare
    HISTORY:
        Date          Author                    Notes
        04/03/2018    Benjamin Reynolds         Initial Creation
        08/28/2018    Benjamin Reynolds         Updated logic.
        10/17/2018    Benjamin Reynolds         Updated flagging a SQL column that is not found in the Graph definition to be a "Collection"
                                                if certain criteria are met. This means the column will be treated as a JSON column when it is
                                                converted to a DataTable later. *Not sure if I want to keep this or not...workaround for WIPs.
        12/14/2018    Benjamin Reynolds         Updated Add-Member items to the Add method since we're creating hashtables...
        03/24/2021    Benjamin Reynolds         Added LogFullPath and writing to log file logic.

    ISSUES/THOUGHTS:
        *The added/removed logic could be better reported back in an object for Sql logging...
#>
    [cmdletbinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true)]$GraphMetaDataColumnDefinition
       ,[Parameter(Mandatory=$true)]$SqlColumnDefinition
       ,[Parameter(Mandatory=$false)][AllowNull()][AllowEmptyString()][string]$LogFullPath
    )

    [bool]$isVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true;

    ## First let's compare the column definitions and create a new/combined column definition to be able to handle when the data has a different column name than what we want/have in SQL:
     # this is used to send to the ConvertTo-DataTable function
       ### OLD:
       ###$SqlColumnDefinition | % {
       ###    $p = [array]::IndexOf($GraphMetaDataColumnDefinition.Name,$_.Name)
       ###
       ###    if ($p -gt -1) {
       ###        $_ | Add-Member -MemberType NoteProperty -Name "DataName" -Value $GraphMetaDataColumnDefinition[$p].DataName
       ###        $_ | Add-Member -MemberType NoteProperty -Name "IsCollection" -Value $GraphMetaDataColumnDefinition[$p].IsCollection
       ###    }
       ###    else {# The property falls into the "RemovedCols":
       ###        $_ | Add-Member -MemberType NoteProperty -Name "DataName" -Value $_.Name
       ###    }
       ###    Remove-Variable -Name p
       ###}
    foreach ($SqlCol in $SqlColumnDefinition) {
        ## determine if the column exists in the Graph definition for the Column name in SQL by getting the index number from the array:
        $p = [array]::IndexOf($GraphMetaDataColumnDefinition.Name,$SqlCol.Name);
        ## if the column exists in the graph data add the "DataName" and "IsCollection" properties to the Sql definition:
        if ($p -gt -1) {
            #Add-Member -InputObject $SqlCol -MemberType NoteProperty -Name "DataName" -Value $GraphMetaDataColumnDefinition[$p].DataName;
            #Add-Member -InputObject $SqlCol -MemberType NoteProperty -Name "IsCollection" -Value $GraphMetaDataColumnDefinition[$p].IsCollection;
            ## Since it's a hashtable we'll use the Add method instead of Add-member....
            $SqlCol.Add("DataName",$GraphMetaDataColumnDefinition[$p].DataName);
            $SqlCol.Add("IsCollection",$GraphMetaDataColumnDefinition[$p].IsCollection);
        }
        ## otherwise just use the same column name as the "DataName":
        else {
            
            # Adding this to account for times when the metadata doesn't explicitly show a column/property but the SQL definition does...we'll mark it as a collection so it'll convert to JSON (in case it is) when converted to a datatable:
            if ($SqlCol.Type -eq 'String' -and [string]::IsNullOrEmpty($SqlCol.MaxLength) -eq $true -and $SqlCol.Name.IndexOf('_JSON') -gt -1) {
                #Add-Member -InputObject $SqlCol -MemberType NoteProperty -Name "DataName" -Value $SqlCol.Name.Replace('_JSON','');
                #Add-Member -InputObject $SqlCol -MemberType NoteProperty -Name "IsCollection" -Value $true;
                ## Since it's a hashtable we'll use the Add method instead of Add-member....
                $SqlCol.Add("DataName",$SqlCol.Name.Replace('_JSON',''));
                $SqlCol.Add("IsCollection",$true);
            }
            else {
                #Add-Member -InputObject $SqlCol -MemberType NoteProperty -Name "DataName" -Value $SqlCol.Name;
                ## Since it's a hashtable we'll use the Add method instead of Add-member....
                $SqlCol.Add("DataName",$SqlCol.Name);
            }
        }
        Remove-Variable -Name p -ErrorAction SilentlyContinue;
    }
    Remove-Variable -Name SqlCol -ErrorAction SilentlyContinue;
    
    
    if ($isVerbose -or (-Not [String]::IsNullOrWhiteSpace($LogFullPath)))
    {
        #### This next portion is only to do any alerting of properties being added or removed (meaning, there's a difference in the SQL columns and Graph properties)
        ## Compare the definition in SQL to the XML/Data Received to get any column differences:
         # We're only looking at column name here - not comparing Type or Nullable
           ##OLD: $ColsRemoved = $SqlColumnDefinition | % {if (!($_.Name -in $GraphMetaDataColumnDefinition.Name)) {$_}}
        $ColsRemoved = foreach ($SqlCol in $SqlColumnDefinition) {
                           if ($SqlCol.Name -notin $GraphMetaDataColumnDefinition.Name) {
                               $SqlCol;
                           }
                       }
        Remove-Variable -Name SqlCol -ErrorAction SilentlyContinue;
           ##OLD: $ColsAdded = $GraphMetaDataColumnDefinition | % {if (!($_.Name -in $SqlColumnDefinition.Name)) {$_}}
        $ColsAdded = foreach ($GrphCol in $GraphMetaDataColumnDefinition) {
                         if ($GrphCol.Name -notin $SqlColumnDefinition.Name) {
                             $GrphCol;
                         }
                     }
        Remove-Variable -Name GrphCol -ErrorAction SilentlyContinue;
        
        ## If there were any property differences, let's alert that:
        if ($ColsRemoved) {
            Write-CmTraceLog -LogMessage "Column(s) Removed! The removed columns will be ignored for now but this should be taken care of ASAP!" -LogFullPath $LogFullPath -Component 'Get-ColumnDefinitionsAndCompare' -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "$($ColsRemoved.Name.Count) Column(s) Removed. The Removed Column(s) is/are:`r`n$($ColsRemoved.Name -join ",")" -LogFullPath $LogFullPath -Component 'Get-ColumnDefinitionsAndCompare' -Verbose:$isVerbose;
        }
        if ($ColsAdded) {
            Write-CmTraceLog -LogMessage "Column(s) Added! The added columns will be ignored but this should be taken care of ASAP!" -LogFullPath $LogFullPath -Component 'Get-ColumnDefinitionsAndCompare' -Verbose:$isVerbose;
            Write-CmTraceLog -LogMessage "$($ColsAdded.Name.Count) Column(s) Added. The Added Column(s) is/are:`r`n$($ColsAdded.Name -join ",")" -LogFullPath $LogFullPath -Component 'Get-ColumnDefinitionsAndCompare' -Verbose:$isVerbose;
        }
        # Cleanup our Removed/Added objects:
        Remove-Variable -Name ColsRemoved,ColsAdded -ErrorAction SilentlyContinue;
        #### End of Property difference checking/alerting
    }

    return $SqlColumnDefinition;

} # End Function: Get-ColumnDefinitionsAndCompare
