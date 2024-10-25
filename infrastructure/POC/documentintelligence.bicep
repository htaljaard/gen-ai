@description('The location of the Document Intelligence resource.')
param location string = resourceGroup().location

@description('The SKU of the Document Intelligence resource.')
<<<<<<< HEAD
param skuName string = 'S0'
=======
param skuName string = 'F0'
>>>>>>> 2b965f8 (Serilog and Document Intelligence)

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

<<<<<<< HEAD
// module pepModule '../../utility/pep.bicep' = {
//   name: 'pepModule'
//   params: {
//     vnetResourceId: vnetResourceId
//     uniquekey: uniquekey
//     tags: tags
//     location: location
//     subnetId: subnetId
//     resourceType: resourceType
//     privateEndPoint: privateEndPoint
//     linkedServiceId: documentIntelligence.id
//     pepName: 'docintel'
//   }
// }
=======
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
  }
}
>>>>>>> 2b965f8 (Serilog and Document Intelligence)

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

<<<<<<< HEAD
resource documentIntelligenceEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: keyvault
  name: 'documentIntelligenceEndpoint'
  properties: {
    value: documentIntelligence.properties.endpoint
  }
}

resource documentIntelligenceKeySecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
=======
resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
>>>>>>> 2b965f8 (Serilog and Document Intelligence)
  parent: keyvault
  name: 'documentIntelligenceKey'
  properties: {
    value: documentIntelligence.listKeys().key1
  }
}

<<<<<<< HEAD
output documentIntelligenceEndpoint string = documentIntelligenceEndpointSecret.properties.secretUri
output documentIntelligenceKey string = documentIntelligenceKeySecret.properties.secretUri
output documentIntelligenceId string = documentIntelligence.id
=======
output documentIntelligenceEndpoint string = keyVaultSecret.properties.secretUri
>>>>>>> 2b965f8 (Serilog and Document Intelligence)
