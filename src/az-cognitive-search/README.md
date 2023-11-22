# Azure Databricks Deployment in Secured Networking Environment

## Scenario

## Problem Summary

## Architecture

## Recommendations

The following sections provide recommendations on when this recipe should, and should not, be used.

### Recommended

### Not Recommended

## Getting Started

### Pre-requisites

The following pre-requisites should be in place in order to successfully use this recipe:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure CLI extension: Databricks](https://docs.microsoft.com/cli/azure/databricks?view=azure-cli-latest)
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html#install-the-cli)
- [jq](https://formulae.brew.sh/formula/jq)
- [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install) (Only if using Azure Bicep)
- [Azure PowerShell](https://docs.microsoft.com/powershell/azure/install-az-ps) (Only if using Azure PowerShell to deploy via Azure Bicep)

### Deployment

### Deployment Options

There are several options which can be made while deploying this recipe. Based on these choices, 

#### Option regarding Private DNS Zones used by Transit VNet

This option allows user to either use existing Private DNS Zones or create new ones in the same resource group in which the recipe is being deployed. Please note that this choice is applicable only to the Private DNS Zones which are used by transit VNet. For the Private DNS Zones used by Databricks VNet, the recipe always creates the required private DNS Zones in a different resource group.

Here are the details of the relevant parameters:

```txt
newOrExistingDnsZones: Parameter to specify if new private DNS Zones are to be created or to use existing ones.
  1. new - Create new Private DNS Zones as part of recipe deployment.
  2. existing - Use existing Private DNS Zones instead of creating new ones.
```

When using the "existing" value for the above parameter, please set the following additional parameter:

```txt
dnsZoneResourceGroupName: 
dnsZoneSubscriptionId
```

The assumption here is that all the required Private DNS Zones are already existing within the same resource group "dnsZoneResourceGroupName". The "dnsZoneSubscriptionId" supports cross-subscription deployment i.e. the existing Private DNS Zones can be in a different subscription than the one in which the recipe is being deployed.

### Deploying Infrastructure Using Bicep

- Open the command prompt and change directory to the `bicep` folder.

```bash
cd <WORKSPACE_LOCATION>/src/az-databricks/deploy/bicep
```

- Login to Azure CLI and set the subscription you want to use.

```bash
az login

az account set -s <subscription_id>
```

- Please note that this recipe is deployed with a target scope of "subscription". The [main.bicep](./deploy/bicep/main.bicep), which is the main file for the Bicep deployment, already has the default values for the required parameters. Please carefully review these values and make sure it doesn't clash with your existing infrastructure (For ex: the VNet address ranges). If you prefer to override these, you can rename the [azuredeploy.parameters.sample.json](./deploy/bicep/azuredeploy.parameters.sample.json) file to **azuredeploy.parameters.json** and modify/add the required parameter values.

Please carefully read the [Deployment Options](#deployment-options) and set the variables accordingly before moving to the next step.

- Optionally, verify what Bicep will deploy, passing in the location where you want to deploy the recipe, deployment name ("adbVnetRecipeDeploy") and the necessary parameters for the Bicep template.

```bash
az deployment sub what-if --name adbVnetRecipeDeploy --location <LOCATION> --template-file main.bicep --parameters azuredeploy.parameters.json --verbose
```

- Deploy the template, passing in the location where you want to deploy the recipe, deployment name ("adbVnetRecipeDeploy") and the necessary parameters for the Bicep template.

```bash
az deployment sub create --name adbVnetRecipeDeploy --location <LOCATION> --template-file main.bicep --parameters azuredeploy.parameters.json --verbose
```

### Test the Recipe

## Specific Observations and Comments
