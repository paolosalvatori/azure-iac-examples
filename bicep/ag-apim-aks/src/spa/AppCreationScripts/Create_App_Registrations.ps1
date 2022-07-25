[CmdletBinding()]
param(
    [Parameter(Mandatory = $True, HelpMessage = 'Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $TenantId
)

#Requires -Modules Microsoft.Graph.Applications

# Pre-requisites
if ($null -eq (Get-Module -ListAvailable -Name "Microsoft.Graph.Applications")) {
    Install-Module "Microsoft.Graph.Applications" -Scope CurrentUser 
}

Import-Module Microsoft.Graph.Applications
$ErrorActionPreference = "Stop"

# connect to MS Graph API
Write-Host "Connecting Microsoft Graph"
Connect-MgGraph -TenantId $TenantId -Scopes "Application.ReadWrite.All"

# create the order-api app registration
Write-Host "Creating the AAD application (ms-identity-order-api)"
$spaAadApplication = New-MgApplication -DisplayName "ms-identity-order-apu" `
    -SignInAudience AzureADandPersonalMicrosoftAccount 


# create the service principal of the newly created application 
New-MgServicePrincipal -AppId $spaAadApplication.AppId -Tags { WindowsAzureActiveDirectoryIntegratedApp }

Write-Host "Created spa application ($spaAppName)"

# create the product-api app registration
Write-Host "Creating the AAD application (ms-identity-javascript-react-spa)"
$spaAadApplication = New-MgApplication -DisplayName "ms-identity-javascript-react-spa" `
    -SignInAudience AzureADandPersonalMicrosoftAccount `
    -Spa @{RedirectUris = "http://localhost:3000" } `


# create the service principal of the newly created application 
New-MgServicePrincipal -AppId $spaAadApplication.AppId -Tags { WindowsAzureActiveDirectoryIntegratedApp }

Write-Host "Created spa application ($spaAppName)"

# Create the spa AAD application
Write-Host "Creating the AAD application (ms-identity-javascript-react-spa)"
$spaAadApplication = New-MgApplication -DisplayName "ms-identity-javascript-react-spa" `
    -SignInAudience AzureADandPersonalMicrosoftAccount `
    -Spa @{RedirectUris = "http://localhost:3000" } `


# create the service principal of the newly created application 
New-MgServicePrincipal -AppId $spaAadApplication.AppId -Tags { WindowsAzureActiveDirectoryIntegratedApp }

Write-Host "Created spa application ($spaAppName)"

# Add Required Resources Access (from 'spa' to 'store-api' & 'product-api')
Write-Host "Getting access from 'spa' to 'Microsoft Graph'"

$mgUserReadScope = @{
    "Id"   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
    "Type" = "Scope"
}

$mgResourceAccess = @($mgUserReadScope);

[object[]]$requiredResourceAccess = @{
    "ResourceAppId"  = "00000003-0000-0000-c000-000000000000"
    "ResourceAccess" = $mgResourceAccess
}

Update-MgApplication -ApplicationId $spaAadApplication.Id -RequiredResourceAccess $requiredResourceAccess
Write-Host "Granted permissions."
