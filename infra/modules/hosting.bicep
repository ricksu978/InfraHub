// infra/modules/hosting.bicep

param nameSuffix string
param location string

var appServicePlanName = 'asp-${nameSuffix}'
var webAppName = 'app-${nameSuffix}'

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2025-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

