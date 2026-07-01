// infra/modules/keyVault.bicep

param nameSuffix string
param location string

// Key Vault names are globally unique + max 24 chars, so append a hash of the RG id.
var keyVaultName = take('kv-${nameSuffix}-${uniqueString(resourceGroup().id)}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
  }
}

output keyVaultName string = keyVault.name

