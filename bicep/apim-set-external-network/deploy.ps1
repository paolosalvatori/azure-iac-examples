[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("australiaeast", "australiasoutheast")]
    [String]
    $location,

    [Parameter(Mandatory = $true)]
    [String]
    $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [String]
    $vnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $subnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $subnetAddressPrefix =  '10.0.0.0/24',

    [Parameter(Mandatory = $true)]
    [String]
    $publicIpName,

    [Parameter()]
    [System.Boolean]
    $isUpdateApim = $false,

    [Parameter(Mandatory = $true)]
    [String]
    $apimName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Premium", "Developer")]
    [String]
    $apimSku,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [Int32]
    $apimCapacity,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$")]
    [String]
    $publisherEmail,

    [Parameter(Mandatory = $true)]
    [String]
    $publisherName,

    [Parameter(Mandatory = $true)]
    [String]
    $nsgName,

    [Parameter(Mandatory = $true)]
    [String]
    $domainLabelPrefix,

    [Parameter()]
    [System.Object]
    $tags = @{
        'environment' = 'uat'
        'costcentre'  = '1234567890'
    },

    [Parameter()]
    [System.Boolean]
    $isWhatif = $true
)

<#
.SYNOPSIS
    Script to deploy Bicep temaplate which updates a specific API Management Instance to use an External Public IP
.DESCRIPTION
    Script to deploy Bicep temaplate which updates a specific API Management Instance to use an External Public IP
.EXAMPLE
    PS C:\> ./deploy.ps1 -location 'australiaeast' -resourceGroupName 'my-rg' -vnetName 'apim-vnet' -subnetName 'apim-subnet -publicIpName 'apim-pip -apimName 'my-apim' -apimSku 'Premium' -apimCapacity 1 -publisherEmail 'me@mycompany.net' -publisherName 'my company' -nsgName 'apim-nsg -domainLabelPrefix 'apim-external' -tags @{'environment'='uat';'costcentre'='12345'} 
    Runs the script with specificed inputs as a 'WhatIf' deployment
.EXAMPLE
    PS C:\> ./deploy.ps1 -location 'australiaeast' -resourceGroupName 'my-rg' -vnetName 'apim-vnet' -subnetName 'apim-subnet -publicIpName 'apim-pip -apimName 'my-apim' -apimSku 'Premium' -apimCapacity 1 -publisherEmail 'me@mycompany.net' -publisherName 'my company' -nsgName 'apim-nsg -domainLabelPrefix 'apim-external' -tags @{'environment'='uat';'costcentre'='12345'} -isWhatIf:$false -isUpdateApim $true
    Runs the script with specificed inputs and deploys/updates the resources in the bicep template
#>

#Requires -Module @{ ModuleName = 'Az'; ModuleVersion = '5.6.0' }

# bicep template deployment defaults to WhatIf (read-only & displays the operations that will occur once script parameter '$isWhatifDeployment=$false')
New-AzResourceGroupDeployment `
    -Name 'apimExternalNetworkUpdateDeployment' `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile './main.bicep' `
    -SubnetAddressPrefix $subnetAddressPrefix `
    -ApimProperties @{name = $apimName ; sku = @{name = $apimSku; capacity = $apimCapacity } ; publisherEmail = $publisherEmail ; publisherName = $publisherName } `
    -UpdateApim $isUpdateApim `
    -Mode Incremental `
    -WhatIf:$isWhatif `
    -Verbose

<#
# example default 'WhatIf' deployment
./deploy.ps1 -location 'australiasoutheast' `
    -resourceGroupName 'apim-pb-rg' `
    -vnetName 'apim-pb-vnet' `
    -subnetName 'apim-subnet' `
    -subnetAddressPrefix '10.0.0.0/24' `
    -publicIpName 'apim-pip' `
    -apimName 'apim-pb-inst' `
    -apimSku 'Premium' `
    -apimCapacity 1 `
    -publisherEmail 'me@mycompany.net' `
    -publisherName 'myCompany' `
    -nsgName 'apim-nsg' `
    -domainLabelPrefix 'cbellee-apim-external' `
    -tags @{'environment' = 'uat'; 'costcentre' = '12345' } `
    -isUpdateApim $false
#>

<#
# example deployment that skips changing APIM configuration
./deploy.ps1 -location 'australiasoutheast' `
    -resourceGroupName 'apim-pb-rg' `
    -vnetName 'apim-pb-vnet' `
    -subnetName 'apim-subnet' `
    -subnetAddressPrefix '10.0.0.0/24' `
    -publicIpName 'apim-pip' `
    -apimName 'apim-pb-inst' `
    -apimSku 'Premium' `
    -apimCapacity 1 `
    -publisherEmail 'me@mycompany.net' `
    -publisherName 'myCompany' `
    -nsgName 'apim-nsg' `
    -domainLabelPrefix 'cbellee-apim-external' `
    -tags @{'environment' = 'uat'; 'costcentre' = '12345' } `
    -isWhatIf:$false     
#>

<#
# example deployment that skips changing APIM configuration
./deploy.ps1 -location 'australiasoutheast' `
    -resourceGroupName 'apim-pb-rg' `
    -vnetName 'apim-pb-vnet' `
    -subnetName 'apim-subnet' `
    -subnetAddressPrefix '10.0.0.0/24' `
    -publicIpName 'apim-pip' `
    -apimName 'apim-pb-inst' `
    -apimSku 'Premium' `
    -apimCapacity 1 `
    -publisherEmail 'me@mycompany.net' `
    -publisherName 'myCompany' `
    -nsgName 'apim-nsg' `
    -domainLabelPrefix 'cbellee-apim-external' `
    -tags @{'environment' = 'uat'; 'costcentre' = '12345' } `
    -isUpdateApim $true `
    -isWhatIf:$false     
#>