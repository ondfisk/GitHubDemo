param location string = resourceGroup().location
param logAnalyticsWorkspaceId string
param appServicePlanId string
param webAppName string
param sqlServerName string
param databaseName string
param databaseSku string = 'Basic'
param sqlAdminGroupName string
param sqlAdminGroupId string
param stagingDatabaseSku string = 'Basic'

var deploymentSlotName = 'staging'
var stagingDatabaseName = '${databaseName}Staging'

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
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
      AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity'
      XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    }
  }

  resource deploymentSlot 'slots' = {
    name: deploymentSlotName
    location: location
    kind: 'app,linux,container'
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      serverFarmId: appServicePlanId
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
        AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${stagingDatabaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity'
        XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
      }
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
      login: sqlAdminGroupName
      principalType: 'Group'
      sid: sqlAdminGroupId
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
