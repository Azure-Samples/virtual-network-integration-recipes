#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

az bicep install

sudo chown -R "$(whoami)" ~/ 

dotnet restore ./src/common/app_code/eventhub-trigger

echo "alias tf=terraform" >> "/home/$(whoami)/.bashrc"
echo "alias powershell=pwsh" >> "/home/$(whoami)/.bashrc"

pwsh -Command Set-PSRepository -Name PSGallery -InstallationPolicy Trusted && \
    pwsh -Command Install-Module -Name Az -Scope CurrentUser -Repository PSGallery && \
    pwsh -Command Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted