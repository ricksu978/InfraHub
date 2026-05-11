@description('A short name used to derive resource names. Letters and numbers only, 2-15 chars.')
@minLength(2)
@maxLength(15)
param project string = 'iac-bicep-demo'

@description('Environment name, e.g. dev, uat, prod. Used in resource naming and tags.')
@allowed([
  'dev'
  'uat'
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

var nameSuffix = toLower('${project}-${environmentName}')

// Naming follows the Microsoft Cloud Adoption Framework resource abbreviations:
// https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
// App Service plan = asp, Web app = app, Key Vault = kv, Azure SQL server = sql, Azure SQL database = sqldb.
// Group all derived resource names together so the naming convention is easy to explain.
var resourceNames = {
  webApp: 'app-${nameSuffix}'
  appServicePlan: 'asp-${nameSuffix}'
  keyVault: 'kv-${nameSuffix}'
  sqlServer: 'sql-${nameSuffix}'
  sqlDatabase: 'sqldb-${nameSuffix}'
}

// Key Vault URI follows a deterministic pattern. Computing it here (instead of consuming
// keyVault.outputs.uri) lets us pass the URI to the API module without creating a cycle
// between the API and Key Vault modules.
var keyVaultUri = 'https://${resourceNames.keyVault}${environment().suffixes.keyvaultDns}/'

var resourceTags = {}
// {
//   project: project
//   environment: environmentName
//   'managed-by': 'bicep'
// }


// ---------- Database ----------
module database 'modules/database.bicep' = {
  name: 'database-deployment'
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
module api 'modules/api.bicep' = {
  name: 'api-deployment'
  params: {
    appServicePlanName: resourceNames.appServicePlan
    webAppName: resourceNames.webApp
    location: location
    tags: resourceTags
    appSettings: {
      ASPNETCORE_ENVIRONMENT: environmentName == 'prod' ? 'Production' : 'Development'
      ConnectionStrings__DefaultConnection: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/SqlConnectionString)'
      KeyVault__Uri: keyVaultUri
    }
  }
}

// ---------- Key Vault ----------
// Grants the API's managed identity the "Key Vault Secrets User" role so it can read secrets.
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
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
