using './main.bicep'

param projectName = 'infrahub'
param environmentName = 'prod'
param sqlAdminLogin = 'sqladminuser'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
