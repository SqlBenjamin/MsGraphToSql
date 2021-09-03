# ConvertTo-DataTable
function ConvertTo-DataTable {
<#
.SYNOPSIS
    This function is used to convert an object to a data table object
.DESCRIPTION
    The function creates a DataTable object with the column definition provided and then fills it with the information from the provided input object
.PARAMETER InputObject
    This is an object containing the data that will be converted to the data table - insert these "records"
    Required.
.PARAMETER ColumnDef
    This is the table definition which is to be used to create the data table.
    If an InputObject is passed (GraphObject parameters):
      The definition must contain the properties: Name, Type, Nullable; with DataName, ColRemoved optional. (Any other properties are currently ignored)
    If the ZipFileName is pased (ReportExport parameters):
      The definition is for the destination SQL table only - if the file has a column of the same name as the SQL table (or MappedColumnName) then the datatype and nullability
      information from the SQL table will be used to define the column, otherwise the data will just be added as found in the file. To properly import this
      resulting datatable a ColumnMapping should be created in the BulkCopy insert.
    Required.
.PARAMETER ZipFileName
    When this is used instead of the InputObject or ZipFileUrl the data used to create the datatable is from a csv file located inside the zip file, which is retrieved from
    the file location passed in to this paramater.
.PARAMETER ZipFileUrl
    When this is used instead of the InputObject or ZipFileName the data used to create the datatable is from a csv file located inside the zip file, which is
    downloaded via the URL - the file is downloaded in memory rather than to disk.
.EXAMPLE
    ConvertTo-DataTable -InputObject $ObjectWithData -ColumnDef $ObjectContainingColumnDefinitions
    Converts the data in the input object to a data table using the columns and data types from the column definition input object
.EXAMPLE
    ConvertTo-DataTable -ZipFileName "C:\Windows\Temp\SomeZipContainingACsvFile.zip" -ColumnDef $SqlTableDefinition;
    Creates a filestream reader for the csv file found within the zip file and converts the data to a data table. Columns are defined if the column exists in the
    SQL table otherwise the column is added as a generic column (string/null/etc).
.INPUTS
    An object with property names (that match the ColumnName's in the ColumnDef parameter) and associated data and an object containing the column definitions
.OUTPUTS
    A "System.Data.DataTable" object containing all the data from the input object for the "columns" provided in the ColumnDef parameter
.NOTES
    NAME: ConvertTo-DataTable
    HISTORY:
        Date          Author                    Notes
        12/04/2017    Benjamin Reynolds
        03/28/2018    Benjamin Reynolds         Accounting for a data name and a column name;
                                                Added missing property handling (for not null properties)
        04/02/2018    Benjamin Reynolds         Added handling of 'collection' columns - JSON
        08/23/2018    Benjamin Reynolds         Updated some formatting and made some minor changes to logic
        12/14/2018    Benjamin Reynolds         Added the ability to store all the information from Graph into a column "AllData_JSON" if it exists.
        01/27/2021    Benjamin Reynolds         Added functionality to create a datatable from a csv located in a zip file - this is to handle the
                                                new Intune V2 Report Export API stuff - once the zip file is on disk this will create a datatable
                                                from the csv within the zip file - and use the datatype/nullability info from the ColumnDef (aka the
                                                SQL table definition).
        01/28/2021    Benjamin Reynolds         Added a check for the Report Export/zip file stuff to handle the scenario when the SQL table has a column
                                                that isn't returned in the csv file. Added verbose information.
        02/25/2021    Benjamin Reynolds         Added MappedColumnName logic. Added ability to create from a download URL as well.
        07/30/2021    Benjamin Reynolds         Updated ReportExport logic to remove escaped double quotes (since the data is quoted due to csv).
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='GraphObject')]$InputObject
       ,[Parameter(Mandatory=$true,ParameterSetName='ReportExportFile')][string]$ZipFileName
       ,[Parameter(Mandatory=$true,ParameterSetName='ReportExportUrl')][string]$ZipFileUrl
       ,[Parameter(Mandatory=$true)]$ColumnDef
    )

    $StartTime = $(Get-Date);

    $DtaTbl = New-Object -TypeName System.Data.DataTable;
    
    if ($PsCmdlet.ParameterSetName -eq 'GraphObject')
    {
        Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Creating the DataTable columns ...";
        
        ## Create the DataTable (based on the column definitions passed in):
        foreach ($tblcol in $ColumnDef) {
            if ($tblcol.Nullable -eq "true" -or $tblcol.Nullable -eq $true) {
                $CurNul = $true;
            }
            else {
                $CurNul = $false;
            }
            #########################################################################################################
            #####  this is for backwards compatibility...consider removing at a later time...
            # This handles Odata where a column has a name with an asterisk in it, i.e., "@odata.type" --> "odatatype"
            if ($tblcol.Name -like "*@*" -or $tblcol.Name -like "*.*") {
                $ColName = $tblcol.Name.Replace('@','').Replace('.','');
            }
            else {
                $ColName = $tblcol.Name;
            }
            #########################################################################################################
            $CurCol = New-Object System.Data.DataColumn;
            $CurCol.ColumnName = $ColName;
            $CurCol.DataType = $tblcol.Type;
            $CurCol.AllowDBNull = $CurNul;
        
            $DtaTbl.Columns.Add($CurCol);
            Write-Verbose "Column $ColName Added to Data Table Definition";
            Remove-Variable -Name ColName,CurNul,CurCol -ErrorAction SilentlyContinue;
        } # end creating DataTable

        Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Populating the DataTable rows ...";
        
        ## Fill the DataTable with the data from the InputObject
        foreach ($Rec in $InputObject) {
            $CurRow = $DtaTbl.NewRow();
            foreach ($col in $ColumnDef) {
                # This works if not converting the Odata column names: # The original working code
                <#if ($(($Rec).($col.Name)) -or $(($Rec).($col.Name)) -eq $false) {
                    $CurRow["$($col.Name)"] = ($Rec).($col.Name)
                }#>
                
                if ($col.DataName) {
                    $DataName = $col.DataName;
                    $ColName = $col.Name;
                }
                else {
                    $DataName = $col.Name;
                    #### This is for backwards compatibility...
                    # This handles the Odata column names:
                    if ($col.Name -like "*@*" -or $col.Name -like "*.*") {
                        $ColName = $col.Name.Replace('@','').Replace('.',''); # may consider replacing all special chars?
                    }
                    else {
                        $ColName = $col.Name;
                    }
                }
                
                ## If we're trying to store all info in a special column do it here:
                if ($ColName -eq "AllData_JSON") {
                    $CurRow["$ColName"] = $($Rec | ConvertTo-Json -Compress -Depth 100);
                }
                ## ...otherwise...Check that the property has a value to set, and if so add the info to the record/row:
                elseif ($(($Rec).($DataName)) -or $(($Rec).($DataName)) -eq $false) {
                    
                    ## Add the property to the current record/row:
                    if ($col.IsCollection -eq "true" -or $col.IsCollection -eq $true) {
                        ## If it's a JSON column (it has "IsCollection" set to true), convert the column data to JSON string
                        $CurRow["$ColName"] = $(($Rec).($DataName) | ConvertTo-Json -Compress -Depth 100);
                    }
                    else {
                        ## Add the property to the current record/row:
                        $CurRow["$ColName"] = ($Rec).($DataName);
                    }
                }
                elseif ($col.Nullable -ne "true") { # do I need to change to use $true/$false instead of string?  -or $col.Nullable -ne $true
                    ## We're going to handle properties that don't exist when the property is NOT Nullable:
                    $Val = Switch ($col.Type) {
                                   "String" {"";break;}
                                   "DateTime" {"1900-01-01 00:00:00.000";break;}
                                   "Int64" {-1;break;}
                                   "Int32" {-1;break;}
                                   "Int16" {0;break;}
                                   "Byte" {0;break;}
                                   "Boolean" {0;break;}
                                   "Guid" {"00000000-0000-0000-0000-000000000000";break;}
                                   default {"0";break;}
                           };
                    
                    $CurRow["$ColName"] = $Val;
                    Remove-Variable -Name Val -ErrorAction SilentlyContinue;
                }
            } # end foreach record
            ## add a Remove-Variable here to wipe out some stuff?
        
            ## Now that all properties/columns are added to the record/row, add the row to the table:
            $DtaTbl.Rows.Add($CurRow);
        }
    }
    elseif ($PsCmdlet.ParameterSetName -eq 'ReportExportFile')
    {
        try
        {
            $null = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression');
            
            $fileStream = New-Object System.IO.FileStream($ZipFileName,[System.IO.FileMode]::Open);
            $zipArchive = New-Object System.IO.Compression.ZipArchive($fileStream,[System.IO.Compression.ZipArchiveMode]::Read);
            [System.IO.Compression.ZipArchiveEntry]$zipArchiveEntry = $zipArchive.GetEntry($zipArchive.Entries[0].Name);
            $streamReader = New-Object System.IO.StreamReader($zipArchiveEntry.Open());
            
            $regex = '(,)(?=(?:[^"]|"[^"]*")*$)';

            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Creating the DataTable columns ...";

            ## Create the Columns based on the headers in the first row:
            $line = $streamReader.ReadLine(); ## Gets the header row (the columns)
            [int]$commas = ([regex]::Matches($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)).Count;
            $lineSplit = [regex]::Split($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture);
            for ($i = 0; $i -lt $lineSplit.Count; $i++)
            {
                $ColName = $lineSplit[$i].Substring(1,$lineSplit[$i].Length-2);
                $CurCol = New-Object System.Data.DataColumn;

                $CurCol.ColumnName = $ColName;

                ## If we have a matching column name in the SQL definition then use that IsNull/DataType info
                $p = [array]::IndexOf($ColumnDef.Name,$ColName);
                if ($p -gt -1)
                {
                    $ColInfo = $ColumnDef[$p];
            
                    $CurCol.DataType = $ColInfo.Type;
            
                    if ($ColInfo.Nullable -eq "true" -or $ColInfo.Nullable -eq $true)
                    {
                        $CurCol.AllowDBNull = $true;
                    }
                    else
                    {
                        $CurCol.AllowDBNull = $false;
                    }
            
                    #if ($ColInfo.MaxLength.Length -gt 0 -and $ColInfo.Type -eq 'String')
                    #{
                    #    $CurCol.MaxLength = $ColInfo.MaxLength
                    #}
                }
                else
                {
                    $p = [array]::IndexOf($ColumnDef.MappedColumnName,$ColName);
                    if ($p -gt -1)
                    {
                        $ColInfo = $ColumnDef[$p];
                        
                        $CurCol.DataType = $ColInfo.Type;
                        
                        if ($ColInfo.Nullable -eq "true" -or $ColInfo.Nullable -eq $true)
                        {
                            $CurCol.AllowDBNull = $true;
                        }
                        else
                        {
                            $CurCol.AllowDBNull = $false;
                        }
                        
                        #if ($ColInfo.MaxLength.Length -gt 0 -and $ColInfo.Type -eq 'String')
                        #{
                        #    $CurCol.MaxLength = $ColInfo.MaxLength
                        #}
                    }
                }
            
                $DtaTbl.Columns.Add($CurCol);
            }
            Remove-Variable -Name ColName,CurCol,i,line,lineSplit -ErrorAction SilentlyContinue;
            
            ## If the SQL Table has a column that doesn't exist in the file and is defined as NOT NULL we need to do something about that:
            foreach ($col in $ColumnDef)
            {
                if (-Not ($DtaTbl.Columns.Contains($col.Name) -or $DtaTbl.Columns.Contains($col.MappedColumnName)) -and ($col.Nullable -eq "false" -or $col.Nullable -eq $false))
                {
                    # add the column...
                    $CurCol = New-Object System.Data.DataColumn;
                    $CurCol.ColumnName = $col.Name;
                    $CurCol.AllowDBNull = $false;
                    $CurCol.DataType = $col.Type;
                    $CurCol.DefaultValue = Switch ($col.Type) {
                                                   "String" {"";break;}
                                                   "DateTime" {"1900-01-01 00:00:00.000";break;}
                                                   "Int64" {-1;break;}
                                                   "Int32" {-1;break;}
                                                   "Int16" {0;break;}
                                                   "Byte" {0;break;}
                                                   "Boolean" {0;break;}
                                                   "Guid" {"00000000-0000-0000-0000-000000000000";break;}
                                                   default {"0";break;}
                                           };
                    $DtaTbl.Columns.Add($CurCol);
                    Remove-Variable -Name CurCol -ErrorAction SilentlyContinue;
                }
            }
            Remove-Variable -Name col -ErrorAction SilentlyContinue;
            
            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Populating the DataTable rows ...";

            ## Populate the data table from all the data in the file:
            while (($line = $streamReader.ReadLine()) -ne $null) ## issuing ReadLine again gets all the data records
            {
                ## This is necessary to capture multiple lines when a record has a line feed in the middle of a property:
                 # we add the next line(s) to the current line until we get to the right number of commas (aka columns)
                 # and then proceed:
                 # if the line doesn't end with a " then the regex doesn't work correctly so we'll add it so we get the proper comma count:
                while (($lineCommas = ([regex]::Matches($(if ($line.EndsWith('"')) {$line} else {$line+'"'}),$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)).Count) -ne $commas)
                {
                    if ($lineCommas -lt $commas)
                    {
                        $line += "`n$($streamReader.ReadLine())";
                    }
                    elseif ($lineCommas -gt $commas)
                    {
                        break;
                    }
                }
                
                $lineSplit = [regex]::Split($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture);
            
                $CurRow = $DtaTbl.NewRow();
                for ($r = 0; $r -lt $lineSplit.Count; $r++)
                {
                    # The values are quoted in the csv so we'll remove them and replace any escaped double quotes as well:
                    $Val = $lineSplit[$r].Substring(1,$lineSplit[$r].Length-2).Replace('""','"');

                    if (-Not [String]::IsNullOrWhiteSpace($Val))
                    {
                        $CurRow[$r] = $Val;
                    }
                    elseif ($DtaTbl.Columns[$r].AllowDBNull -eq $false)
                    {
                        $Val = Switch ($DtaTbl.Columns[$r].DataType) {
                                       "String" {"";break;}
                                       "DateTime" {"1900-01-01 00:00:00.000";break;}
                                       "Int64" {-1;break;}
                                       "Int32" {-1;break;}
                                       "Int16" {0;break;}
                                       "Byte" {0;break;}
                                       "Boolean" {0;break;}
                                       "Guid" {"00000000-0000-0000-0000-000000000000";break;}
                                       default {"0";break;}
                               };
                        $CurRow[$r] = $Val;
                    }
                }
                $DtaTbl.Rows.Add($CurRow);
                Remove-Variable -Name r,CurRow -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name line,lineSplit -ErrorAction SilentlyContinue;
        }
        catch
        {
            # Do nothing for now
            Write-Error $PSItem;
        }
        finally
        {
            ## Cleanup:
            if ($streamReader) {$streamReader.Dispose();}
            if ($zipArchive) {$zipArchive.Dispose();}
            if ($fileStream) {$fileStream.Close();}
        }
    }
    else #if ($PsCmdlet.ParameterSetName -eq 'ReportExportUrl')
    {
        try
        {
            $null = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression');

            $webClient = New-Object System.Net.WebClient;

            [byte[]]$zipFile = $webClient.DownloadData($ZipFileUrl);

            # This produces a "System.OutOfMemoryException,Microsoft.PowerShell.Commands.NewObjectCommand" error: $memStream = New-Object System.IO.MemoryStream($zipFile);
            #v5+ only? :
            $memStream = [System.IO.MemoryStream]::new($zipFile);
            
            #$fileStream = New-Object System.IO.FileStream($ZipFileName,[System.IO.FileMode]::Open);
            #$zipArchive = New-Object System.IO.Compression.ZipArchive($fileStream,[System.IO.Compression.ZipArchiveMode]::Read);
            $zipArchive = New-Object System.IO.Compression.ZipArchive($memStream,[System.IO.Compression.ZipArchiveMode]::Read);
            [System.IO.Compression.ZipArchiveEntry]$zipArchiveEntry = $zipArchive.GetEntry($zipArchive.Entries[0].Name);
            $streamReader = New-Object System.IO.StreamReader($zipArchiveEntry.Open());
            
            $regex = '(,)(?=(?:[^"]|"[^"]*")*$)';

            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Creating the DataTable columns ...";

            ## Create the Columns based on the headers in the first row:
            $line = $streamReader.ReadLine(); ## Gets the header row (the columns)
            [int]$commas = ([regex]::Matches($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)).Count;
            $lineSplit = [regex]::Split($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture);
            for ($i = 0; $i -lt $lineSplit.Count; $i++)
            {
                $ColName = $lineSplit[$i].Substring(1,$lineSplit[$i].Length-2);
                $CurCol = New-Object System.Data.DataColumn;

                $CurCol.ColumnName = $ColName;

                ## If we have a matching column name in the SQL definition then use that IsNull/DataType info
                $p = [array]::IndexOf($ColumnDef.Name,$ColName);
                if ($p -gt -1)
                {
                    $ColInfo = $ColumnDef[$p];
            
                    $CurCol.DataType = $ColInfo.Type;
            
                    if ($ColInfo.Nullable -eq "true" -or $ColInfo.Nullable -eq $true)
                    {
                        $CurCol.AllowDBNull = $true;
                    }
                    else
                    {
                        $CurCol.AllowDBNull = $false;
                    }
            
                    #if ($ColInfo.MaxLength.Length -gt 0 -and $ColInfo.Type -eq 'String')
                    #{
                    #    $CurCol.MaxLength = $ColInfo.MaxLength
                    #}
                }
                else
                {
                    $p = [array]::IndexOf($ColumnDef.MappedColumnName,$ColName);
                    if ($p -gt -1)
                    {
                        $ColInfo = $ColumnDef[$p];
                        
                        $CurCol.DataType = $ColInfo.Type;
                        
                        if ($ColInfo.Nullable -eq "true" -or $ColInfo.Nullable -eq $true)
                        {
                            $CurCol.AllowDBNull = $true;
                        }
                        else
                        {
                            $CurCol.AllowDBNull = $false;
                        }
                        
                        #if ($ColInfo.MaxLength.Length -gt 0 -and $ColInfo.Type -eq 'String')
                        #{
                        #    $CurCol.MaxLength = $ColInfo.MaxLength
                        #}
                    }
                }
                Remove-Variable -Name p -ErrorAction SilentlyContinue;
            
                $DtaTbl.Columns.Add($CurCol);
            }
            Remove-Variable -Name ColName,CurCol,i,line,lineSplit -ErrorAction SilentlyContinue;
            
            ## If the SQL Table has a column that doesn't exist in the file and is defined as NOT NULL we need to do something about that:
            foreach ($col in $ColumnDef)
            {
                if (-Not ($DtaTbl.Columns.Contains($col.Name) -or $DtaTbl.Columns.Contains($col.MappedColumnName)) -and ($col.Nullable -eq "false" -or $col.Nullable -eq $false))
                {
                    # add the column...
                    $CurCol = New-Object System.Data.DataColumn;
                    $CurCol.ColumnName = $col.Name;
                    $CurCol.AllowDBNull = $false;
                    $CurCol.DataType = $col.Type;
                    $CurCol.DefaultValue = Switch ($col.Type) {
                                                   "String" {"";break;}
                                                   "DateTime" {"1900-01-01 00:00:00.000";break;}
                                                   "Int64" {-1;break;}
                                                   "Int32" {-1;break;}
                                                   "Int16" {0;break;}
                                                   "Byte" {0;break;}
                                                   "Boolean" {0;break;}
                                                   "Guid" {"00000000-0000-0000-0000-000000000000";break;}
                                                   default {"0";break;}
                                           };
                    $DtaTbl.Columns.Add($CurCol);
                    Remove-Variable -Name CurCol -ErrorAction SilentlyContinue;
                }
            }
            Remove-Variable -Name col -ErrorAction SilentlyContinue;
            
            Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : Populating the DataTable rows ...";

            ## Populate the data table from all the data in the file:
            while (($line = $streamReader.ReadLine()) -ne $null) ## issuing ReadLine again gets all the data records
            {
                ## This is necessary to capture multiple lines when a record has a line feed in the middle of a property:
                 # we add the next line(s) to the current line until we get to the right number of commas (aka columns)
                 # and then proceed:
                 # if the line doesn't end with a " then the regex doesn't work correctly so we'll add it so we get the proper comma count:
                while (($lineCommas = ([regex]::Matches($(if ($line.EndsWith('"')) {$line} else {$line+'"'}),$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture)).Count) -ne $commas)
                {
                    if ($lineCommas -lt $commas)
                    {
                        $line += "`n$($streamReader.ReadLine())";
                    }
                    elseif ($lineCommas -gt $commas)
                    {
                        break;
                    }
                }
                
                $lineSplit = [regex]::Split($line,$regex,[System.Text.RegularExpressions.RegexOptions]::ExplicitCapture);
            
                $CurRow = $DtaTbl.NewRow();
                for ($r = 0; $r -lt $lineSplit.Count; $r++)
                {
                    # The values are quoted in the csv so we'll remove them and replace any escaped double quotes as well:
                    $Val = $lineSplit[$r].Substring(1,$lineSplit[$r].Length-2).Replace('""','"');

                    if (-Not [String]::IsNullOrWhiteSpace($Val))
                    {
                        $CurRow[$r] = $Val;
                    }
                    elseif ($DtaTbl.Columns[$r].AllowDBNull -eq $false)
                    {
                        $Val = Switch ($DtaTbl.Columns[$r].DataType) {
                                       "String" {"";break;}
                                       "DateTime" {"1900-01-01 00:00:00.000";break;}
                                       "Int64" {-1;break;}
                                       "Int32" {-1;break;}
                                       "Int16" {0;break;}
                                       "Byte" {0;break;}
                                       "Boolean" {0;break;}
                                       "Guid" {"00000000-0000-0000-0000-000000000000";break;}
                                       default {"0";break;}
                               };
                        $CurRow[$r] = $Val;
                    }
                }
                $DtaTbl.Rows.Add($CurRow);
                Remove-Variable -Name r,CurRow -ErrorAction SilentlyContinue;
            }
            Remove-Variable -Name line,lineSplit -ErrorAction SilentlyContinue;
        }
        catch
        {
            # Do nothing for now
            Write-Error $PSItem;
        }
        finally
        {
            ## Cleanup:
            if ($memStream) {$memStream.Dispose();}
            if ($streamReader) {$streamReader.Dispose();}
            if ($zipArchive) {$zipArchive.Dispose();}
        }
    }

    $ElapsedTime = $(Get-Date) - $StartTime;
    Write-Verbose "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fff") : DataTable Created/Loaded in $("{0:HH:mm:ss.fff}" -f [datetime]$ElapsedTime.Ticks)";

    Write-Output @(,($DtaTbl));

} # End: ConvertTo-DataTable
