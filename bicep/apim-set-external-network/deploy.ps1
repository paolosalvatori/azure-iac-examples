[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("australiaeast", "australiasoutheast")]
    [String]
    $location,

    [Parameter(Mandatory=$true)]
    [String]
    $resourceGroupName,

    [Parameter(Mandatory=$true)]
    [String]
    $vnetName,

    [Parameter(Mandatory=$true)]
    [String]
    $subnetName,

    [Parameter(Mandatory=$true)]
    [String]
    $publicIpName,

    [Parameter(Mandatory=$true)]
    [String]
    $apimName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Premium", "Developer")]
    [String]
    $apimSku,

    [Parameter(Mandatory=$true)]
    [ValidateCount(1,10)]
    [Int32]
    $apimCapacity,

    [Parameter(Mandatory=$true)]
    [ValidatePattern("^\w+([-+.’]\w+)@\w+([-.]\w+).\w+([-.]\w+)*$")]
    [String]
    $publisherEmail,

    [Parameter(Mandatory=$true)]
    [ValidatePattern("^\w+([-+.’]\w+)@\w+([-.]\w+).\w+([-.]\w+)*$")]
    [String]
    $publisherName,

    [Parameter(Mandatory=$true)]
    [String]
    $nsgName,

    [Parameter(Mandatory=$true)]
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
