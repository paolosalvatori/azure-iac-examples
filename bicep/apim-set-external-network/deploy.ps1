[CmdletBinding(SupportsShouldProcess)]
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
    $subnetAddressPrefix,

    [Parameter(Mandatory = $true)]
    [String]
    $publicIpName,

    [Parameter()]
    [Switch]
    $UpdateApim,

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
    }
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

if($WhatIfPreference.IsPresent) {$WhatIfPreference = $true}

New-AzResourceGroupDeployment `
    -Name 'apimExternalNetworkUpdateDeployment' `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile './main.bicep' `
    -SubnetAddressPrefix $subnetAddressPrefix `
    -UpdateApim $UpdateApim.IsPresent `
    -ApimProperties @{name = $apimName ; sku = @{name = $apimSku; capacity = $apimCapacity } ; publisherEmail = $publisherEmail ; publisherName = $publisherName } `
    -Verbose

<#
# example test deployment whaivch shows only the potential changes - note the -WhatIf switch is specified when calling the script
./deploy.ps1 -location 'australiasoutheast' `
    -ResourceGroupName 'apim-pb-rg' `
    -VnetName 'apim-pb-vnet' `
    -SubnetName 'apim-subnet' `
    -SubnetAddressPrefix '10.0.0.0/24' `
    -PublicIpName 'apim-pip' `
    -ApimName 'apim-pb-inst' `
    -ApimSku 'Premium' `
    -ApimCapacity 1 `
    -PublisherEmail 'me@mycompany.net' `
    -PublisherName 'myCompany' `
    -NsgName 'apim-nsg' `
    -DomainLabelPrefix 'cbellee-apim-external' `
    -Tags @{'environment' = 'uat'; 'costcentre' = '12345' } `
    -WhatIf
#>

<#
# example deployment that adds the subnet & NSG, but skips changing APIM configuration
./deploy.ps1 -location 'australiasoutheast' `
    -ResourceGroupName 'apim-pb-rg' `
    -VnetName 'apim-pb-vnet' `
    -SubnetName 'apim-subnet' `
    -SubnetAddressPrefix '10.0.0.0/24' `
    -PublicIpName 'apim-pip' `
    -ApimName 'apim-pb-inst' `
    -ApimSku 'Premium' `
    -ApimCapacity 1 `
    -PublisherEmail 'me@mycompany.net' `
    -PublisherName 'myCompany' `
    -NsgName 'apim-nsg' `
    -DomainLabelPrefix 'cbellee-apim-external' `
    -tags @{'environment' = 'uat'; 'costcentre' = '12345' }    
#>

<#
# example deployment that includes the change to APIM - note the '-UpdateApim' switch
./deploy.ps1 -location 'australiasoutheast' `
    -ResourceGroupName 'apim-pb-rg' `
    -VnetName 'apim-pb-vnet' `
    -SubnetName 'apim-subnet' `
    -SubnetAddressPrefix '10.0.0.0/24' `
    -PublicIpName 'apim-pip' `
    -ApimName 'apim-pb-inst' `
    -ApimSku 'Premium' `
    -ApimCapacity 1 `
    -PublisherEmail 'me@mycompany.net' `
    -PublisherName 'myCompany' `
    -NsgName 'apim-nsg' `
    -DomainLabelPrefix 'cbellee-apim-external' `
    -Tags @{'environment' = 'uat'; 'costcentre' = '12345' } `
    -UpdateApim 
#>