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

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    reserved: true
    hyperV: false
    siteConfig: {
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      detailedErrorLoggingEnabled: true
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      http20Enabled: true
      httpLoggingEnabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource deploymentSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  name: deploymentSlotName
  parent: webApp
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    reserved: true
    hyperV: false
    siteConfig: {
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      detailedErrorLoggingEnabled: true
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      http20Enabled: true
      httpLoggingEnabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
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

resource appSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
  }
}

resource slotConfigNames 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'slotConfigNames'
  parent: webApp
  properties: {
    appSettingNames: [
      'APPLICATIONINSIGHTS_CONNECTION_STRING'
      'AZURE_SQL_CONNECTIONSTRING'
    ]
    azureStorageConfigNames: []
    connectionStringNames: []
  }
}

resource stagingApplicationInsights 'Microsoft.Insights/components@2020-02-02'= {
  name: '${webAppName}-staging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource stagingAppSettings 'Microsoft.Web/sites/slots/config@2023-12-01' = {
  name: 'appsettings'
  parent: deploymentSlot
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: stagingApplicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    AZURE_SQL_CONNECTIONSTRING: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=ActiveDirectoryManagedIdentity'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
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

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: databaseSku
  }
  properties: {}
}

resource stagingDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: stagingDatabaseName
  location: location
  sku: {
    name: stagingDatabaseSku
  }
  properties: {}
}
