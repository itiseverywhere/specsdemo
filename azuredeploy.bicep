@description('Name of the App Service plan to create')
param appServicePlanName string = 'todo-app-plan'

@description('Name of the App Service (Web App)')
param webAppName string = 'todo-app-service'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Azure SKU for App Service Plan')
param skuName string = 'B1'

@description('Cosmos DB account name (must be globally unique)')
param cosmosAccountName string = 'todocosmos${uniqueString(resourceGroup().id)}'

@description('Key Vault name (must be globally unique)')
param keyVaultName string = 'todokv${uniqueString(resourceGroup().id)}'

@description('Azure App Service runtime stack (linux)')
param linuxFxVersion string = 'NODE|18-lts'

// Cosmos DB account (SQL API)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-07-01-preview' = {
  name: '${cosmosAccount.name}/todos-db'
  properties: {
    resource: {
      id: 'todos-db'
    }
    options: {}
  }
  dependsOn: [cosmosAccount]
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-07-01-preview' = {
  name: '${cosmosDb.name}/todos'
  properties: {
    resource: {
      id: 'todos'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
      }
    }
    options: {}
  }
  dependsOn: [cosmosDb]
}

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enableSoftDelete: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
  dependsOn: [
    webApp
  ]
}

// Produce Cosmos connection string and store in Key Vault
var cosmosConnectionString = listConnectionStrings(cosmosAccount.id, cosmosAccount.apiVersion).connectionStrings[0].connectionString

resource cosmosSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVault.name}/CosmosConnectionString'
  properties: {
    value: cosmosConnectionString
  }
  dependsOn: [
    keyVault
    cosmosAccount
  ]
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: 'Basic'
  }
  properties: {
    reserved: true // Linux
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'COSMOS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${cosmosSecret.properties.secretUriWithVersion})'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
    clientAffinityEnabled: false
  }
  dependsOn: [
    appServicePlan
    cosmosSecret
  ]
}

output webAppDefaultHostName string = webApp.properties.defaultHostName
