param tags object = {}
param uniquekey string
param location string = resourceGroup().location
param subnetId string
param keyVaultName string
param vnetResourceId string

var privateEndPoint = 'privatelink.blob.core.windows.net'
var resourceType = 'blob'

resource keyvaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

module pepModule '../../utility/pep.bicep' = {
  name: 'pepModule'
  params: {
    vnetResourceId: vnetResourceId
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: subnetId
    resourceType: resourceType
    privateEndPoint: privateEndPoint
    linkedServiceId: storageResource.id
    pepName: 'storageaccount'
  }
}

var storageAccountName = '${uniquekey}sa'

resource storageResource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled'
  }
  tags: tags
}

resource blobStoreSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyvaultResource
  name: '${uniquekey}-storageaccount-connectionString'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageResource.listKeys().keys[0].value}'
    contentType: 'ConnectionString'
  }
}

output storageAccountSecretUri string = blobStoreSecret.properties.secretUri
