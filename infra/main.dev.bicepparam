using './main.bicep'

param project = 'iac-bicep-demo'
param environmentName = 'dev'
param sqlAdministratorLogin = 'sqladmin-dev'
param sqlAdministratorLoginPassword = readEnvironmentVariable(
  'SQL_ADMIN_PASSWORD',
  'DemoOnly-ReplaceMe-123!'
)
