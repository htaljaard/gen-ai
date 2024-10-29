param keyVaultName string
param resourceName string

var uniqueStr = uniqueString(resourceGroup().id, resourceName)
var guidStr = guid(resourceGroup().id, resourceName)
var safeGuid = replace(guidStr, '-', '')
var combinedStr = '${uniqueStr}${safeGuid}'

var ivString = take(uniqueString(safeGuid, 'iv'), 16)
var randomStringKey = take(combinedStr, 32)

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource keySecretKey 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: '${resourceName}-encryption-Key'
  properties: {
    contentType: 'text/plain'
    value: randomStringKey
  }
}

resource keySecretIV 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: '${resourceName}-encryption-iv'
  properties: {
    contentType: 'text/plain'
    value: ivString
  }
}

output encryptionKeySecretUri string = keySecretKey.properties.secretUri
output encryptionIVSecretUri string = keySecretIV.properties.secretUri
