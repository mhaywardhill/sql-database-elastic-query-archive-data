targetScope = 'resourceGroup'

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('SQL administrator login')
param sqlAdminLogin string

@description('SQL administrator password')
@secure()
param sqlAdminPassword string

@description('Name of the first SQL database.')
param databaseOneName string = 'appdb-primary'

@description('Name of the second SQL database.')
param databaseTwoName string = 'appdb-archive'

@description('SQL Database SKU name. Example: Basic, S0, S1, GP_S_Gen5_1.')
param databaseSkuName string = 'S0'

@description('Allow Azure services to access this server (required for elastic query)')
param allowAzureServices bool = true

module sqlServer 'modules/sqlServer.bicep' = {
  name: 'deploy-sql-server'
  params: {
    sqlServerName: sqlServerName
    location: location
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    allowAzureServices: allowAzureServices
  }
}

module databaseOne 'modules/sqlDatabase.bicep' = {
  name: 'deploy-database-one'
  params: {
    sqlServerName: sqlServerName
    databaseName: databaseOneName
    location: location
    databaseSkuName: databaseSkuName
  }
  dependsOn: [
    sqlServer
  ]
}

module databaseTwo 'modules/sqlDatabase.bicep' = {
  name: 'deploy-database-two'
  params: {
    sqlServerName: sqlServerName
    databaseName: databaseTwoName
    location: location
    databaseSkuName: databaseSkuName
  }
  dependsOn: [
    sqlServer
  ]
}

resource sqlServerRef 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource databaseOneRef 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  name: databaseOneName
  parent: sqlServerRef
}

resource databaseTwoRef 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  name: databaseTwoName
  parent: sqlServerRef
}

output sqlServerResourceId string = sqlServerRef.id
output databaseOneResourceId string = databaseOneRef.id
output databaseTwoResourceId string = databaseTwoRef.id
