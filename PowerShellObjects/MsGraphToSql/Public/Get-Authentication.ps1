# Get-Authentication
function Get-Authentication { # change name to Initialize-Authentication?
<#
.SYNOPSIS
    This function is used to authenticate with the Azure Active Directory using ADAL
.DESCRIPTION
    The function authenticates with Azure Active Directory with a UserPrincipalName. Additionally,
    the users credentials can be passed in either as a UserPasswordCredential or as a secure string.
.EXAMPLE
    Get-Authentication -User user@microsoft.com -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
    Authenticates you to a specific Application ID within Azure Active Directory with the users UPN
.EXAMPLE
    Get-Authentication -user me@mydomain.com -UserPasswordCredentials $GraphCredentials -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
    Authenticates within Azure AD using the user/password passed in along with the Application ID
.EXAMPLE
    Get-Authentication -user me@mydomain.com -SecurePassword $SecureGraphPassword -ApplicationId eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
    Authenticates within Azure AD using the user/password passed in along with the Application ID
.EXAMPLE
    Get-Authentication -User eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee -IsMSI;
    Authenticates for MS Graph using the Managed Service Identity (MSI) provided.
.NOTES
    NAME: Get-Authentication
    HISTORY:
        Date              Author                    Notes
        12/15/2017        Benjamin Reynolds         Adapted from Nick Ciaravella's "Connect-IntuneDataWarehouse"
        07/03/2018        Benjamin Reynolds         Updated to use a secure string password and added comments
        07/20/2018        Benjamin Reynolds         Added ability to pass in credentials rather than a secure password
        03/16/2020        Benjamin Reynolds         Added MSI authentication.
        09/02/2020        Benjamin Reynolds         Updated to account for different authorities and audience.
#>
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='UsePassword')][String]$User
       ,[Parameter(Mandatory=$false,ParameterSetName='UsePassword')][System.Security.SecureString]$SecurePassword # keeping this for backward compatibility
       ,[Parameter(Mandatory=$true,ParameterSetName='UseCredentials')]<#[Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential]#>$UserPasswordCredentials
       ,[Parameter(Mandatory=$false)][String]$ApplicationId="b78eaaf9-18b8-49c7-93fa-77d96d729253"
       ,[Parameter(Mandatory=$false)][Alias("Audience","BaseURL")][String]$resourceAppIdURI="https://graph.microsoft.com/"
       ,[Parameter(Mandatory=$false)][String]$RedirectUri='urn:ietf:wg:oauth:2.0:oob'
       ,[Parameter(Mandatory=$false)][Switch]$IsMSI
       ,[Parameter(Mandatory=$false)][Alias("Authority")][String]$AuthUrl = 'https://login.microsoftonline.com/common'
    )

    ## Set Working Variables:
    if ($PsCmdlet.ParameterSetName -eq 'UseCredentials') {
        [String]$User = $UserPasswordCredentials.UserName
    }

    if ($AuthUrl.EndsWith('/'))
    {
        $AuthUrl = $AuthUrl.Substring(0,$AuthUrl.Length-1);
    }
    if (-Not $resourceAppIdURI.EndsWith('/'))
    {
        $resourceAppIdURI = "$resourceAppIdURI/";
    }

    if ($IsMSI -eq $true) {
        try {
            $authResult = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$User&resource=$resourceAppIdURI" -Method GET -Headers @{Metadata="true"};
        }
        catch {
            write-host $_.Exception.Message -f Red;
            write-host $_.Exception.ItemName -f Red;
            write-host;
            throw;
        }

        # if we have an AccessToken then set the global variables to use:
        if ($authResult.access_token) {
            $Global:ADAuthResult = $authResult;
            #$Global:ADAuthUser = $User; # We aren't actually using this anywhere so going to remove it
            #$Global:OpStoreURL = $resourceAppIdURI; # We aren't actually using this anywhere so going to remove it
        }
        else {
            throw "Authorization Access Token is null, please re-run authentication...";
        }
    }
    else {
        #if ([String]::IsNullOrEmpty($AuthUrl))
        #{
        #    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User;
        #    $tenant = $userUpn.Host;
        #    $authority = "https://login.windows.net/$tenant";
        #}

        ## Make sure the ActiveDirectory Assemblies are loaded:
        if ((Test-ADAssembliesLoaded) -eq $false) {
            Add-ADAssemblies;
        }
        
        ## Let's get authenticated and create the global variables required:
        try {
            $authContext = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $AuthUrl; #$authority;
        
            # Acquire the token either using the user/password or the credentials (if only a user was passed in then the current user's credentials will be used):
            if ($PsCmdlet.ParameterSetName -eq 'UseCredentials') {
                # Get the Auth:
                $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $ApplicationId, $UserPasswordCredentials).Result;
            }
            
            if ($PsCmdlet.ParameterSetName -eq 'UsePassword') {
                if ($SecurePassword) {
                    # Create the credentials:
                    $userCredentials = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $userUPN,$SecurePassword;
                    # Get the Auth:
                    $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $ApplicationId, $userCredentials).Result;
                }
                else {
                    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
                    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto";
                    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId");
                    # Get the Auth:
                    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$ApplicationId,$RedirectUri,$platformParameters,$userId).Result;
                }
            }
        }
        catch {
            write-host $_.Exception.Message -f Red;
            write-host $_.Exception.ItemName -f Red;
            write-host;
            throw;
        }

        # if we have an AccessToken then set the global variables to use:
        if ($authResult.AccessToken) {
            $Global:ADAuthResult = $authResult;
            #$Global:ADAuthUser = $User; # We aren't actually using this anywhere so going to remove it
            #$Global:OpStoreURL = $resourceAppIdURI; # We aren't actually using this anywhere so going to remove it
        }
        else {
            throw "Authorization Access Token is null, please re-run authentication...";
        }
    }
} #End: Get-Authentication
