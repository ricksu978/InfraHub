@description('Name of the Azure SQL logical server. Must be globally unique, lowercase.')
param sqlServerName string

@description('Name of the SQL database.')
param databaseName string

@description('Azure region for the SQL resources.')
param location string = resourceGroup().location

@description('Tags to apply to the SQL resources.')
param tags object = {}

@description('SQL administrator login name.')
param administratorLogin string

@description('SQL administrator login password.')
@secure()
param administratorLoginPassword string

@description('SKU name for the database (e.g. Basic, S0, GP_S_Gen5_2).')
param skuName string = 'Basic'

@description('SKU tier for the database.')
param skuTier string = 'Basic'

@description('Allow other Azure services (e.g. App Service) to access the SQL server.')
param allowAzureServices bool = true

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// Allow Azure services and resources to access this server (start/end 0.0.0.0 is the documented marker).
resource allowAzureFirewallRule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = sqlDatabase.name
