@description('A short name used to derive resource names. Letters and numbers only, 2-10 chars.')
@minLength(2)
@maxLength(10)
param workloadName string = 'sswdemo'

@description('Environment name, e.g. dev, test, prod. Used in resource naming and tags.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('SQL administrator login name.')
param sqlAdministratorLogin string

@description('SQL administrator password. Provide via secure parameter or Key Vault reference.')
@secure()
param sqlAdministratorLoginPassword string

// ---------- Naming ----------
// A short, deterministic suffix keeps globally-unique names (Web App, Key Vault, SQL server) stable per resource group.
var uniqueSuffix = uniqueString(resourceGroup().id, workloadName, environmentName)
var namePrefix = toLower('${workloadName}-${environmentName}')

var apiAppName = '${namePrefix}-api-${uniqueSuffix}'
var apiPlanName = '${namePrefix}-plan'
// Key Vault names are 3-24 chars, alphanumerics and hyphens only.
var keyVaultName = take(replace('${namePrefix}-kv-${uniqueSuffix}', '--', '-'), 24)
// SQL server names must be lowercase, 1-63 chars, alphanumerics and hyphens, cannot start/end with hyphen.
var sqlServerName = '${namePrefix}-sql-${uniqueSuffix}'
var sqlDatabaseName = '${workloadName}db'

// Key Vault URI follows a deterministic pattern. Computing it here (instead of consuming
// keyVault.outputs.uri) lets us pass the URI to the API module without creating a cycle
// between the API and Key Vault modules.
var keyVaultUri = 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/'

var commonTags = {
  workload: workloadName
  environment: environmentName
  'managed-by': 'bicep'
  demo: 'ssw-2026-may-user-group'
}

// ---------- Database ----------
module database 'modules/database.bicep' = {
  name: 'database'
  params: {
    sqlServerName: sqlServerName
    databaseName: sqlDatabaseName
    location: location
    tags: commonTags
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
  }
}

// ---------- API (App Service) ----------
// The App Service is created first (without the Key Vault reference) so that the system-assigned
// managed identity exists and can be granted access to Key Vault. The connection string is then
// surfaced via Key Vault references on the app settings of the deployed app.
module api 'modules/api.bicep' = {
  name: 'api'
  params: {
    appServicePlanName: apiPlanName
    webAppName: apiAppName
    location: location
    tags: commonTags
    appSettings: {
      ASPNETCORE_ENVIRONMENT: environmentName == 'prod' ? 'Production' : 'Development'
      WEBSITE_RUN_FROM_PACKAGE: '1'
      // Resolved at runtime from Key Vault using the App Service managed identity.
      ConnectionStrings__DefaultConnection: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/SqlConnectionString)'
      KeyVault__Uri: keyVaultUri
    }
  }
}

// ---------- Key Vault ----------
// Grants the API's managed identity the "Key Vault Secrets User" role so it can read secrets.
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    #disable-next-line BCP334
    name: keyVaultName
    location: location
    tags: commonTags
    secretsUserPrincipalIds: [
      api.outputs.webAppPrincipalId
    ]
  }
}

// ---------- Outputs ----------
output apiHostName string = api.outputs.webAppHostName
output apiName string = api.outputs.webAppName
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
output sqlServerFqdn string = database.outputs.sqlServerFqdn
output sqlDatabaseName string = database.outputs.databaseName
