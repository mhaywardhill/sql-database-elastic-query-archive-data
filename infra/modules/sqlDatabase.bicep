@description('SQL Server name that will host the database')
param sqlServerName string

@description('SQL Database name')
param databaseName string

@description('Azure region')
param location string

@description('SQL Database SKU name. Example: Basic, S0, S1, GP_S_Gen5_1.')
param databaseSkuName string = 'S0'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: databaseName
  parent: sqlServer
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output databaseResourceId string = sqlDatabase.id
output databaseName string = sqlDatabase.name
