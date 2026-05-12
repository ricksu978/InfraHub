using './main.bicep'

param project = 'iac-bicep-demo'
param environmentName = 'prod'
param sqlAdministratorLogin = 'sqladmin-prod'
param sqlAdministratorLoginPassword = readEnvironmentVariable(
  'SQL_ADMIN_PASSWORD',
  'DemoOnly-ReplaceMe-123!'
)
