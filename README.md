# Azure DevOps self hosted agent in Azure Container App

This is the companion repository for the [Run a self hosted agent in Docker](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops) and [Deploy to Azure Container Apps from Azure Pipelines](https://learn.microsoft.com/en-us/azure/container-apps/azure-pipelines). 

This project helps Azure DevOps engineers to setup Azure DevOps self-hosted agent running in Azure Container App

## Architecture
![alt text](images/ca-selfhostedagent-architecture.png.png)

### Components

#### Azure DevOps
Source code is maintained in Azure DevOps Git repository. This pipeline will be triggered when a developer check-in code to GitHub repository.

#### Azure Container Registry
stores self hosted agent container images. You can also use other container registries like Docker Hub.

#### Azure Container Apps
Container App runs Azure DevOps self hosted agent container and listen for any pipeline jobs queued and runs them.

## Getting Started

In this quick start, you create Azure DevOps pipeline which deploys Bicep script to create an Azure container registry, run registry task to build from a Dockerfile and push to container registry, create user assigned identity, assign acrPull role on container registry, create container app with user assigned identity, set the registry and pull image from container registry.

### Create an Azure DevOps repository and clone the source code
Create a new Git repository in Azure DevOps and clone the source code from [Github repo](https://github.com/bnagajagadeesh/azuredevopsagent-ca.git).

run the following command to clone the repository
```bash
git clone https://github.com/bnagajagadeesh/azuredevopsagent-ca.git azuredevopsagent
```

### Create an Azure DevOps service connection
Create an Azure DevOps service connection for your Azure subscription. You can refer to  [create an azure devops service connection](https://learn.microsoft.com/en-us/azure/container-apps/azure-pipelines#create-an-azure-devops-service-connection) for detailed steps.

The minimum role required is the Contributor role. This role has full access to read, write, and manage all types of Azure resources.

However, if you want to follow the principle of least privilege, you can create a custom role that has only the necessary permissions. The necessary permissions include:

Microsoft.Resources/deployments/*: To create or update deployments.
Microsoft.Web/containerApps/*: To create or update Container Apps.
Microsoft.ContainerRegistry/registries/*: To create or update Container Registries.

### Create an Azure DevOps YAML pipeline
Create a new Azure DevOps YAML pipeline using [azure-pipelines.yml](azure-pipelines.yml). You can refer to  [create an azure devops yaml pipeline](https://learn.microsoft.com/en-us/azure/container-apps/azure-pipelines#create-an-azure-devops-yaml-pipeline) for detailed steps.

### Create Agent pool
Create a new agent pool following steps given [here](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser#create-agent-pools) 

## Build

### Build and deploy to Container Apps
Run Azure DevOps pipeline which uses AzureResourceManagerTemplateDeployment@3 task to run main.bicep file.

This main.bicep file is a Bicep template for deploying an Azure Container App with a self-hosted Azure DevOps agent. Here's a summary of what it does:

Parameters: It defines a set of parameters that can be used to customize the deployment, such as the names of the container app, environment, and log analytics workspace, the location for all resources, the minimum and maximum number of replicas, the name of the Azure Container Registry (ACR), and details about the Git repository and Docker image.

Log Analytics Workspace: It creates a Log Analytics workspace for monitoring the container app.

Azure Container Registry (ACR): It creates an ACR for storing Docker images.

Build ACR Image: It uses a module to build a Docker image from a Git repository and push it to the ACR.

User Assigned Identity (UAI): It creates a UAI and assigns it the ACR Pull role, allowing the container app to pull images from the ACR.

Container App Environment: It creates a container app environment with a consumption-based pricing model.

Container App: It creates a container app with the UAI and deploys it to the container app environment. The app is configured to use the Docker image from the ACR, and it's scaled based on HTTP requests.

Output: It outputs the fully qualified domain name (FQDN) of the container app.

You get an error in container app after the deployment due to missing permissions. 
![alt text](images/ca-agent-error.png)

Access denied. ca-azpagent needs Manage permissions for pool selfhostedagentpool to perform the action. For more information, contact the Azure DevOps Server administrator.

To fix this issue, you need to add below permissions in Azure DevOps

Add System assigned managed identity of Container App to 
 1) Azure DevOps Orgnization settings - users and
 2) Add an Azure Managed Identity to an Azure DevOps agent pool follow these steps:
Navigate to your Azure DevOps organization.
Go to Project Settings.
Under Pipelines, select Agent Pools.
Select the desired agent pool.
Go to the Security tab.
Click on "Add" and then "Add Azure AD user or group".
In the dialog box that appears, search for the name of your Managed Identity.
Select the Managed Identity from the list, Select Role as "Administrator" and click on "Add".

### Test
Naviate to Azure DevOps - Orgnization settings - Pipelines - Agent pools - selfhostedagentpool - Agents

You should see one agent running with the status online as shown in the screenshot below.

![alt text](images/ca-selfhostedagent-test.png)


## Contribute
Contributions to AzureDevOpsAgent are welcome. Here is how you can contribute:

[Submit bugs](https://github.com/bnagajagadeesh/azuredevopsagent-ca/issues) and help us verify fixes.
[Submit pull requests](https://github.com/bnagajagadeesh/azuredevopsagent-ca/pulls) for bug fixes and features and discuss existing proposals

## License
Code licensed under the [GNU GENERAL PUBLIC LICENSE](LICENSE).

## Contact Us
If you have questions or you would like to reach out to us about an issue you're having or for development advice as you work on a issue, you can reach us as follows:

Open an [issue](https://github.com/bnagajagadeesh/azuredevopsagent-ca/issues/new) and prefix the issue title with [Question]. See [Question](https://github.com/bnagajagadeesh/azuredevopsagent-ca/issues?q=label%3AQuestion) tag for already-opened questions.