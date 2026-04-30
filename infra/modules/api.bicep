@description('Name of the App Service Plan.')
param appServicePlanName string

@description('Name of the Web App (must be globally unique).')
param webAppName string

@description('Azure region for the API resources.')
param location string = resourceGroup().location

@description('Tags to apply to the API resources.')
param tags object = {}

@description('SKU name for the App Service Plan (e.g. B1, S1, P0v3).')
param skuName string = 'B1'

@description('.NET runtime stack for the Linux Web App.')
param linuxFxVersion string = 'DOTNETCORE|10.0'

@description('Application settings to expose to the API. Connection strings should be Key Vault references.')
param appSettings object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [for setting in items(appSettings): {
        name: setting.key
        value: string(setting.value)
      }]
    }
  }
}

output appServicePlanId string = appServicePlan.id
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output webAppPrincipalId string = webApp.identity.principalId
