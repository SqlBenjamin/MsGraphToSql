# Invoke-SqlCommand
function Invoke-SqlCommand {
<#
.SYNOPSIS
    This function executes a SQL command against a server/db and returns an object used to determine if it was successful or not.
    If the command is getting data (multiple columns/rows) then the data is returned as an object to the caller.
.DESCRIPTION
    The function executes a provided SQL command and returns whether it was successful or not along with any error that was captured. If the
    "ReturnTableData" switch is defined then all the data returned by the command will be returned as a data object to the caller.
    To determine the SQL Server and database to run the command against either the Server/DB need to be passed in or a SQL Connection String.
    If no "SqlCredentials" are passed in then the current user's credentials will be used to try and create the connection; otherwise the
    credentials securely stored in the SqlCredential will be used to make the connection.
.PARAMETER SqlServerName
    The name of the SQL Server to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlDatabaseName
    The name of the Database to connect to. If this is defined the SqlConnString is not required
.PARAMETER SqlConnString
    The entire connection string used to make the connection to SQL. If this is defined neither SqlServerName nor SqlDatabaseName are required.
.PARAMETER SqlCredentials
    This is a SqlClient.SqlCredential containing the user/password to use to make the connection to SQL. If this is not passed in the function will try to use the current user's credentials
.PARAMETER SqlCommandText
    This is the SQL DML/DDL desired to run against the SQL Server.
.PARAMETER ReturnTableData
    This is a switch that controls whether all the data from the DML command should be returned to the caller. If this is not passed in only the first row/column value will be returned rather than all the rows/columns.
.PARAMETER SqlCommandTimeout
    The SQL command timeout (in seconds) to use while running a command/query against SQL.
.PARAMETER SqlConnTimeout
    The SQL connection timeout (in seconds) to use when making a SQL Connection.
.EXAMPLE
    Invoke-SqlCommand -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlCommandText "SELECT @@VERSION;";
    This will run "SELECT @@VERSION;" against the SQL Server "MySqlServer" and Database "MyDb". The value returned will be in the return object's property "SqlColVal"
.EXAMPLE
    Invoke-SqlCommand -SqlServerName "MySqlServer" -SqlDatabaseName "MyDb" -SqlCommandText "SELECT @@VERSION;";
    This will run "SELECT @@VERSION;" against the SQL Server "MySqlServer" and Database "MyDb". The value returned will be in the return object's property "SqlColVal"
.EXAMPLE
    Invoke-SqlCommand -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlCommandText "SELECT TOP 5 * FROM sys.objects;" -ReturnTableData;
    This will run "SELECT TOP 5 * FROM sys.objects;" against the SQL Server "MySqlServer" and Database "MyDb".
    The rows and columns returned will be in the return object's property "SqlTableData".
.EXAMPLE
    Invoke-SqlCommand -SqlConnString "Server=MySqlServer;Database=MyDb;Integrated Security=SSPI" -SqlCommandText "SELECT TOP 5 * FROM sys.objects;";
    This will run "SELECT TOP 5 * FROM sys.objects;" against the SQL Server "MySqlServer" and Database "MyDb". Although multiple rows and columns are returned by the command,
    since the "ReturnTableData" switch was not turned on, only the value from the first row and column will be returned. It will be in the return object's property "SqlColVal".
.OUTPUTS
    An object (ArrayList) with the following properties:
    -Value = either -1 (failure) or 0 (success) 
    -ErrorCaptured = this property contains the information if an error was caught  
    One of the following:
     -SqlColVal = if ReturnTableData is not passed in the command is run and if there is anything returned this property will contain the first column/row value
     -SqlTableData = if the ReturnTableData switch is used the data captured is returned in this property as an ArrayList of Hashtables
.NOTES
    NAME: Invoke-SqlCommand
    HISTORY:
        Date                Author                    Notes
        09/05/2018          Benjamin Reynolds         Initial Creation
        09/10/2018          Benjamin Reynolds         Adding Reader switch/capability.
        #10/24/2018          Benjamin Reynolds         Added SqlAdapter capability and SqlCommandTimeout.
        03/08/2021          Benjamin Reynolds         Updated Connection string validation and ability to send credentials with either parameterset. Added SqlConnTimeout.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("SqlServer")][string]$SqlServerName
       ,[Parameter(Mandatory=$true,ParameterSetName='NoConnString')][Alias("DatabaseName","Database")][string]$SqlDatabaseName
       ,[Parameter(Mandatory=$true,ParameterSetName='ConnString')][string]$SqlConnString
       ,[Parameter(Mandatory=$false)][Alias("SqlCreds")][System.Data.SqlClient.SqlCredential]$SqlCredentials
       ,[Parameter(Mandatory=$true)][String]$SqlCommandText
       ,[Parameter(Mandatory=$false)][Alias("ReturnAllColsAndRows","UseReader")][Switch]$ReturnTableData
       #,[Parameter(Mandatory=$false)][ValidateSet("MultipleDataSets","OneDataSet","OneValue")][string]$ReturnDataType = "OneValue"
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlCommandTimeout
       ,[Parameter(Mandatory=$false)][AllowNull()][System.Nullable[int]]$SqlConnTimeout
    )

    $ReturnObj = New-Object System.Collections.ArrayList;

    ## Create the connection to SQL:
    try
    {
        ## if the connection string was sent then this will validate that it's a valid connection string, if its null then it'll create an empty object which we'll populate:
        $SqlConnBuilder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new($SqlConnString);

        if ([String]::IsNullOrWhiteSpace($SqlConnBuilder.ConnectionString))
        {
            $SqlConnBuilder['Server'] = $SqlServerName;
            $SqlConnBuilder['Database'] = $SqlDatabaseName;
            if ($null -ne $SqlConnTimeout)
            {
                $SqlConnBuilder['Connection Timeout'] = $SqlConnTimeout;
            }
            
        }
        
        if ($null -ne $SqlCredentials) # Use SQL Authentication:
        {
            $SqlConn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $SqlConnBuilder.ConnectionString, $SqlCredentials;
        }
        else # Use Windows Authentication:
        {
            $SqlConnBuilder['Integrated Security'] = $true;
            $SqlConn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $SqlConnBuilder.ConnectionString;
        }
    }
    catch
    {
        $SqlErrorCaptured = $PSItem;
        $StopFunction = $true;
    }
    
    if (-Not $StopFunction)
    {
        ## Connect to SQL and get the data:
        $SqlConn.Open();
        $SqlCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList $SqlCommandText, $SqlConn;
        if ($null -ne $SqlCommandTimeout) {
            $SqlCmd.CommandTimeout = $SqlCommandTimeout;
        }
        
        try {
            #if ($ReturnDataType -eq "MultipleDataSets") {
            #    ## If a sproc returns multiple result sets capture all the data:
            #    $SqlTableData = New-Object -TypeName System.Data.DataSet;
            #
            #    $SqlAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList $SqlCmd;
            #    $SqlAdapter.Fill($SqlTableData);
            #} # end using adapter (for returning all datasets returned)
            #elseif ($ReturnDataType -eq "OneDataSet") {
            if ($ReturnTableData) {
                $SqlTableData = New-Object System.Collections.ArrayList;
                
                $SqlReader = $SqlCmd.ExecuteReader();
                while ($SqlReader.Read()) {
                    $RowData = New-Object -TypeName System.Collections.Hashtable;
                    for ($i = 0; $i -lt $SqlReader.FieldCount; $i++) {
                        $RowData[$SqlReader.GetName($i)] = $SqlReader.GetValue($i);
                    }
                    [void]$SqlTableData.Add($RowData);
                    Remove-Variable -Name RowData,i -ErrorAction SilentlyContinue;
                }
                $SqlReader.Close()
            } # end using reader (if returning all data returned by the command)
            else {
                $SqlColVal = $SqlCmd.ExecuteScalar();
            }
        }
        catch {
            $SqlErrorCaptured = $PSItem;
        }
        finally { # Make sure to close the connection whether successful or not
            if ($SqlConn.State -ne [System.Data.ConnectionState]::Closed)
            {
                $SqlConn.Close();
            }
        }
    }

    ## Create the return object (include the error if one was caught):
    if ($SqlErrorCaptured) {
        if ($SqlColVal) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"SqlColVal"=$SqlColVal;"ErrorCaptured" = $SqlErrorCaptured;"Value" = -1};
        }
        elseif ($SqlTableData) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"SqlTableData"=$SqlTableData;"ErrorCaptured" = $SqlErrorCaptured;"Value" = -1};
        }
        else {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"ErrorCaptured" = $SqlErrorCaptured;"Value" = -1};
        }
        [void]$ReturnObj.Add($TmpRtnObj);
        return $ReturnObj;
    }
    else {
        if ($SqlColVal) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"SqlColVal"=$SqlColVal;"Value" = 0};
        }
        elseif ($SqlTableData) {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"SqlTableData"=$SqlTableData;"Value" = 0};
        }
        else {
            $TmpRtnObj = New-Object -TypeName PSObject -Property @{"Value" = 0};
        }
        [void]$ReturnObj.Add($TmpRtnObj);
        return $ReturnObj;
    }
} # End: Invoke-SqlCommand
