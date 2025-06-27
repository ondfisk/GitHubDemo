param location string = resourceGroup().location
param appServicePlanSku string = 'P0v3'
param databaseSku string = 'Basic'
param stagingDatabaseSku string = 'Basic'

param databaseAdminGroupName string
param databaseAdminGroupId string

var deploymentSlotName = 'staging'
var databaseName = 'Movies'
var stagingDatabaseName = '${databaseName}Staging'
var suffix = substring(uniqueString(resourceGroup().id), 0, 8)
var logAnalyticsWorkspaceName = 'log-${suffix}'
var appServicePlanName = 'plan-${suffix}'
var webAppName = 'web-${suffix}'
var sqlServerName = 'sql-${suffix}'
var containerRegistryName = 'registry0${suffix}'
var acrPull = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

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
        'AZURE_SQL_CONNECTIONSTRING'
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
      AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity;'
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
      AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${stagingDatabaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity;'
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
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource stagingApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${webAppName}-staging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: databaseAdminGroupName
      principalType: 'Group'
      sid: databaseAdminGroupId
    }
  }

  resource azureServices 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  resource database 'databases' = {
    name: databaseName
    location: location
    sku: {
      name: databaseSku
    }
    properties: {}
  }

  resource stagingDatabase 'databases' = {
    name: stagingDatabaseName
    location: location
    sku: {
      name: stagingDatabaseSku
    }
    properties: {}
  }
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
