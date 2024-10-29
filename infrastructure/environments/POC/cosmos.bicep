param tags object = {}
param uniquekey string
param location string = resourceGroup().location
param subnetId string
param keyVaultName string
param vnetResourceId string

var privateEndPoint = 'privatelink.documents.azure.com'
var resourceType = 'sql'

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

module pep '../../utility/pep.bicep' = {
  name: 'pep'
  params: {
    vnetResourceId: vnetResourceId
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: subnetId
    resourceType: resourceType
    privateEndPoint: privateEndPoint
    linkedServiceId: cosmosAccount.id
    pepName: 'cosmosdb'
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: '${uniquekey}-cosmosdb'
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    databaseAccountOfferType: 'Standard'

    locations: [
      { locationName: location }
    ]
    consistencyPolicy: { defaultConsistencyLevel: 'Eventual' }
    isVirtualNetworkFilterEnabled: true
    publicNetworkAccess: 'Disabled'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  name: 'anabelleDB'
  parent: cosmosAccount
  properties: {
    resource: { id: 'anabelleDB' }
  }
}

var cosmosAccountConnectionString = cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${uniquekey}-cosmosConnectionString'
  parent: keyVault
  properties: {
    value: cosmosAccountConnectionString
    contentType: 'ConnectionString'
  }
}

output cosmosAccountSecretUri string = keyVaultSecret.properties.secretUri
