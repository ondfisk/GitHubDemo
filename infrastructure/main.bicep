param location string = resourceGroup().location
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param appServicePlanName string
param webAppName string
param sqlServerName string
param databaseName string
param databaseSku string = 'Basic'
param sqlAdminGroupName string
param sqlAdminGroupId string
param stagingDatabaseSku string = 'Basic'

var deploymentSlotName = 'staging'
var stagingDatabaseName = '${databaseName}Staging'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  kind: 'linux'
  location: location
  sku: {
    name: 'P0v3'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    hyperV: false
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      detailedErrorLoggingEnabled: true
      requestTracingEnabled: true
      httpLoggingEnabled: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource deploymentSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  name: deploymentSlotName
  parent: webApp
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    hyperV: false
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      detailedErrorLoggingEnabled: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {}
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
  }
}

resource connectionStrings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'connectionstrings'
  parent: webApp
  properties: {
    AppDbContext: {
      value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default"'
      type: 'SQLAzure'
    }
  }
}

resource slotConfigNames 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'slotConfigNames'
  parent: webApp
  properties: {
    appSettingNames: [
      'APPLICATIONINSIGHTS_CONNECTION_STRING'
    ]
    azureStorageConfigNames: []
    connectionStringNames: [
      'AppDbContext'
    ]
  }
}

resource stagingApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${applicationInsightsName}-staging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource stagingAppSettings 'Microsoft.Web/sites/slots/config@2023-12-01' = {
  name: 'appsettings'
  parent: deploymentSlot
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: stagingApplicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
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
    minimalTlsVersion: '1.2'
  }

  resource azureServices 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: databaseSku
  }
  properties: {
  }
}

resource slotConnectionStrings 'Microsoft.Web/sites/slots/config@2022-09-01' = {
  name: 'connectionstrings'
  parent: deploymentSlot
  properties: {
    AppDbContext: {
      value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${stagingDatabaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default"'
      type: 'SQLAzure'
    }
  }
}

resource stagingDatabase 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServer
  name: stagingDatabaseName
  location: location
  sku: {
    name: stagingDatabaseSku
  }
  properties: {}
}
