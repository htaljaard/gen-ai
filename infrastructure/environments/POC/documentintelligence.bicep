@description('The location of the Document Intelligence resource.')
param location string = resourceGroup().location

@description('The SKU of the Document Intelligence resource.')
param skuName string = 'S0'

param tags object = {}
param uniquekey string
param subnetId string
param vnetResourceId string

var privateEndPoint = 'privatelink.cognitiveservices.azure.com'
var resourceType = 'account'

param keyVaultName string

resource keyvault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
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
    linkedServiceId: documentIntelligence.id
    pepName: 'documentIntelligence'
  }
}

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'doc-intel-${uniquekey}'
  location: location
  tags: tags
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: toLower('${uniquekey}-doc-intel')
    publicNetworkAccess: 'Disabled'
  }
  sku: {
    name: skuName
  }
}

resource documentIntelligenceEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: keyvault
  name: 'documentIntelligenceEndpoint'
  properties: {
    value: documentIntelligence.properties.endpoint
  }
}

resource documentIntelligenceKeySecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: keyvault
  name: 'documentIntelligenceKey'
  properties: {
    value: documentIntelligence.listKeys().key1
  }
}

output documentIntelligenceEndpoint string = documentIntelligenceEndpointSecret.properties.secretUri
output documentIntelligenceKey string = documentIntelligenceKeySecret.properties.secretUri
output documentIntelligenceId string = documentIntelligence.id
