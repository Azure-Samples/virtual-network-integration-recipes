# Azure Machine Learning Workspace in a managed virtual network

<!-- Replace "Recipe Template" title with name of the recipe. -->

## Scenario

<!-- Describe the usage scenario for this template.  Describe the challenges this recipes aims to address. -->
This scenario aims to address the challenge of correctly configuring an Azure machine learning workspace within a Microsoft managed VNet including ensuring appropriate connectivity with common services such as Azure Storage Account, Azure Key Vault, Azure Container Registry, Azure DevOps.

⚠️ WARNING: This code is experimental at this stage and provided solely for evaluation purposes. It is NOT intended for production use and may contain bugs, incomplete features, or other issues. Use at your own risk, as it may undergo significant changes without notice, and no guarantees or support are provided. By using this code, you acknowledge and agree to these conditions. Consult the documentation or contact the maintainer if you have questions or concerns.

### Problem Summary

<!--Briefly describe the problme that this recipe intends to resolve or make easier. -->
Azure machine learning workspace is composed of a number of different components: workspace storage account, key vault, machine learning Data Pipelines and Data Flows, SQL Dedicated pools, SQL Serverless pools, Spark pools and other external data sources. Despite being under a single machine learning umbrella service, each of these sub-components require a slightly different VNet configuration treatment to properly isolate network traffic. For example, generally you need at least four Private Endpoints configured for a single workspace each with connecting to a different sub-component. Another example, while managed workspace are generally a single tenant service with compute resources spun up within a designated Managed VNet, data scientist vm's, azure dev ops pipelines could be multi-tenanted and therefore require provisioning a Private Endpoint within the bridge vnet in order to connect to the workspace successfully. 

In addition to this, customers will also need to ensure that traffic between the Azure machine learning workspace studio can still privately flow between the workspace components and additional Azure services such as Storage and Key Vault. This is done through the use of Private Endpoints. Additionally, one has to keep in mind the secure integration with Azure DevOps pipelines and Github actions that are enabled through bridge virtual network.

This recipe aims to provide developers a starting point with IaC + PaC example of an Azure machine learning managed-vnet workspace with all sub-components correctly configured to ensure traffic stays private, while still being able to connect to common additional services such as machine learning studio Azure Storage and Azure Key Vault.

### Architecture

<!-- Include a high-level architecture diagram of the components used in this recipe. -->


### Recommendations

The following sections provide recommendations on when this recipe should, and should not, be used.

#### Recommended

<!-- Provide details on when usage of this recipe is recommended. -->
This recipe is recommended if the following conditions are true:

- Customer is fine to use Microsoft Managed-VNet workspace
- Customer understands the division of responsibility with this PaaS offering

#### Not Recommended

<!-- Provide details on when usage of this recipe is NOT recommended. -->
This recipe is **not** recommended if the following conditions are true:

- Azure Machine Learning workspace is required to be accessible from the public Internet
- Customer wants to use their own BYO virtual network for the ML workspace 

## Getting Started

<!-- Provide instructions on how a user would use this recipe (e.g., how they would deploy the resources). -->

### Pre-requisites

<!-- List the pre-reqs for use of this recipe (SDKs, roles/permissions, etc.) -->
The following pre-requisites should be in place in order to successfully use this recipe:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [.NET Core 7.0](https://docs.microsoft.com/dotnet/core/install/)
- [Terraform](https://www.terraform.io/downloads.html) (Only if using Terraform)
- [Azure PowerShell](https://docs.microsoft.com/powershell/azure/install-az-ps) (Only if using Azure PowerShell to deploy via Azure Bicep)

### Deployment

To deploy this recipe, perform the infrastructure deployment steps using Terraform. Unix/Linux shell script is also provided with az cli commands to peform the quick set-up in PoC enviroments.

<!-- Provide instructions on how to deploy the recipe. -->

### Remote Access

The recipe does not provision a Virutal Machine (VM) or Azure Bastion to provide remote access within the virtual network.  If a VM or Bastion is needed, modify the virtual network topology to add the necessary subnets (for example, add subnets "snet-vm" for the VM and "AzureBastionSubnet" for Azure Bastion in the bridge virtual network).

It also excludes the configuration steps required to peer the bridge network to the customer on-prem network.

#### Virtual Network

The recipe provides for the ability to provision managed virtual network workspace. managed-vnet workspace will be known as 'spoke' and the other virtual network connecting to it will be the 'bridge' virtual network as it will allow the secure connectivity to the workspace resources for the data scientists, ML SME's, Azure Pipelines and Github actions. In the Bridge/spoke model, the recipe assumes Azure Private DNS zones reside in another resource group.  The recipe includes parameters/variables to control how Azure Private DNS Zones are used - either use existing Private DNS Zones, or create new Private DNS Zones.

#### Deploying Infrastructure Using Terraform

<!-- TODO: Update to use Azure CLI. -->

> Azure PowerShell is shown below due to a [likely bug in Azure CLI 2.27.0 and 2.27.1](https://github.com/Azure/azure-cli/issues/19308) which prevents execution of the provided Azure Bicep modules using the Azure CLI.
0. az login


### Bash
```
az login --use-device-code
az account set --subscription SUBSCRIPTION_ID
```

### Bash
   ```Bash
   az group create --location <LOCATION> --name <RESOURCE_GROUP_NAME>
   ```
1. Deploy the template, passing in the name of the resource group created earlier and the necessary parameters for the Bicep template.

### Bash
 ```Bash
   mkdir src
 ```
### Bash
 ```Bash
   cd src
   mkdir aml_managed_vnet
   cd aml_managed_vnet
   cp *.tf .
 ```
Note: For this step, the terraform scripts supplied by us has to be copied to the bash terminal at the user defined location. Subsequently, those scripts are required to be copied to the /src/aml_managed_vnet location in the same bash terminal.

### Bash
 ```Bash
   pwd
   terraform init
   terraform plan 
   terraform apply 
 ```
### Testing Solution

    - To verify the solution is working as intended, the data scientist 

## Change Log

<!--
Describe the change history for this recipe. For example:
- 2021-06-01
  - Fix for bug in Terraform template that prevented Key Vault reference resolution for function app.
-->
- 2024-01-11 - Created feature branch and check-in code in i 
- 

## Next Steps

<!-- Provide description and links to what a user of this recipe could do next.  Include suggestions for how the recipe could be enhanced or built upon. -->
