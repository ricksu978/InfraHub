// infra/modules/keyVault.bicep

param nameSuffix string
param location string

var keyVaultName = 'kv-${nameSuffix}'

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

