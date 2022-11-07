#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

# Validating input parameters
if [ $# -ne 7 ]
then
    echo "Usage: $0 <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME> <KEY_VAULT_NAME> <SQL_SERVER_NAME> <MPE_STORAGE_ACCOUNT_NAME> <MPE_KEY_VAULT_NAME> <MPE_SQL_SERVER_NAME>"
    exit 1
fi

resource_group_name=$1

# Resource name
storage_name=$2
keyvault_name=$3
sql_server_name=$4

# Managed private endpoint names
mpe_storage_name=$5
mpe_keyvault_name=$6
mpe_sql_server_name=$7

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
        "sqlserver")
            mpe_type="Microsoft.Sql/servers"
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

# Approving managed private endpoints.
echo "Approving managed private endpoints."
approveManagedPrivateEndpoint "${storage_name}" "${mpe_storage_name}" "storage"
approveManagedPrivateEndpoint "${sql_server_name}" "${mpe_sql_server_name}" "sqlserver"
approveManagedPrivateEndpoint "${keyvault_name}" "${mpe_keyvault_name}" "keyvault"
