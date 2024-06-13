@description('Specifies the name of the container app.')
param containerAppName string = 'ca-azpagent'

@description('Specifies the name of the container app environment.')
param containerAppEnvName string = 'ca-azpagent-env'

@description('Specifies the name of the log analytics workspace.')
param containerAppLogAnalyticsName string = 'ca-azpagent-log'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplica int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplica int = 3

@description('The name of the Azure Container Registry')
param AcrName string = 'crazpagent'

@description('The Git Repository URL, eg. https://github.com/YOURORG/YOURREPO.git')
param gitRepositoryUrl string = 'https://github.com/bnagajagadeesh/azuredevopsagent-ca.git'

@description('The name of the repository branch to use')
param gitBranch string = 'main'

@description('The directory in the repo that contains the dockerfile')
param gitRepoDirectory string = 'ContainerApp'

@description('The image name/path you want to create in ACR')
param imageName string = 'azpagent'

param imageTag string

@description('The ACR compute platform needed to build the image')
param acrBuildPlatform string = 'linux'

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
param currentTimestamp string = utcNow('yyyy-MM-dd-HHmmss')

param azpToken string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: containerAppLogAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: AcrName
  location: location
  sku: {
    name: 'Basic'
  }
}

module buildAcrImage 'br/public:deployment-scripts/build-acr:1.0.1' = {
  name: 'buildAcrImage-${replace(imageName,'/','-')}'
  params: {
    AcrName: acr.name
    location: location
    gitRepositoryUrl: gitRepositoryUrl
    gitBranch: gitBranch
    gitRepoDirectory: gitRepoDirectory
    imageName: imageName
    imageTag: imageTag
    acrBuildPlatform: acrBuildPlatform
  }
}

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'uid-${containerAppName}'
  location: location
}

@description('This allows the managed identity of the container app to access the registry and scope is applied to the ACR')
resource uaiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, uai.id, acrPullRole)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRole
    principalId: uai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerAppName
  location: location  
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      registries: [
        {          
          server: acr.properties.loginServer
          identity: uai.id
        }
      ]            
    }
    template: {
      revisionSuffix: 'revision-${currentTimestamp}'
      containers: [
        {
          name: containerAppName
          image: buildAcrImage.outputs.acrImage
          resources: {
            cpu: json('1')
            memory: '2Gi'
          }          
          env: [
            {
              name: 'AZP_URL'
              value: 'https://dev.azure.com/106025/'
            }
            {
              name: 'AZP_POOL'
              value: 'selfhostedagentpool'
            }
            {
              name: 'AZP_AGENT_NAME'
              value: 'containerapp-azpagent'
            }
            {
              name: 'AZP_TOKEN'
              value: azpToken
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplica
        maxReplicas: maxReplica
        rules: [
          {
            name: 'cpu-utilization'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'AverageValue'
                value: '75'
              }
            }
          }
        ]
      }
    }
  }
}
