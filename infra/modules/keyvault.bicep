@description('Name of the Key Vault. Must be globally unique, 3-24 chars, alphanumerics and hyphens.')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region for the Key Vault.')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault.')
param tags object = {}

@description('Tenant ID used for RBAC/access policies. Defaults to the current subscription tenant.')
param tenantId string = subscription().tenantId

@description('SKU for the Key Vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Object IDs (e.g. App Service managed identity) that should receive the Key Vault Secrets User role.')
param secretsUserPrincipalIds array = []

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
  }
}

// Built-in role: Key Vault Secrets User
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource secretsUserAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in secretsUserPrincipalIds: {
  name: guid(keyVault.id, principalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
  }
}]

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
