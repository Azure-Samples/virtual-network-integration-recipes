#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

if [ $# -ne 4 ]
then
    echo "Usage: $0 <resource_group_name> <databricks_workspace_name> <storage_account_name> <keyvault_name>"
    exit 1
fi

# To allow installation of "databricks" extension without prompting
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

resourceGroupName=$1
adbWorkspaceName=$2
storageAccountName=$3
keyvaultName=$4

scopeName="storage-scope"
secretName="StorageAccountKey"

echo "Retrieving keys from storage account."
storageAccountKey=$(az storage account keys list --resource-group "${resourceGroupName}" --account-name "${storageAccountName}" --output json --only-show-errors | jq -r .[0].value)

echo "Retrieving logged in user details (user/service principal)."
loginUserId=""
loginUserType=$(az account show --output json --only-show-errors | jq -r '.user.type')
echo "   Logged in as '${loginUserType}'."

case "${loginUserType}" in
    "servicePrincipal")
        spId=$(az account show --output json --only-show-errors | jq -r '.user.name')
        loginUserId=$(az ad sp show --id "${spId}" --output json --only-show-errors | jq -r '.objectId')
        ;;
    "user")
        loginUserId=$(az ad signed-in-user show --output json --only-show-errors | jq -r '.objectId')
        ;;
    *)
        echo >&2 "Unhandled login type specified." 
        exit 1
        ;;
esac

echo "   Login User Id: ${loginUserId}."

# Granting all privileges on keyvault secrets to the deployer.
echo "Granting all privileges on keyvault secret to the deployer."
az keyvault set-policy \
    --name "${keyvaultName}" \
    --object-id "${loginUserId}" \
    --secret-permissions backup delete get list purge recover restore set \
    --output none \
    --only-show-errors

# Adding 10 seconds wait to make sure that the Key Vault access granted above is in place.
sleep 10

echo "Storing keys in Azure Key Vault."
az keyvault secret set \
    --name "StorageAccountKey" \
    --vault-name "${keyvaultName}" \
    --value "${storageAccountKey}" \
    --output none \
    --only-show-errors

echo "   Stored secret 'StorageAccountKey'."
echo "Creating Azure Key Vault-based secret scope."

# Create ADB secret scope backed by Azure Key Vault
# Currently, there is a limitation that Azure Key Vault-backed secret scope can't be created while logged in as a
#  Service Principal (e.g.: AzDo CI/CD Pipelines). The following error message is thrown:
#   {"error_code":"CUSTOMER_UNAUTHORIZED","message":"Unable to grant read/list permission to Databricks service principal
#    to KeyVault 'https://<keyvault-name>.vault.azure.net/': key not found: https://graph.windows.net/"}
# To avoid this, the secret scope is created only if logged in as a User. In case of SP, this step is skipped.
if [ "${loginUserType}" = "user" ]
then
    # "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" is a constant, unique applicationId that identifies Azure Databricks workspace resource inside Azure
    adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json --only-show-errors | jq -r .accessToken)
    echo "Got adbGlobalToken=\"${adbGlobalToken:0:20}...${adbGlobalToken:(-20)}\""
    azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json --only-show-errors | jq -r .accessToken)
    echo "Got azureApiToken=\"${azureApiToken:0:20}...${azureApiToken:(-20)}\""

    keyvaultId=$(az keyvault show --name "${keyvaultName}" --resource-group "${resourceGroupName}" --output json --only-show-errors | jq -r .id)
    keyvaultUri=$(az keyvault show --name "${keyvaultName}" --resource-group "${resourceGroupName}" --output json --only-show-errors | jq -r .properties.vaultUri)

    adbId=$(az databricks workspace show --resource-group "${resourceGroupName}" --name "${adbWorkspaceName}" --output json --only-show-errors | jq -r .id)
    adbWorkspaceUrl=$(az databricks workspace show --resource-group "${resourceGroupName}" --name "${adbWorkspaceName}" --output json --only-show-errors | jq -r .workspaceUrl)

    authHeader="Authorization: Bearer ${adbGlobalToken}"
    adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:${azureApiToken}"
    adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:${adbId}"

    createSecretScopePayload="{
        \"scope\": \"${scopeName}\",
        \"scope_backend_type\": \"AZURE_KEYVAULT\",
        \"backend_azure_keyvault\":
        {
            \"resource_id\": \"${keyvaultId}\",
            \"dns_name\": \"${keyvaultUri}\"
        },
        \"initial_manage_principal\": \"users\"
    }"

    echo "${createSecretScopePayload}" | curl -sS -X POST -H "${authHeader}" -H "${adbSPMgmtToken}" -H "${adbResourceId}" \
        --data-binary "@-" "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/create"

    echo "   Secret scope '${scopeName}' created successfully."
else
    echo "   As it's a SP login, skipping the creation of Azure Key Vault-backed secret scope. Please create it manually from Azure Portal."
fi

echo "==================== Summary ========================"
echo "Storage Account Name : ${storageAccountName}"
echo "AKV Name             : ${keyvaultName}"
echo "AKV Secret Name      : ${secretName}"
echo "ADB Workspace Name   : ${adbWorkspaceName}"
echo "ADB Secret Scope Name: ${scopeName} (if created)"
echo "====================================================="
