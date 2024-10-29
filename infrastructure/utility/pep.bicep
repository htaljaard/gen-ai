param vnetResourceId string
param uniquekey string
param tags object
param location string = resourceGroup().location
param subnetId string
param pepName string

@description('As per https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#commercial')
param resourceType string
@description('As per https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#commercial')
param privateEndPoint string

param linkedServiceId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateEndPoint
  location: 'global'
  tags: tags
  resource privateSitesDnsZoneVNetLink 'virtualNetworkLinks' = {
    name: '${last(split(vnetResourceId, '/'))}-vnetlink'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetResourceId
      }
    }
  }
}

resource pepResource 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${uniquekey}-${pepName}-pep'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'peplink'
        properties: {
          privateLinkServiceId: linkedServiceId
          groupIds: [
            resourceType
          ]
        }
      }
    ]
  }
  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'dnszonegroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}
