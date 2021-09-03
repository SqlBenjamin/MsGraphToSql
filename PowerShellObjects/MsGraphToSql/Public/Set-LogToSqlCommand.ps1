# Set-LogToSqlCommand
function Set-LogToSqlCommand {
<#
.SYNOPSIS
    This function creates the command to use to log the IntuneSync stuff to SQL.
.DESCRIPTION
    The function builds either an INSERT or UPDATE command with the given data in order to write the information to SQL correctly.
.PARAMETER JobName
    If starting the script this will log the job that is running the script or needs to be null for any ad-hoc execution of the script.
.PARAMETER TableToLog
    If starting the logging of a table within the script, the table name must be passed in here. This is only required when initially logging the table.
.PARAMETER BatchId
    If starting the logging of a table within the script, the batch id can be passed in if one exists; it is only optional when initially logging the table.
.PARAMETER LogTableRowId
    When updating a table that has started the logging the ID for the table must be passed in so that only that record is updated.
.PARAMETER IsFirstXml
    If writing XML information to the ExtendedInfo column for the first time (for the given table) this is required so that the SET command is built properly.
    This will write the XML for ExtendedInfo into the column as is (which would overwrite the data if not the first time).
.PARAMETER AttrName
    If updating XML information to the ExtendedInfo column AND adding properties for an already logged portion (aka UriPart) this is required.
    Examples of this are: 'UriPart' and 'ReportName'
.PARAMETER AttrValue
    If updating XML information to the ExtendedInfo column AND adding properties for an already logged portion (aka UriPart) this is required.
    This is the name of the 'UriPart' or XML element that should be updated within the XML.
.PARAMETER LogToTable
    This is the name of the table that will be used in the INSERT or UPDATE command. If this isn't provided the default value of '[[LogToTable]]' will be used and will need to be replaced.
.PARAMETER PropertyValues
    This is only available when starting to log to a table or when updating a table.
    This must be either a hashtable or a dictionary (i.e., OrderedDictionary).
    The key value pairs will contain the columns to update with the values to update with.
    * If logging the completion of a table or job the "EndDateUTC" is required! (and can't be null)*
.EXAMPLES
    Set-LogToSqlCommand -JobName 'ECM_Test';
    Set-LogToSqlCommand -JobName $null;
    Set-LogToSqlCommand -JobName $null -LogToTable 'dbo.SomeTable';
    Set-LogToSqlCommand -TableToLog 'BlahBlah' -BatchId 987 -PropertyValues @{StartDateUTC = 'DEFAULT'};
    Set-LogToSqlCommand -TableToLog 'BlahBlah' -BatchId 987;
    Set-LogToSqlCommand -TableToLog 'BlahBlah' -BatchId $null -PropertyValues @{StartDateUTC = 'DEFAULT'};
    Set-LogToSqlCommand -TableToLog 'BlahBlah' -BatchId $null;
    Set-LogToSqlCommand -TableToLog 'BlahBlah' -BatchId $null -PropertyValues @{StartDateUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"))};
    Set-LogToSqlCommand -TableToLog 'BlahBlah';
    Set-LogToSqlCommand -LogTableRowId 123 -IsFirstXml -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt};
    Set-LogToSqlCommand -LogTableRowId 123 -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt}; # 'ExtendedInfo.modify(insert as last)'
    Set-LogToSqlCommand -LogTableRowId 123 -AttrName $UriType -AttrValue $CurUriPart -PropertyValues @{ExtendedInfo = $SqlXmlLogTxt}; # 'ExtendedInfo.modify(insert into @key = value)'
    Set-LogToSqlCommand -LogTableRowId 123 -PropertyValues @{EndDateUTC = $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"));ErrorNumber = -7;ErrorMessage = $ErrMsg;ExtendedInfo = $SqlXmlLogTxt};
    Set-LogToSqlCommand -LogTableRowId 123 -PropertyValues @{EndDateUTC = 'NULL';ErrorNumber = -7;ErrorMessage = $ErrMsg;ExtendedInfo = $SqlXmlLogTxt};
    Set-LogToSqlCommand -LogTableRowId 123 -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()';ErrorNumber = -7;ErrorMessage = $ErrMsg;ExtendedInfo = $SqlXmlLogTxt};
    Set-LogToSqlCommand -LogTableRowId 123 -PropertyValues @{EndDateUTC = 'SYSUTCDATETIME()'};
.OUTPUTS
    A string containing the SQL DML command.
.NOTES
    NAME: Set-LogToSqlCommand
    HISTORY:
        Date                Author                    Notes:
        03/15/2021          Benjamin Reynolds         Initial Creation
        06/11/2021          Benjamin Reynolds         Fixed issue with AttrValue not properly getting encoded for SQL.

    NOTES:
        -the xml string in ExtendedInfo must come pre-escaped.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='JobStart')][AllowNull()][AllowEmptyString()][string]$JobName
       ,[Parameter(Mandatory=$true,ParameterSetName='TableStart')][ValidateScript({-Not [String]::IsNullOrWhiteSpace($PSItem)})][string]$TableToLog
       ,[Parameter(Mandatory=$false,ParameterSetName='TableStart')][AllowNull()][System.Nullable[int]]$BatchId
       ,[Parameter(Mandatory=$true,ParameterSetName='Updates')][int]$LogTableRowId
       ,[Parameter(Mandatory=$false,ParameterSetName='Updates')][switch]$IsFirstXml
       ,[Parameter(Mandatory=$false,ParameterSetName='Updates')][string]$AttrName
       ,[Parameter(Mandatory=$false,ParameterSetName='Updates')][string]$AttrValue
       ,[Parameter(Mandatory=$false,HelpMessage='This is the logging table to which you want to write.')][string]$LogToTable = '[[LogToTable]]'
       ,[Parameter(Mandatory=$true,ParameterSetName='Updates')]
        [Parameter(Mandatory=$false,ParameterSetName='TableStart')]
        #[Parameter(Mandatory=$false,ParameterSetName='JobStart')] # currently not supported when it's a job start
        [ValidateScript({$PSItem.GetType().Name -like '*Dictionary*' -or $PSItem.GetType().Name -like '*Hashtable*'})]$PropertyValues
    )

    ## Start Of Job:
    if ($PsCmdlet.ParameterSetName -eq 'JobStart')
    {
        $JobName = if ([String]::IsNullOrWhiteSpace($JobName)) {"NULL";} else {"N'$JobName'";}
        return "INSERT $LogToTable (StartDateUTC,JobName) VALUES (DEFAULT,$JobName); SELECT SCOPE_IDENTITY() AS [ID];";
    }

    ## Start of Table:
    if ($PsCmdlet.ParameterSetName -eq 'TableStart')
    {
        [string]$Batch = if ($null -eq $BatchId) {'DEFAULT';} else {$BatchId;}
        [string]$StartDateUTC = if ($PropertyValues) {$PropertyValues['StartDateUTC'];} else {$null;};
        $StartDateUTC = if (-Not [String]::IsNullOrWhiteSpace($StartDateUTC) -and $StartDateUTC -ne 'DEFAULT') {"'$StartDateUTC'";} else {"DEFAULT";};
        return "INSERT $LogToTable (TableName,BatchID,StartDateUTC) VALUES (N'$TableToLog',$Batch,$StartDateUTC); SELECT SCOPE_IDENTITY() AS [ID];";
    }

    ## If we made it this far we are updating the table:
    [string]$declareCmd = "";
    [string]$setCmd = "";

    ## Some Helper/Logic stuff
    if ($PropertyValues)
    {
        [bool]$IsEnd = if (-Not [String]::IsNullOrWhiteSpace($PropertyValues['EndDateUTC'])) {$true;} else {$false;}
    }

    ## XML Updates or End of Job/Table:
    foreach ($xmlVal in $PropertyValues.GetEnumerator())
    {
        $Key = $xmlVal.Key;
        $Value = $xmlVal.Value;
        
        ## We're only going to allow Specific Keys to weed out the trash:
        if ($Key -notin ('StartDateUTC','EndDateUTC','ErrorNumber','ErrorMessage','ExtendedInfo'))
        {
            continue;
        }
       
        if (-Not ([String]::IsNullOrWhiteSpace($Value)))
        {
            ## Fix Values for the SET Command:
            if ($Key -eq 'StartDateUTC' -and $Value -notin ('NULL','SYSUTCDATETIME()')) {$Value = "'$Value'";}
            if ($Key -eq 'EndDateUTC' -and $Value -notin ('NULL','SYSUTCDATETIME()')) {$Value = "'$Value'";}
            if ($Key -eq 'ErrorMessage') {$Value = "N'$($Value.Replace("'","''"))'"}
            
            ## Handle XML Stuff
            if ($Key -eq 'ExtendedInfo')
            {
                $declareCmd = "DECLARE @XmlInfo xml = '$Value'; ";
                if ((-not [String]::IsNullOrWhiteSpace($AttrName)) -and (-not [String]::IsNullOrWhiteSpace($AttrValue)))
                {
                    $setCmd += ",$Key.modify(N'insert sql:variable(""@XmlInfo"") into (/SpecificURLs/SpecificURL[@$AttrName = ""$($AttrValue.Replace("'","''").Replace('&','&amp;'))""])[1]')";
                }
                elseif ((-Not $IsEnd) -and (-Not $IsFirstXml) -and [String]::IsNullOrWhiteSpace($AttrName) -and [String]::IsNullOrWhiteSpace($AttrValue))
                {
                    $setCmd += ",$Key.modify(N'insert sql:variable(""@XmlInfo"") as last into (/SpecificURLs)[1]')";
                }
                else # IsFirstXml OR IsEnd -eq $true (AND AttrName and AttrValue DO NOT EXIST)
                {
                    $setCmd += ",$Key = @XmlInfo";
                }
                ## Original logic slightly flawed: when enddate exists and just need to update a record this did not work:
                ####if ((-Not $IsEnd) -and (-Not $IsFirstXml) -and [String]::IsNullOrWhiteSpace($AttrName) -and [String]::IsNullOrWhiteSpace($AttrValue))
                ####{
                ####    $setCmd += ",$Key.modify(N'insert sql:variable(""@XmlInfo"") as last into (/SpecificURLs)[1]')";
                ####}
                ####elseif ((-Not $IsEnd) -and (-Not $IsFirstXml))
                ####{
                ####    $setCmd += ",$Key.modify(N'insert sql:variable(""@XmlInfo"") into (/SpecificURLs/SpecificURL[@$AttrName = ""$($AttrValue.Replace('&','&amp;'))""])[1]')";
                ####}
                ####else # IsFirstXml OR IsEnd -eq $true
                ####{
                ####    $setCmd += ",$Key = @XmlInfo";
                ####}
            }
            else
            {
                $setCmd += ",$Key = $Value";
            }
        }
    }

    # Create the Return command and return it:
    return "$($declareCmd)UPDATE $LogToTable SET $($setCmd.Substring(1)) WHERE ID = $LogTableRowId;";
} # End: Set-LogToSqlCommand
