using './main.bicep'

param projectName = 'iacdemo'
param environmentName = 'dev'
param location = 'australiaeast'
param sqlAdminLogin = 'sqladminuser'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
