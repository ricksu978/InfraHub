
using './main.bicep'

param projectName = 'infrahub'
param environmentName = 'dev'
param sqlAdminLogin = 'sqladminuser'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD', '')
