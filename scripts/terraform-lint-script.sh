#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

#TF_LINT_VERSION is set from argument passed to this script
# e.g. ./terraform-lint-script.sh 0.28.1

echo ""
echo -e "\n\n>>> Install tflint (3rd party)"
wget -q https://github.com/terraform-linters/tflint/releases/download/v"$1"/tflint_linux_amd64.zip -O /tmp/tflint.zip
sudo unzip -q -o -d /usr/local/bin/ /tmp/tflint.zip

echo -e "\n\n>>> Terraform version"
terraform -version

echo -e "\n\n>>> TFLint version"
tflint --version

echo -e "\n\n>>> Terraform init"
terraform init

echo -e "\n\n>>> tflint --init"
tflint --init

echo -e "\n\n>>> tflint"
tflint

echo -e "\n\n>>> Terraform validate"
terraform validate
