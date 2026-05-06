@description('A short name used to derive resource names. Letters and numbers only, 2-10 chars.')
@minLength(2)
@maxLength(10)
param project string = 'usergroup'

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

// A short, deterministic suffix keeps globally-unique names stable per resource group.
var uniqueSuffix = uniqueString(resourceGroup().id, project, environmentName)
var nameSuffix = toLower('${project}-${environmentName}')

// Naming follows the Microsoft Cloud Adoption Framework resource abbreviations:
// https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
// App Service plan = asp, Web app = app, Key Vault = kv, Azure SQL server = sql, Azure SQL database = sqldb.
// Group all derived resource names together so the naming convention is easy to explain.
var resourceNames = {
  webApp: 'app-${nameSuffix}-${uniqueSuffix}'
  appServicePlan: 'asp-${nameSuffix}'

  // Key Vault names are 3-24 chars, alphanumerics and hyphens only.
  keyVault: take(replace('kv-${nameSuffix}-${uniqueSuffix}', '--', '-'), 24)

  // SQL server names must be lowercase, 1-63 chars, alphanumerics and hyphens, cannot start/end with hyphen.
  sqlServer: 'sql-${nameSuffix}-${uniqueSuffix}'
  sqlDatabase: 'sqldb-${nameSuffix}'
}

// Key Vault URI follows a deterministic pattern. Computing it here (instead of consuming
// keyVault.outputs.uri) lets us pass the URI to the API module without creating a cycle
// between the API and Key Vault modules.
var keyVaultUri = 'https://${resourceNames.keyVault}${environment().suffixes.keyvaultDns}/'

var resourceTags = {
  project: project
  environment: environmentName
  'managed-by': 'bicep'
}

// Keep application configuration in one place so it is easier to map template values
// to the app settings visible in App Service.
var apiAppSettings = {
  ASPNETCORE_ENVIRONMENT: environmentName == 'prod' ? 'Production' : 'Development'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  // Resolved at runtime from Key Vault using the App Service managed identity.
  ConnectionStrings__DefaultConnection: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/SqlConnectionString)'
  KeyVault__Uri: keyVaultUri
}

// ---------- Database ----------
module database 'modules/database.bicep' = {
  params: {
    sqlServerName: resourceNames.sqlServer
    databaseName: resourceNames.sqlDatabase
    location: location
    tags: resourceTags
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
  }
}

// ---------- API (App Service) ----------
// The App Service is created first (without the Key Vault reference) so that the system-assigned
// managed identity exists and can be granted access to Key Vault. The connection string is then
// surfaced via Key Vault references on the app settings of the deployed app.
module api 'modules/api.bicep' = {
  params: {
    appServicePlanName: resourceNames.appServicePlan
    webAppName: resourceNames.webApp
    location: location
    tags: resourceTags
    appSettings: apiAppSettings
  }
}

// ---------- Key Vault ----------
// Grants the API's managed identity the "Key Vault Secrets User" role so it can read secrets.
module keyVault 'modules/keyvault.bicep' = {
  params: {
    #disable-next-line BCP334
    keyVaultName: resourceNames.keyVault
    location: location
    tags: resourceTags
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
