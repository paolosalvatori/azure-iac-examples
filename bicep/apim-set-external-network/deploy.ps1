[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $location = 'australiasoutheast',

    [Parameter()]
    [String]
    $resourceGroupName = 'apim-pb-rg',

    [Parameter()]
    [String]
    $vnetName = 'apim-pb-vnet',

    [Parameter()]
    [String]
    $subnetName = 'apim-subnet',

    [Parameter()]
    [String]
    $subnetAddressPrefix = '10.0.0.0/24',

    [Parameter()]
    [String]
    $publicIpName = 'apim-pip',

    [Parameter()]
    [String]
    $apimName = 'apim-pb',

    [Parameter()]
    [String]
    $apimSku = 'Premium',

    [Parameter()]
    [Int32]
    $apimCapacity = 1,

    [Parameter()]
    [String]
    $publisherEmail = 'cbellee@microsoft.com',

    [Parameter()]
    [String]
    $publisherName = 'KainiIndustries',

    [Parameter()]
    [String]
    $nsgName = 'apim-nsg',

    [Parameter()]
    [String]
    $domainLabelPrefix = 'apim-pb',

    [Parameter()]
    [System.Object]
    $tags = @{
        'environment' = 'uat'
        'costcentre'  = '1234567890'
    },

    [Parameter()]
    [System.Boolean]
    $isWhatifDeployment = $true
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
    PS C:\> ./deploy.ps1 -location 'australiaeast' -resourceGroupName 'my-rg' -vnetName 'apim-vnet' -subnetName 'apim-subnet -publicIpName 'apim-pip -apimName 'my-apim' -apimSku 'Premium' -apimCapacity 1 -publisherEmail 'me@mycompany.net' -publisherName 'my company' -nsgName 'apim-nsg -domainLabelPrefix 'apim-external' -tags @{'environment'='uat';'costcentre'='12345'} -isWhatIfDeployment:$false
    Runs the script with specificed inputs and deploys/updates the resources in the bicep template
#>

#Requires -Module @{ ModuleName = 'Az'; ModuleVersion = '5.6.0' }

# bicep template deployment defaults to WhatIf (read-only & displays the operations that will occur once script parameter '$isWhatifDeployment=$false')
New-AzResourceGroupDeployment `
    -Name 'apimExternalNetworkUpdateDeployment' `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile './main.bicep' `
    -ApimProperties @{name = $apimName ; sku = @{sku = $apimSku; capacity = $apimCapacity } ; publisherEmail = $publisherEmail ; publisherName = $publisherName } `
    -Mode Incremental `
    -WhatIf:$isWhatifDeployment `
    -Verbose
