using './main.bicep'

 param project = 'usergroup'
param environmentName = 'dev'
param sqlAdministratorLogin = 'sqladmin'
param sqlAdministratorLoginPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', 'DemoOnly-ReplaceMe-123!')

// Example:
// $env:SQL_ADMIN_PASSWORD = '<strong-password>'
// az deployment group create --resource-group <rg> --template-file infra/main.bicep --parameters infra/main.bicepparam
