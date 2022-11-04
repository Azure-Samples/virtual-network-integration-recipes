#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

# Validating input parameters
if [ $# -ne 5 ]
then
    echo "Usage: $0 <rg_name> <syn_workspace_name> <syn_storage_acc_name> <main_storage_acc_name> <keyvault_name>"
    exit 1
fi

resource_group_name=$1
synapse_workspace_name=$2
synapse_storage_account_name=$3
main_storage_account_name=$4
keyvault_name=$5

# Managed Private Endpoints name
mpe_synapse_storage_name="mpe_synapse_storage_001"
mpe_main_storage_name="mpe_main_storage_001"
mpe_keyvault_name="mpe_keyvault_001"

# Setting some variables to be able to create managed private endpoints
synapse_storage_account_id=$(az storage account show --resource-group "${resource_group_name}" --name "${synapse_storage_account_name}" --output json | jq -r '.id')
main_storage_account_id=$(az storage account show --resource-group "${resource_group_name}" --name "${main_storage_account_name}" --output json | jq -r '.id')
keyvault_id=$(az keyvault show --resource-group "${resource_group_name}" --name "${keyvault_name}" --output json | jq -r '.id')

# Procedure to create managed private endpoint
createManagedPrivateEndpoint () {
    resource_id=$1
    mpe_name=$2
    echo "   Creating managed private endpoint '${mpe_name}' of type '$3'."
    case $3 in
        "storage")
            group_id="dfs"
            ;;
        "keyvault")
            group_id="vault"
            ;;
        *)
            echo >&2 "Invalid endpoint type specified." 
            exit 1
            ;;
    esac

    access_token=$(az account get-access-token --resource https://dev.azuresynapse.net --output json | jq -r .accessToken)
    endpoint="https://${synapse_workspace_name}.dev.azuresynapse.net/managedVirtualNetworks/default/managedPrivateEndpoints/${mpe_name}?api-version=2020-12-01"

# curl - To aid debugging in case of failure, remove --fail flag to show detailed output.
    curl --request PUT \
        --url "${endpoint}" \
        --header "Authorization: Bearer ${access_token}" \
        --header "content-type: application/json" \
        --data "{\"properties\": { \"privateLinkResourceId\": \"${resource_id}\", \"groupId\": \"${group_id}\"}}" \
        --fail --silent --show-error | jq .
}

# Procedure to approve managed private endpoint
approveManagedPrivateEndpoint () {
    resource_name=$1
    mpe_name=$2
    case $3 in
        "storage")
            mpe_type="Microsoft.Storage/storageAccounts"
            ;;
        "keyvault")
            mpe_type="Microsoft.KeyVault/vaults"
            ;;
        *)
            echo >&2 "Invalid endpoint type specified." 
            exit 1
            ;;
    esac

    echo "   Approving managed private endpoint '${mpe_name}' of type '$3'."
    private_endpoint_connection_id=$(az network private-endpoint-connection list \
        -g "${resource_group_name}" \
        -n "${resource_name}" \
        --type "${mpe_type}" \
        --query "[?contains(properties.privateEndpoint.id,'${mpe_name}') && properties.privateLinkServiceConnectionState.status == 'Pending'].id" \
        --only-show-errors \
        -o tsv)

    if [ -z "${private_endpoint_connection_id}" ]
    then
        echo "   Endpoint already approved."
    else
        az network private-endpoint-connection approve \
            --id "${private_endpoint_connection_id}" \
            --description "Approved" \
            --output none
    fi
}

# Creating managed private endpoints.
echo "Creating managed private endpoints."
createManagedPrivateEndpoint "${synapse_storage_account_id}" "${mpe_synapse_storage_name}" "storage"
createManagedPrivateEndpoint "${main_storage_account_id}" "${mpe_main_storage_name}" "storage"
createManagedPrivateEndpoint "${keyvault_id}" "${mpe_keyvault_name}" "keyvault"

# Giving it some time for MPEs to get created
sleep 60

# Approving managed private endpoints.
echo "Approving managed private endpoints."
approveManagedPrivateEndpoint "${synapse_storage_account_name}" "${mpe_synapse_storage_name}" "storage"
approveManagedPrivateEndpoint "${main_storage_account_name}" "${mpe_main_storage_name}" "storage"
approveManagedPrivateEndpoint "${keyvault_name}" "${mpe_keyvault_name}" "keyvault"
