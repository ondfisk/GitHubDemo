param location string = resourceGroup().location
param appServicePlanSku string = 'P0v3'

param logAnalyticsWorkspaceId string

var deploymentSlotName = 'staging'
var databaseName = 'Movies'
var stagingDatabaseName = '${databaseName}Staging'
var suffix = substring(uniqueString(resourceGroup().id), 0, 8)
var appServicePlanName = 'plan-${suffix}'
var webAppName = 'web-${suffix}'
var databaseServerName = 'db-${suffix}'
var containerRegistryName = 'registry0${suffix}'
var acrPull = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      acrUseManagedIdentityCreds: true
      healthCheckPath: '/healthz'
    }
  }

  resource slotConfigNames 'config' = {
    name: 'slotConfigNames'
    properties: {
      appSettingNames: [
        'APPLICATIONINSIGHTS_CONNECTION_STRING'
        'AZURE_POSTGRESQL_CONNECTIONSTRING'
      ]
      azureStorageConfigNames: []
      connectionStringNames: []
    }
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
      ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
      AZURE_POSTGRESQL_CONNECTIONSTRING: 'Server=${postgresqlServer.properties.fullyQualifiedDomainName};Port=5432;Database=${databaseName};SslMode=Require;User Id=aad_${databaseName}'
      XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    }
  }
}

resource deploymentSlot 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: webApp
  name: deploymentSlotName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      acrUseManagedIdentityCreds: true
      healthCheckPath: '/healthz'
    }
  }

  resource stagingAppSettings 'config' = {
    name: 'appsettings'
    properties: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: stagingApplicationInsights.properties.ConnectionString
      ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
      AZURE_POSTGRESQL_CONNECTIONSTRING: 'Server=${postgresqlServer.properties.fullyQualifiedDomainName};Port=5432;Database=${stagingDatabaseName};SslMode=Require;User Id=aad_${stagingDatabaseName}'
      XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: webAppName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource stagingApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${webAppName}-staging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: databaseServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    createMode: 'Default'
    version: '17'
    storage: {
      storageSizeGB: 32
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: tenant().tenantId
    }
  }
}

resource postgresqlAdministrators 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = {
  parent: postgresqlServer
  name: deployer().objectId
  properties: {
    tenantId: tenant().tenantId
    principalName: deployer().userPrincipalName
    principalType: 'Group'
  }
}

resource postgresqlFirewallRules 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgresqlServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresqlServer
  name: databaseName
  properties: {}
}

resource stagingDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresqlServer
  name: stagingDatabaseName
  properties: {}
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

resource webAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, webApp.id, acrPull)
  scope: containerRegistry
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPull
  }
}

resource deploymentSlotRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, deploymentSlot.id, acrPull)
  scope: containerRegistry
  properties: {
    principalId: deploymentSlot.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPull
  }
}

output webAppName string = webApp.name
output containerRegistryName string = containerRegistry.name
