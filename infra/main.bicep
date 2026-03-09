targetScope = 'resourceGroup'

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Administrator username for the SQL logical server.')
param sqlAdminLogin string

@secure()
@description('Administrator password for the SQL logical server.')
param sqlAdminPassword string

@description('Name of the first SQL database.')
param databaseOneName string = 'appdb-primary'

@description('Name of the second SQL database.')
param databaseTwoName string = 'appdb-archive'

@description('SQL Database SKU name. Example: Basic, S0, S1, GP_S_Gen5_1.')
param databaseSkuName string = 'S0'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}

resource databaseOne 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: databaseOneName
  parent: sqlServer
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource databaseTwo 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: databaseTwoName
  parent: sqlServer
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output sqlServerResourceId string = sqlServer.id
output databaseOneResourceId string = databaseOne.id
output databaseTwoResourceId string = databaseTwo.id
