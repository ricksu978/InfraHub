// infra/modules/database.bicep

param nameSuffix string
param location string
param sqlAdminLogin string

@secure()
param sqlAdminPassword string

var sqlServerName = 'sql-${nameSuffix}'
var sqlDatabaseName = 'sqldb-${nameSuffix}'

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name

