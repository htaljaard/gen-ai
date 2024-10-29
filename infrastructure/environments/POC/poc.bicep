//general
param resourceName string = 'anabelle'
param envName string = 'uat'
param tags object = {
  environment: envName
}

//ENTRA
#disable-next-line no-hardcoded-env-urls
param instance string = 'https://login.microsoftonline.com/'
param tenantId string
param clientId string
@secure()
param clientSecret string
param domain string

var uniquekey = uniqueString(resourceGroup().id, resourceName, envName)
var location = resourceGroup().location

// Role definition Ids for managed identity role assignments
var roleDefinitionIds = {
  storage: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  keyvault: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  servicebus: '090c5cfd-751d-490a-894a-3ce6f1109419' // Azure Service Bus Data Owner
  cosmosdbDataReader: '00000000-0000-0000-0000-000000000001' // Cosmos DB Built-in Data Reader
}

//VNET
@description('Resource Group for the web application.')
resource vnetResource 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${uniquekey}'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        //[0] App Gateway
        name: 'ag-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        //[1] App Service
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'serverFarmDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        //[2] Resources
        name: 'resource-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        //[3] Private Endpoints
        name: 'pep-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: tags
}

//App Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: '${uniquekey}-appinsights'
  location: resourceGroup().location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

//Key Vault 
module keyVaultPepModule '../../utility/pep.bicep' = {
  name: 'keyVaultPepModule'
  params: {
    vnetResourceId: vnetResource.id
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: vnetResource.properties.subnets[2].id
    resourceType: 'vault'
    privateEndPoint: 'privatelink.vaultcore.azure.net'
    linkedServiceId: keyvaultResource.id
    pepName: 'keyvault'
  }
}

resource keyvaultResource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'z${uniquekey}-kv'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    publicNetworkAccess: 'disabled'
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

//ENTRA Secrets
resource clientIdSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  name: '${uniquekey}-clientId'
  parent: keyvaultResource
  properties: {
    value: clientId
  }
}

resource clientSecretSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  name: '${uniquekey}-clientSecret'
  parent: keyvaultResource
  properties: {
    value: clientSecret
  }
}

resource tenantIdSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  name: '${uniquekey}-tenantId'
  parent: keyvaultResource
  properties: {
    value: tenantId
  }
}

resource domainSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  name: '${uniquekey}-domain'
  parent: keyvaultResource
  properties: {
    value: domain
  }
}

//Storage Account
module storageAccount './storageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    uniquekey: uniquekey
    subnetId: vnetResource.properties.subnets[3].id
    location: location
    keyVaultName: keyvaultResource.name
    tags: tags
    vnetResourceId: vnetResource.id
  }
}

//Cosmos DB
module cosmos 'cosmos.bicep' = {
  name: 'cosmos'
  params: {
    uniquekey: uniquekey
    location: location
    subnetId: vnetResource.properties.subnets[2].id
    keyVaultName: keyvaultResource.name
    vnetResourceId: vnetResource.id
    tags: tags
  }
}

//Encryption Keys for Secret Storage
module encryptionSecrets 'encryption.bicep' = {
  name: 'encryptionSecrets'
  params: {
    keyVaultName: keyvaultResource.name
    resourceName: uniquekey
  }
}

//Document Intelligence

//Putting this pep module out of the document intelligence module to avoid race condition with openai pep module
module diPep '../../utility/pep.bicep' = {
  name: 'diPep'
  params: {
    vnetResourceId: vnetResource.id
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: vnetResource.properties.subnets[2].id
    resourceType: 'account'
    privateEndPoint: 'privatelink.openai.azure.com'
    linkedServiceId: documentIntelligence.outputs.documentIntelligenceId
    pepName: 'docintel'
  }
  dependsOn: [
    documentIntelligence
    openAIPep
  ]
}
module documentIntelligence './documentintelligence.bicep' = {
  name: 'documentIntelligence'
  params: {
    keyVaultName: keyvaultResource.name
    uniquekey: uniquekey
    subnetId: vnetResource.properties.subnets[2].id
    vnetResourceId: vnetResource.id
    tags: tags
  }
}

//openAI
module openAIPep '../../utility/pep.bicep' = {
  name: 'openAIPep'
  params: {
    vnetResourceId: vnetResource.id
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: vnetResource.properties.subnets[2].id
    resourceType: 'account'
    privateEndPoint: 'privatelink.openai.azure.com'
    linkedServiceId: openai.outputs.resourceId
    pepName: 'openai'
  }
}
module openai 'br/public:avm/res/cognitive-services/account:0.7.0' = {
  name: 'openai'
  params: {
    kind: 'OpenAI'
    name: '${uniquekey}-openai'
    location: resourceGroup().location
    tags: tags
    customSubDomainName: uniquekey
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    sku: 'S0'
    deployments: [
      {
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-05-13'
        }
        sku: { name: 'GlobalStandard', capacity: 10 }
        name: 'gpt-4o'
      }
      {
        model: {
          format: 'OpenAI'
          name: 'gpt-4o-mini'
          version: '2024-07-18'
        }
        sku: { name: 'GlobalStandard', capacity: 100 }
        name: 'gpt-4o-mini'
      }
      {
        model: {
          format: 'OpenAI'
          name: 'text-embedding-ada-002'
          version: '2'
        }
        sku: { name: 'Standard', capacity: 30 }
        name: 'text-embedding-ada-002'
      }
    ]
  }
}

//app service 
module appServicePep '../../utility/pep.bicep' = {
  name: 'appServicePep'
  params: {
    vnetResourceId: vnetResource.id
    uniquekey: uniquekey
    tags: tags
    location: location
    subnetId: vnetResource.properties.subnets[2].id
    resourceType: 'sites'
    privateEndPoint: 'privatelink.azurewebsites.net'
    linkedServiceId: appService1.id
    pepName: 'appservice1'
  }
}
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${resourceName}-appserviceplan'
  location: resourceGroup().location
  sku: {
    name: 'B1'
    tier: 'Shared'
  }
  tags: tags
  properties: {}
}
resource appService1 'Microsoft.Web/sites@2023-12-01' = {
  name: '${resourceName}-app1'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    vnetRouteAllEnabled: false
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: vnetResource.properties.subnets[1].id
    siteConfig: {
      windowsFxVersion: 'DOTNETCORE|8.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'Encryption__Key'
          value: '@Microsoft.KeyVault(SecretUri=${encryptionSecrets.outputs.encryptionKeySecretUri})'
        }
        {
          name: 'Encryption__IV'
          value: '@Microsoft.KeyVault(SecretUri=${encryptionSecrets.outputs.encryptionIVSecretUri})'
        }
        {
          name: 'AzureAd__Instance'
          value: instance
        }
        {
          name: 'AzureAd__TenantId'
          value: '@Microsoft.KeyVault(SecretUri=${tenantIdSecret.properties.secretUri})'
        }
        {
          name: 'AzureAd__ClientId'
          value: '@Microsoft.KeyVault(SecretUri=${clientIdSecret.properties.secretUri})'
        }
        {
          name: 'AzureAd__ClientSecret'
          value: '@Microsoft.KeyVault(SecretUri=${clientSecretSecret.properties.secretUri})'
        }
        {
          name: 'AzureAd__Domain'
          value: '@Microsoft.KeyVault(SecretUri=${domainSecret.properties.secretUri})'
        }
        {
          name: 'Serilog:MinimumLevel'
          value: 'Information'
        }
        {
          name: 'Serilog:Using:0'
          value: 'Serilog.Sinks.Console'
        }
        {
          name: 'Serilog:Using:1'
          value: 'Serilog.Sinks.File'
        }
        {
          name: 'Serilog:WriteTo:0:Name'
          value: 'Console'
        }
      ]
      connectionStrings: [
        {
          name: 'BLOB_STORAGE_CONNECTION_STRING'
          connectionString: '@Microsoft.KeyVault(SecretUri=${storageAccount.outputs.storageAccountSecretUri})'
          type: 'Custom'
        }
        {
          name: 'CosmosDBConnection'
          connectionString: '@Microsoft.KeyVault(SecretUri=${cosmos.outputs.cosmosAccountSecretUri})'
          type: 'Custom'
        }
      ]
    }
  }
  tags: tags
}
resource appserviceRoleToKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, appService1.id, roleDefinitionIds.keyvault)
  properties: {
    principalId: appService1.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIds.keyvault)
  }
}

//WAF
module waf 'waf.bicep' = {
  name: 'waf'
  params: {
    resourceName: uniquekey
    location: location
    tags: tags
    vnetName: vnetResource.name
    agName: 'ag-${uniquekey}'
  }
}

//Budget
module budget 'budget.bicep' = {
  name: 'budget'
  params: {
    startDate: '2024-10-1' //need to update this
    endDate: '2024-12-31'
    contactEmails: ['hein.taljaard@needcoffee.net']
  }
}
