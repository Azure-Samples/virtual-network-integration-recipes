# Protect MLOps Solutions using Azure Network Security Capabilities

# Types of VNET

- Azure Managed VNET
- Customer VNET

# Typical Functional Components in MLOps Solution
- Data storage: Azure Blob Storage
- Model training, validation and registration: Azure Machine Learning
- Model deployment: Azure Machine Learning endpoints and Azure Kubernetes Service
- Model monitor: Azure Monitor for Application Insights
- MLOps pipelines: Azure DevOps and Azure Pipelines 

# Azure Services used to help protect MLOps Solution
- Azure Key Vault for managing secrets/keys used in the solution 
- Azure Policy for meeting regulatory and compliance requirements
- Microsoft Entra for Authentication and Authorization 
- Virtual Network for network security

# Benefits of Managed VNET
- Easy to configure
- Automatically secures your workspace and managed compute resources
- Outbound traffic required by the Azure ML service us automatically enabled
- Can be implemented in two patterns: allow internet outbound mode or allow only approved outbound mode (recommended)

# Securing VNET along with data exfiltration prevention and data protection
- Use Azure virtual network for network isolation
- Put all the resources in the same region
- Have Hub VNET that contains the firewall. Use FQDNs in firewall in addition to service tags to prevent data exfiltation.
- Firewall in Hub VNET will control the internet outbound from your virtual networks.
- A spoke VNET to contain the following resources
  - Training subnet that contains compute instance and compute clusters used for training the models
    - Configure service endpoint with service endpoint policy to prevent data exfiltration
  - Configure the resources in the training subnet with no public ip.
  - Scoring subnet containing AKS cluster
  - Private end point subnet that will contain the private endpoints used to connect to the workspace and its workspace components. Private endpoint will use private ip from the VNET pool of private ip addresses.
  - Compute resources should be able to reach the firewall in hub VNET.
  - Managed online endpoint that will use private endpoint of the workspace to process the incoming requests.
  - Private endpoint to allow managed online endpoint deployments to access private storage.
  - **Allow inbound from Azure ML service tag using NSG ans UDR to skip firewall when using compute instance or cluster with public ip.
  - Enable "Allow trusted Microsoft services to bypass this firewall" for Azure Key Vault.
  - Enable "Grant access to trusted Azure services" for Azure Storage account.
  - Enable "Allow trusted services" for Azure container registry.

    ## Limitations
    Workspace and default storage account must be in the same VNET
    AKV and ACR for the workspace to be in the same VNET, or in a peered VNET
    Azure Compute instance and compute clusters must be in the same VNET, region anf subscription as the workspace and its associated resources

  # List of Required Rules
  These rules are automatically created with the managed VNET regardless of public network access mode for those resources
  - Types of outbound: read only and read/write
    - read only outbound cannot be explited by the malicious actors but read/write outbound can be.
    - **Azure Storage and Azure Frontdoor are read/write outbound.** Hence to minimise the data exfiltration risk use a service endpoint policy with and Azure ML alias to allow outbound to only Azure ML managed storage accounts. There is no need to open outbound to storage on the firewall.
  - Azure Service Tags required to allow outbound from compute instance and cluster to access Azure ML managed storage accounts to get scripts etc.
     - Outbound service tag: AzureActiveDirectory    Protocol:TCP  Port:80, 443
     - Outbound service tag: AzureResourceManager    Protocol:TCP  Port:443
     - Outbound service tag:AzureMachineLearning     Protocol:UDP  Port:5831
     - Outbound service tag:BatchNodeManagement     Protocol:TCP  Port:443
     - Outbound service tag: AzureFrontDoor    Protocol:  Port:
     - Outbound service tag: MicrosoftContainerRegistry Protocol: Port:
     - Outbound service tag:AzureMonitor  Protocol: Port:
     - Inbound: AzureMachineLearning
       
  - Outbound FQDNs required to allow outbound from compute instance and cluster to access Azure ML managed storage accounts to get scripts etc.
    - mcr.microsoft.com  Protocol:TCP Port:443
    - *.data.mcr.microsoft.com  Protocol:TCP Port:443
    - ml.azure.com   Protocol:TCP  Port:443
    - automlresources-prod.azureedge.net  Protocol:TCP Port:443
   
     ![Defaultoutboundrules](images/managedvnet_automaticrules.png)


## Public vs Private ML workspace
Public workspace can show data in your private storage account, so we recommend using private workspace.
Use Microsoft Entra authentication and authorization with conditional access if you want to access workspace publicly.



## Managed online endpoint security - outbound and inbound
Enable network isolation for the managed online endpoints to secure the following network traffic:
- Inbound scoring requests
- Outbound communication with the workspace, ACR and Azure Blob storage

## Private IP requirements
- One IP per compute instance, compute cluster node, and private endpoint
- IP's for AKS

##  Challenges due to shortage of Private IPs
Private IP address shortage in your main network. The hub-spoke network connected with your on-prem network might not have large enough private IP address space. In this case, use isolated, not peered VNets for Azure ML resources.



## Built-in-policies (Azure Policy)



## Image build compute for ACR behind VNET

## Enable ML Studio UI with private link enabled workspace along with data exfiltration prevention

## Enabling Defender for Cloud

## Assigning Azure Policies for compliance
Policy | Description| 
--- | --- | 
Customer-managed key |Audit or enforce whether workspaces must use a customer-managed key. |
Private link | Audit or enforce whether workspaces use a private endpoint to communicate with a virtual network. |
Private endpoint | Configure the Azure Virtual Network subnet where the private endpoint should be created. |
Private DNS zone | Configure the private DNS zone to use for the private link. |
User-assigned managed identity | Audit or enforce whether workspaces use a user-assigned managed identity. |
Disable public network access | Audit or enforce whether workspaces disable access from the public internet. |
Disable local authentication | Audit or enforce whether Azure Machine Learning compute resources should have local authentication methods disabled. |
Modify/disable local authentication | Configure compute resources to disable local authentication methods. |
Compute cluster and instance is behind virtual network | Audit whether compute resources are behind a virtual network.|


