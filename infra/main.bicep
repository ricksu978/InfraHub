// main.bicep


// Parameters
param projectName string = 'infrahub'
param environmentName string = 'dev'
param location string = resourceGroup().location
param sqlAdminLogin string
@secure()
param sqlAdminPassword string

// Variables
var nameSuffix = toLower('${projectName}-${environmentName}')

module hosting './modules/hosting.bicep' = {
  name: 'hosting'
  params: {
    nameSuffix: nameSuffix
    location: location
  }
}


module database './modules/database.bicep' = {
  name: 'database'
  params: {
    nameSuffix: nameSuffix
    location: location
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    nameSuffix: nameSuffix
    location: location
  }
}


output webAppUrl string = hosting.outputs.webAppUrl
output sqlServerName string = database.outputs.sqlServerName
output sqlDatabaseName string = database.outputs.sqlDatabaseName
output keyVaultName string = keyvault.outputs.keyVaultName

