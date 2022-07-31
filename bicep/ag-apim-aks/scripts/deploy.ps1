$password = 'M1cr0soft1234567890'
$location = 'australiaeast'
$domainName = 'kainiindustries.net'
$tenant = (Get-AzDomain $domainName)
$childDomainName = "aksdemo.$domainName"
$rgName = "ag-apim-aks-$location-rg"
$deploymentName = 'ag-apim-aks-deploy'
$aksAdminGroupObjectId = 'f6a900e2-df11-43e7-ba3e-22be99d3cede'
$sans = "api.$childDomainName", "portal.$childDomainName", "management.$childDomainName", "proxy.internal.$childDomainName", "portal.internal.$childDomainName", "management.internal.$childDomainName"
$sshPublicKey = $(cat ~/.ssh/id_rsa.pub)
$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
$cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert

$redirectUris = @("http://localhost:3000", "https://api.$childDomainName")
$orderApiSvcIp = '10.2.2.4'
$productApiSvcIp = '10.2.2.5'
$reactSpaSvcIp = '10.2.2.6'
$identityPrefix = 'aks'

$environment = 'dev'
$semver = '0.1.2'
$tag = "$environment-$semver"

$spaImageName = "spa:$tag"
$orderApiImageName = "order:$tag"
$productApiImageName = "product:$tag"

$orderApiPort = "8080"
$productApiPort = "8081"

$cert = @{}
$root = @{}
$appRegHash = @{}

$appRegistrationDefinitions = @(
    @{
        Name          = "$identityPrefix-order-api"
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
        Name          = "$identityPrefix-product-api"
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
        Name           = "$identityPrefix-react-spa"
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
        Write-Host -Object "creating application '$($Name)'"
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
        Write-Host -Object "application '$($appReg.DisplayName)' already registered"
    }
    return $appReg
}
function New-ClientAppRegistration {
    Param (
        $Name,
        $RequiredResourceAccess
    )

    if (!($appReg = $(Get-MgApplication -filter "DisplayName eq '$Name'"))) {
        Write-Host -Object "creating application '$($Name)'"
        $appReg = New-MgApplication `
            -DisplayName $Name `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Spa @{ RedirectUris = $redirectUris } `
            -RequiredResourceAccess $RequiredResourceAccess `
            -Verbose

        New-MgServicePrincipal -AppId $appReg.AppId
    }
    else {
        Write-Host -Object "application '$($appReg.DisplayName)' already registered"
    }
    return $appReg
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
        foreach ($appRegName in $AppRegistrations) {
            Write-Host -Object "Removing App Registration '$appRegName'"
            if ($($appReg = $(Get-MgApplication -filter "DisplayName eq '$appRegName'"))) {
                Write-Host -Object "Removing $appRegName App Registrations..."
                Remove-MgApplication -ApplicationId $appReg.Id
            }
            else {
                Write-Host -Object "App Registration '$appRegName' not found"
            }
        }
        return
    }

    $appRegistrationDefinitions = @()

    # create api app registrations
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'api') {
        New-ApiAppRegistration -Name $appReg.Name -ApiDefinition $appReg.ApiDefinition -ApiRoles $appReg.ApiRoles
        $newAppReg = Get-MgApplication -Filter "DisplayName eq '$($appReg.Name)'"
        $appRegistrationDefinitions += $newAppReg
        $appRegHash[$newAppReg.DisplayName] = $newAppReg
    }

    # define resource access
    $requiredResourceAccess = @(
        @{
            ResourceAppId  = $appRegistrationDefinitions[0].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegistrationDefinitions[0].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegistrationDefinitions[0].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        },
        @{
            ResourceAppId  = $appRegistrationDefinitions[1].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegistrationDefinitions[1].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegistrationDefinitions[1].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        }
    )

    # create spa app registration
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'client') {
        $appReg.ResourceAccess = $requiredResourceAccess
        New-ClientAppRegistration -Name $appReg.Name -RequiredResourceAccess $appReg.ResourceAccess
        $newAppReg = Get-MgApplication -Filter "DisplayName eq '$($appReg.Name)'"
        $appRegHash[$newAppReg.DisplayName] = $newAppReg
    }

    $result = $appRegHash
    return $result
}

#############
# Main
#############

# create app registrations
Write-Host "Connecting Microsoft Graph"
Connect-MgGraph -TenantId $tenant.Id -Scopes "Application.ReadWrite.All"

# create self-signed certificates
if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host -Object "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
}

$clearBytes = $rootCert.Export($cerContentType)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$root = @{CertName = $rootCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }))) {
    Write-Host -Object "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certificate'
}

$clearBytes = $pfxCert.Export($pkcs12ContentType, $password)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$cert = @{CertName = $pfxCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $password }

# create application registrations
$appRegistrations = New-AppRegistrations -AppRegistrations $appRegistrationDefinitions -TenantId $tenant.Id

# patch react authConfig.json file 
Write-Host -Object "patching react authConfig.js file"
$authConfig = Get-Content ../src/spa/src/authConfig_template.js
$authConfig `
    -replace "{{CLIENT_ID}}", $appRegistrations."$identityPrefix-react-spa".AppId `
    -replace "{{DOMAIN_NAME}}", $domainName `
    -replace "{{ORDER_READ}}", "$($appRegistrations."$identityPrefix-order-api".AppId)/$($appRegistrations."$identityPrefix-order-api".Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{ORDER_WRITE}}", "$($appRegistrations."$identityPrefix-order-api".AppId)/$($appRegistrations."$identityPrefix-order-api".Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{PRODUCT_READ}}", "$($appRegistrations."$identityPrefix-product-api".AppId)/$($appRegistrations."$identityPrefix-product-api".Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{PRODUCT_WRITE}}", "$($appRegistrations."$identityPrefix-product-api".AppId)/$($appRegistrations."$identityPrefix-product-api".Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{ORDER_API_ENDPOINT}}", "https://api.$childDomainName/api/order/orders" `
    -replace "{{PRODUCT_API_ENDPOINT}}", "https://api.$childDomainName/api/product/products" `
    -replace "{{REDIRECT_URI}}", "https://api.$childDomainName" > ../src/spa/src/authConfig.js

# generate API policy XML documents
Write-Host -Object "Generating APIM policy XML files"
$xml = Get-Content .\api-policy-template.xml     

$xml -replace "{{APP_GWY_FQDN}}", "api.$childDomainName" `
    -replace "{{AUDIENCE_API}}", $appRegistrations."$identityPrefix-order-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$orderApiSvcIp" `
    -replace "{{TENANT_NAME}}", $domainName > ./order-api-policy.xml

$xml -replace "{{APP_GWY_FQDN}}", "api.$childDomainName" `
    -replace "{{AUDIENCE_API}}", $appRegistrations."$identityPrefix-product-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$productApiSvcIp" `
    -replace "{{TENANT_NAME}}", $domainName > ./product-api-policy.xml

# deploy bicep template
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

Write-Host -Object "Deploying infrastructure"
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
    -kubernetesSpaIpAddress $reactSpaSvcIp `
    -orderApiYaml $(Get-Content -Raw -Path ../src/order/openapi.yaml) `
    -productApiYaml $(Get-Content -Raw -Path ../src/product/openapi.yaml) `
    -orderApiPoicyXml $(Get-Content -Raw -Path ./order-api-policy.xml) `
    -productApiPoicyXml $(Get-Content -Raw -Path ./product-api-policy.xml) `
    -Verbose

# get deployment output
$deployment = Get-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rg.ResourceGroupName

# stop & start the app gateway for it to get the updated DNS zone!!!!
<# $appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName

Write-Host -Object "Stopping App Gateway"
Stop-AzApplicationGateway -ApplicationGateway $appgwy

Write-Host -Object "Starting App Gateway"
Start-AzApplicationGateway -ApplicationGateway $appgwy #>

# build container images in ACR
Write-Host -Object "Bulding Order container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $orderApiImageName `
    --build-arg SERVICE_PORT=$orderApiPort `
    -f ../src/Dockerfile ../src/order

Write-Host -Object "Bulding Product container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $productApiImageName `
    --build-arg SERVICE_PORT=$productApiPort `
    -f ../src/Dockerfile ../src/product

Write-Host -Object "Bulding Reaxt Spa container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $spaImageName `
    -f ../src/spa/Dockerfile ../src/spa

# apply kubernetes manifests
Write-Host -Object "Applying Kubernetes manifests"
Import-AzAksCredential -ResourceGroupName $rg.ResourceGroupName -Name $deployment.Outputs.aksClusterName.Value -Admin -Force

# create k8s namespace
kubectl apply -f ../manifests/namespace.yaml

# apply k8s manifests
$(Get-Content -Path ../manifests/order.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$orderApiImageName" -replace "{{SVC_IP_ADDRESS}}", $orderApiSvcIp | kubectl apply -f -
$(Get-Content -Path ../manifests/product.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$productApiImageName" -replace "{{SVC_IP_ADDRESS}}", $oproductApiSvcIp | kubectl apply -f -
$(Get-Content -Path ../manifests/spa.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$spaImageName" -replace "{{SVC_IP_ADDRESS}}", $reactSpaSvcIp | kubectl apply -f -

# add admin consent for react spa app registration
az ad app permission admin-consent --id $appRegistrations."$identityPrefix-react-spa".AppId