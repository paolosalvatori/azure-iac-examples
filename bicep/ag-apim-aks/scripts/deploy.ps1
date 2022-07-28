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

#$productAppName = 'demo-product-api'
#$orderAppName = 'demo-order-api'
#$reactAppName = 'demo-react-spa'

$deploymentName = 'ag-apim-aks-deploy'
$redirectUris = @("http://localhost:3000", "https://api.$childDomainName")
$orderApiSvcIp = '10.2.2.4'
$productApiSvcIp = '10.2.2.5'

$environment = 'dev'
$semver = '0.1.2'
$tag = "$environment-$semver"

$spaImageName = "spa:$tag"
$orderApiImageName = "order:$tag"
$orderApiPort = "8080"
$productApiImageName = "product:$tag"
$productApiPort = "8081"

$cert = @{}
$root = @{}
$appRegHash = @{}

$appRegArray = @(
    @{
        Name          = 'demo-order-api'
        Type          = 'api'
        ApiDefinition = @{
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
        ApiRoles      = @(
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
    },
    @{
        Name          = 'demo-product-api'
        Type          = 'api'
        ApiDefinition = @{
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
        ApiRoles      = @(
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
    }
    @{
        Name           = 'demo-react-spa'
        Type           = 'client'
        ResourceAccess = @()
        RedirectUris   = $redirectUris
    }
)

#############
# functions
#############

function New-ApiAppRegistration {
    Param (
        $Name,
        $ApiDefinition,
        $ApiRoles
    )
    
    if (!($appReg = $(Get-MgApplication -filter "DisplayName eq '$Name'"))) {
        $appReg = New-MgApplication `
            -DisplayName $Name `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Api $ApiDefinition `
            -AppRoles $ApiRoles `
            -Verbose

        Update-MgApplication -ApplicationId $appReg.Id -IdentifierUris "api://$($appReg.AppId)"
        New-MgServicePrincipal -AppId $appReg.AppId
    }
    else {
        Write-Information -MessageData "application '$($appReg.DisplayName)' already registered"
    }
    return $appReg
}

function New-ClientAppRegistration {
    Param (
        $Name,
        $RequiredResourceAccess
    )

    if (!($clientAppReg = $(Get-MgApplication -filter "DisplayName eq '$Name'"))) {
        $clientAppReg = New-MgApplication `
            -DisplayName $Name `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Spa @{ RedirectUris = $redirectUris } `
            -RequiredResourceAccess $RequiredResourceAccess `
            -Verbose

        New-MgServicePrincipal -AppId $clientAppReg.AppId
    }
    else {
        Write-Information -MessageData "application '$($clientAppReg.Name)' already registered"
    }
    return $clientAppReg
}

function New-AppRegistrations {

    Param(
        [string]$TenantId,
        [switch]$RemoveAppRegistrations,
        [array]$AppRegistrations
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
        foreach ($appRegName in $AppRegistrations.Name) {
            Write-Information -MessageData "Removing App Registration '$appRegName'"
            if ($($appReg = $(Get-MgApplication -filter "DisplayName eq '$appRegName'"))) {
                Write-Information -MessageData "Removing $appRegName App Registrations..."
                Remove-MgApplication -ApplicationId $appReg.Id
            }
            else {
                Write-Information -MessageData "App Registrations $appRegName not found"
            }
        }
        return
    }

    $appRegArray = @()

    # create api app registrations
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'api') {
        $newAppReg = New-ApiAppRegistration -Name $appReg.Name -ApiDefinition $appReg.ApiDefinition -ApiRoles $appReg.ApiRoles
        $appRegArray += $newAppReg
        $appRegHash[$newAppReg.DisplayName] = $newAppReg
    }

    # define resource access
    $requiredResourceAccess = @(
        @{
            ResourceAppId  = $appRegArray[0].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegArray[0].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegArray[0].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        },
        @{
            ResourceAppId  = $appRegArray[1].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegArray[1].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegArray[1].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        }
    )

    # create spa app registration
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'client') {
        $appReg.ResourceAccess = $requiredResourceAccess
        $newClientAppReg = New-ClientAppRegistration -Name $appReg.Name -RequiredResourceAccess $appReg.ResourceAccess
        $appRegHash[$newClientAppReg.DisplayName] = $newClientAppReg
    }

    $result = $appRegHash

    #$result = [PSCustomObject]@{
    #    orderApi   = $orderApiApp
    #    productApi = $productApiApp
    #    reactSpa   = $reactApp
    #orderApiScopes = $orderApiDefinition
    #productApiScopes = $productApiDefinition

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

$appRegistrations = New-AppRegistrations -AppRegistrations $appRegArray -TenantId $tenant.Id

# generate API policy XML documents
Write-Information -MessageData "Generating APIM policy XML files"
$xml = Get-Content .\api-policy-template.xml     

$xml -replace "{{APP_GWY_FQDN}}", "api.$childDomainName" `
    -replace "{{AUDIENCE_API}}", $appRegistrations.'demo-order-api'.AppId `
    -replace "{{SERVICE_URL}}", "http://$orderApiSvcIp" `
    -replace "{{TENANT_NAME}}", $domainName > ./order-api-policy.xml

$xml -replace "{{APP_GWY_FQDN}}", "api.$childDomainName" `
    -replace "{{AUDIENCE_API}}", $appRegistrations.'demo-product-api'.AppId `
    -replace "{{SERVICE_URL}}", "http://$productApiSvcIp" `
    -replace "{{TENANT_NAME}}", $domainName > ./product-api-policy.xml

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
    -kubernetesSpaIpAddress '10.2.2.6' `
    -orderApiYaml $(Get-Content -Raw -Path ../src/order/openapi.yaml) `
    -productApiYaml $(Get-Content -Raw -Path ../src/product/openapi.yaml) `
    -orderApiPoicyXml $(Get-Content -Raw -Path ./order-api-policy.xml) `
    -productApiPoicyXml $(Get-Content -Raw -Path ./product-api-policy.xml) `
    -Verbose

# get deployment output
$deployment = Get-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rg.ResourceGroupName

# stop & start the app gateway for it to get the updated DNS zone!!!!
$appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName

<#
Write-Information -MessageData "Stopping App Gateway"
Stop-AzApplicationGateway -ApplicationGateway $appgwy
Write-Information -MessageData "Starting App Gateway"
Start-AzApplicationGateway -ApplicationGateway $appgwy
#>

#########################################
# Patch react authConfig.json file with 
# scopes, tenant name, endpoints, 
# clientId & redirectUri
#########################################

Write-Information -MessageData "patching react authConfig.js file"
$authConfig = Get-Content ../src/spa/src/authConfig_template.js
$authConfig `
    -replace "{{CLIENT_ID}}", $appRegistrations.'demo-react-spa'.AppId `
    -replace "{{DOMAIN_NAME}}", $domainName `
    -replace "{{ORDER_READ}}", "$($appRegistrations.'demo-order-api'.Api.Oauth2PermissionScopes[0].Id)/$($appRegistrations.'demo-order-api'.Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{ORDER_WRITE}}", "$($appRegistrations.'demo-order-api'.Api.Oauth2PermissionScopes[1].Id)/$($appRegistrations.'demo-order-api'.Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{PRODUCT_READ}}", "$($appRegistrations.'demo-product-api'.Api.Oauth2PermissionScopes[0].Id)/$($appRegistrations.'demo-product-api'.Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{PRODUCT_WRITE}}", "$($appRegistrations.'demo-product-api'.Api.Oauth2PermissionScopes[1].Id)/$($appRegistrations.'demo-product-api'.Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{ORDER_API_ENDPOINT}}", "https://api.$childDomainName/api/order/orders" `
    -replace "{{PRODUCT_API_ENDPOINT}}", "https://api.$childDomainName/api/product/products" `
    -replace "{{REDIRECT_URI}}", "https://api.$childDomainName" > ../src/spa/src/authConfig.js

# build container images in ACR
Write-Information -MessageData "Bulding Order container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $orderApiImageName `
    --build-arg SERVICE_PORT=$orderApiPort `
    -f ../src/Dockerfile ../src/order

Write-Information -MessageData "Bulding Product container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $productApiImageName `
    --build-arg SERVICE_PORT=$productApiPort `
    -f ../src/Dockerfile ../src/product

Write-Information -MessageData "Bulding Reaxt Spa container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $spaImageName `
    -f ../src/spa/Dockerfile ../src/spa

# apply kubernetes manifests
Write-Information -MessageData "Applying Kubernetes manifests"
Import-AzAksCredential -ResourceGroupName $rg.ResourceGroupName -Name $deployment.Outputs.aksClusterName.Value -Admin -Force

kubectl apply -f ../manifests/namespace.yaml

$(Get-Content -Path ../manifests/order.yaml) -replace "IMAGE_TAG", "$($deployment.Outputs.acrName.Value).azurecr.io/$orderApiImageName" | kubectl apply -f -
$(Get-Content -Path ../manifests/product.yaml) -replace "IMAGE_TAG", "$($deployment.Outputs.acrName.Value).azurecr.io/$productApiImageName" | kubectl apply -f -
$(Get-Content -Path ../manifests/spa.yaml) -replace "IMAGE_TAG", "$($deployment.Outputs.acrName.Value).azurecr.io/$spaImageName" | kubectl apply -f -

# TODO
# fix acrPull role assignemt to ACR for AKS cluster...
# assign agent-pool user mid acrPull role
# assign aks system mid user mid contributor role to MC_ resource group
# add admin consent for rct spa app registration
# add AG httpsetting & backend for react spa to bicep
