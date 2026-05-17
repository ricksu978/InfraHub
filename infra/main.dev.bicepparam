using './main.bicep'

param projectName = 'demoapp'
param environmentName = 'dev'
param sqlAdminLogin = 'sqladminuser'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
