[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("australiaeast", "australiasoutheast")]
    [String]
    $Location,

    [Parameter(Mandatory = $true)]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [String]
    $VnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $SubnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $SubnetAddressPrefix,

    [Parameter(Mandatory = $true)]
    [String]
    $PublicIpName,

    [Parameter()]
    [Switch]
    $UpdateApim,

    [Parameter(Mandatory = $true)]
    [String]
    $ApimName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Premium", "Developer")]
    [String]
    $ApimSku,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [Int32]
    $ApimCapacity,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$")]
    [String]
    $PublisherEmail,

    [Parameter(Mandatory = $true)]
    [String]
    $PublisherName,

    [Parameter(Mandatory = $true)]
    [String]
    $NsgName,

    [Parameter(Mandatory = $true)]
    [String]
    $DomainLabelPrefix,

    [Parameter()]
    [System.Object]
    $Tags = @{
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
.EXAMPLE
     example deployment that adds the subnet & NSG, but skips changing APIM configuration
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
.EXAMPLE
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
