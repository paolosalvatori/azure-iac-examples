$password = 'M1cr0soft1234567890'
$location = 'australiaeast'
$domainName = 'kainiindustries.net'
$tenant = (Get-AzDomain $domainName)
$childDomainName = "aksdemo.$domainName"
$rgName = "ag-apim-aks-$location-2-rg"
$aksAdminGroupObjectId = 'f6a900e2-df11-43e7-ba3e-22be99d3cede'
$sans = "api.$childDomainName", "portal.$childDomainName", "management.$childDomainName", "proxy.internal.$childDomainName", "portal.internal.$childDomainName", "management.internal.$childDomainName"
$sshPublicKey = $(cat ~/.ssh/id_rsa.pub)
$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
$cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert

$productAppName = 'demo-product-api'
$orderAppName = 'demo-order-api'
$reactAppName = 'demo-react-spa'

$orderApiName = 'order-api'
$productApiName = 'product-api'
$orderApiPath = "api/order"
$productApiPath = "api/product"

$orderApiSpecPath = '../src/order/openapi.yaml'
$productApiSpecPath = '../src/product/openapi.yaml'

$deploymentName = 'ag-apim-aks-deploy'
$redirectUris = @("http://localhost:3000", "https://api.aksdemo.kainiindustries.net")
$orderApiSvcIp = '10.2.1.4'
$productApiSvcIp = '10.2.1.5'
$cert = @{}
$root = @{}

#############
# functions
#############

function New-AppRegistrations {

    Param(
        [string]$TenantId,
        [switch]$RemoveAppRegistrations
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

    if ($RemoveAppRegistrations) {
        Write-Information -MessageData "Removing App Registrations..."
        if ($($orderApi = $(Get-MgApplication -filter "DisplayName eq '$orderAppName'"))) {
            Write-Information -MessageData "Removing $orderAppName App Registrations..."
            Remove-MgApplication -ApplicationId $orderApi.Id
        }
        else {
            Write-Information -MessageData "App Registrations $orderAppName not found"
        }

        if ($($productApi = $(Get-MgApplication -filter "DisplayName eq '$productAppName'"))) {
            Write-Information -MessageData "Removing $productAppName App Registrations..."
            Remove-MgApplication -ApplicationId $productApi
        }
        else {
            Write-Information -MessageData "App Registrations $productAppName not found"
        }

        if ($($reactSpa = $(Get-MgApplication -filter "DisplayName eq '$reactAppName'"))) {
            Write-Information -MessageData "Removing '$reactAppName' App Registrations..."
            Remove-MgApplication -ApplicationId $reactSpa.Id
        }
        else {
            Write-Information -MessageData "App Registrations '$reactAppName' not found"
        }
        return
    }

    # define app roles
    $orderApiAppRoles = @(
        @{
            AllowedMemberTypes = @("User")
            Description        = "Order Reader Role"
            DisplayName        = "Reader Role"
            Id                 = (New-Guid).Guid
            IsEnabled          = $True
            Value              = "Order.Role.Read"
        },
        @{
            AllowedMemberTypes = @("User")
            Description        = "Order Writer Role"
            DisplayName        = "Order Writer Role"
            Id                 = (New-Guid).Guid
            IsEnabled          = $True
            Value              = "Order.Role.Write"
        }
    )

    $productApiAppRoles = @(
        @{
            AllowedMemberTypes = @("User")
            Description        = "Product Reader Role"
            DisplayName        = "Product Reader Role"
            Id                 = (New-Guid).Guid
            IsEnabled          = $True
            Value              = "Product.Role.Read"
        },
        @{
            AllowedMemberTypes = @("User")
            Description        = "Product Writer Role"
            DisplayName        = "Product Writer Role"
            Id                 = (New-Guid).Guid
            IsEnabled          = $True
            Value              = "Product.Role.Write"
        }
    )

    # define api scopes
    $orderApiDefinition = @{
        RequestedAccessTokenVersion = 2
        Oauth2PermissionScopes      = @(
            @{
                Value                   = "Order.Read"
                AdminConsentDisplayName = "Read order API"
                AdminConsentDescription = "Allows the app to read orders"
                Id                      = (New-Guid).Guid
                IsEnabled               = $True
                Type                    = "Admin"
                UserConsentDisplayName  = "read orders"
                UserConsentDescription  = "allows app to read orders"
            },
            @{
                Value                   = "Order.Write"
                AdminConsentDisplayName = "Write order API"
                AdminConsentDescription = "Allows the app to write orders"
                Id                      = (New-Guid).Guid
                IsEnabled               = $True
                Type                    = "Admin"
                UserConsentDisplayName  = "write orders"
                UserConsentDescription  = "allows app to write orders"
            }
        )
    }

    $productApiDefinition = @{
        RequestedAccessTokenVersion = 2
        Oauth2PermissionScopes      = @(
            @{
                Value                   = "Product.Read"
                AdminConsentDisplayName = "Read product API"
                AdminConsentDescription = "Allows the app to read products"
                Id                      = (New-Guid).Guid
                IsEnabled               = $True
                Type                    = "Admin"
                UserConsentDisplayName  = "read products"
                UserConsentDescription  = "allows app to read products"
            },
            @{
                Value                   = "Product.Write"
                AdminConsentDisplayName = "Write product API"
                AdminConsentDescription = "Allows the app to write products"
                Id                      = (New-Guid).Guid
                IsEnabled               = $True
                Type                    = "Admin"
                UserConsentDisplayName  = "write products"
                UserConsentDescription  = "allows app to write products"
            }
        )
    }

    # create api app registrations
    if (!($orderApiApp = $(Get-MgApplication -filter "DisplayName eq '$orderAppName'"))) {
        $orderApiApp = New-MgApplication `
            -DisplayName $orderAppName `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Api $orderApiDefinition `
            -AppRoles $orderApiAppRoles `
            -Verbose

        Update-MgApplication -ApplicationId $orderApiApp.Id -IdentifierUris "api://$($orderApiApp.AppId)"
        New-MgServicePrincipal -AppId $orderApiApp.AppId
    } else {
        Write-Information -MessageData "application '$orderAppName' already registered"
    }

    if (!($productApiApp = $(Get-MgApplication -filter "DisplayName eq '$productAppName'"))) {
        $productApiApp = New-MgApplication `
            -DisplayName $productAppName `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Api $productApiDefinition `
            -AppRoles $productApiAppRoles `
            -Verbose

        Update-MgApplication -ApplicationId $productApiApp.Id -IdentifierUris "api://$($productApiApp.AppId)"
        New-MgServicePrincipal -AppId $productApiApp.AppId
    } else {
        Write-Information -MessageData "application '$productAppName' already registered"
    }

    # define resource access
    $requiredResourceAccess = @(
        @{
            ResourceAppId  = $orderApiApp.AppId
            ResourceAccess = @(
                @{
                    Id   = $orderApiDefinition.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $orderApiDefinition.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        },
        @{
            ResourceAppId  = $productApiApp.AppId
            ResourceAccess = @(
                @{
                    Id   = $productApiDefinition.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $productApiDefinition.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        }
    )

    # create spa app registration
    if (!($reactApp = $(Get-MgApplication -filter "DisplayName eq '$reactAppName'"))) {
        $reactApp = New-MgApplication `
            -DisplayName $reactAppName `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Spa @{ RedirectUris = $redirectUris } `
            -RequiredResourceAccess $requiredResourceAccess `
            -Verbose

        New-MgServicePrincipal -AppId $reactApp.AppId
    } else {
        Write-Information -MessageData "application '$reactAppName' already registered"
    }

    $result = [PSCustomObject]@{
        orderapi   = $orderApiApp
        productapi = $productApiApp
        reactspa   = $reactApp
    }

    return $result
}

#############
# Main
#############

$InformationPreference = 'continue'

# create self-signed certificates
if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Information -MessageData "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
}

$clearBytes = $rootCert.Export($cerContentType)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$root = @{CertName = $rootCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }))) {
    Write-Information -MessageData "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certificate'
}

$clearBytes = $pfxCert.Export($pkcs12ContentType, $password)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$cert = @{CertName = $pfxCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

$appRegistrations = New-AppRegistrations -TenantId $tenant.Id

# deploy bicep templates
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

Write-Information -MessageData "Deploying infrastructure"
New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateParameterFile  ../infra/main.parameters.json `
    -Mode Incremental `
    -templateFile ../infra/main.bicep `
    -location $location `
    -domainName $childDomainName `
    -cert $cert `
    -rootCert $root `
    -sshPublicKey $sshPublicKey `
    -aksAdminGroupObjectId $aksAdminGroupObjectId `
    -Verbose

# get deployment output
$deployment = Get-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rg.ResourceGroupName

# stop & start the app gateway for it to get the updated DNS zone!!!!
$appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName

Write-Information -MessageData "Stopping & starting App Gateway"
Stop-AzApplicationGateway -ApplicationGateway $appgwy
Start-AzApplicationGateway -ApplicationGateway $appgwy

### TODO 
# 1. Patch react authConfig.json file with scopes, tenant name, endpoints, clientId & redirectUri