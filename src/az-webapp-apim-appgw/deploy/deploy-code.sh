#!/bin/bash

SUBSCRIPTION_ID=$1
RESOURCE_GROUP_NAME=$2
WEB_APP_NAME=$3
LOCATION=$4
STORAGE_ACCOUNT_NAME=$5

if [[ -z $SUBSCRIPTION_ID ]] || [[ -z $RESOURCE_GROUP_NAME ]] || [[ -z $WEB_APP_NAME ]] || [[ -z $LOCATION ]] || [[ -z $STORAGE_ACCOUNT_NAME ]]
then  
    echo "Parameters missing."
    echo "Usage: deploy-code.sh subscription_id resource_group_name web_app_name location storage_account_name"
    echo "Try: deploy-code.sh XXX-XXX-XXX myRG myWebApp eastus myStorageAccount"
    exit
fi

# Create storage account
az storage account create --location "$LOCATION" --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --allow-blob-public-access false --https-only true --kind Storage --sku Standard_GRS

# Create a container
az storage container create --name app-code --account-name "$STORAGE_ACCOUNT_NAME"

# Assign web app identity to storage account
WEB_APP_ID=$(az webapp identity show --resource-group "$RESOURCE_GROUP_NAME" --name "$WEB_APP_NAME" --query principalId -o tsv)

export MSYS_NO_PATHCONV=1
az role assignment create \
    --role "Storage Blob Data Reader" \
    --assignee "$WEB_APP_ID" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"

# Sleep for a few seconds to let AAD permissions update.
echo "Sleeping for 30 seconds . . . "
sleep 30
echo "Awake . . . resuming."

# Build code
cd ../../common/app_code/WeatherForecastAPI/ || exit

dotnet publish --configuration Release

# zip code
cd ./bin/Release/netcoreapp3.1/publish || exit
zip -r code.zip .

# Copy the zipped file to the WeatherForecastAPI folder.
cp code.zip ../../../../code.zip

# Change directory back to the WeatherForecastAPI folder.
cd ../../../.. || exit

# Upload zipped code to storage account
az storage blob upload --account-name "$STORAGE_ACCOUNT_NAME" --container app-code --file ./code.zip --name code.zip --auth-mode key

# Get URI for uploaded blob -
BLOB_PACKAGE_URI="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/app-code/code.zip"

cd ../../../az-webapp-apim-appgw/deploy || exit

az webapp config appsettings set --resource-group "$RESOURCE_GROUP_NAME" --name "$WEB_APP_NAME" --settings WEBSITE_RUN_FROM_PACKAGE="$BLOB_PACKAGE_URI"

# May only need to restart if a new package was uploaded.
az webapp restart --resource-group "$RESOURCE_GROUP_NAME" --name "$WEB_APP_NAME"