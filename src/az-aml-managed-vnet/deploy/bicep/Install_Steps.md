# Here are the steps to create managed virtual network ml workspace
### Create resource group "rg_poc"
    az group create -l westus -n rg_poc 
### create managed-vnet workspace "mlws_poc" in the resource group "rg_poc" 
    az ml workspace create --name mlws_poc --resource-group rg_poc --managed-network allow_only_approved_outbound
    Options
    --enable-data-isolation -e

    ### output 
    Creating Key Vault: (mlwspockeyvault87fdea5cb  ) ..  Done (23s)
    Creating Log Analytics Workspace: (mlwspoclogalytia77f654d3  )  Done (22s)
    Creating Storage Account: (mlwspocstoraged4813c4856  )  Done (27s)
    Creating Application Insights: (mlwspocinsights7eb6d67ca  )  Done (32s)
    Creating AzureML Workspace: (mlws_poc  ) ..  Done (22s)
    Total time : 57s

### Create user defined outbound rules if required
       az ml workspace create --file workspace.yaml --resource-group rg --name ws
### Disable public access for the workspace
    az ml workspace update --name mlws_poc --resource-group rg_poc --public-network-access disabled
### Disable public network access for the Azure keyvault from the Azure Portal as the subscription of the managed-vnet is not known to execute the commands 
### Enable trusted microsoft services to bypass the firewall for azure keyvault
   Check "Allow trusted Microsoft services to bypass this firewall" from the Azure portal      
### Enable purge protection for the key vault from the portal
### Disable public access for the storage account and select the preferred network routing as 'Microsoft' for the traffic
### Provision the network 
      az ml workspace provision-network -g rg_poc -n mlws_poc
### Create compute resource for the image build
      az ml workspace update --name mlws_poc --resource-group rg_poc --image-build-compute mlws_poc_comput
# Here are the steps to create hub virtual network with private endpoint to managed-vnet workspace 
    
### Create hub vnet
### Create vm in hub vnet
### Create bastion in hub vnet
### Create inbound pe for workspace  in the hub vnet

  # Create RBAC
# Technical Validations
     1. View workspace
       az --list-defaults/-l --output/ -o table
       az-ml-workspace-show
     3. Show details of a managed network outbound rules
        az ml workspace outbound-rule list --workspace-name mlws_poc --resource-group rg_poc
        az-ml-workspace-outbound-rule-show  
        
# Functional Validations   
Create a VM in the Hub VNet, and connect it via Bastion into this VM to access the AML studio portal. Then create a new compute instance, it should succeed.
      
