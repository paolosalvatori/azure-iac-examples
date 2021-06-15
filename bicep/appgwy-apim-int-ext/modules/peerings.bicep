param vNets array
param suffix string

resource hubVnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = [for i in range(0, (length(vNets) - 1)): {
  name: '${vNets[0].name}-${suffix}/peering-to-${vNets[(i + 1)].name}-${suffix}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', '${vNets[(i + 1)].name}-${suffix}')
    }
  }
  dependsOn: []
}]

resource spokeVnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = [for i in range(0, (length(vNets) - 1)): {
  name: '${vNets[(i + 1)].name}-${suffix}/peering-to-${vNets[0].name}-${suffix}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', '${vNets[0].name}-${suffix}')
    }
  }
  dependsOn: []
}]
