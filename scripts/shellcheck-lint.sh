#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# This file is for use in the Azure DevOps pipeline (.azdo\pipelines\ci\shell-script-lint.yml).

echo "This checks for formatting and common bash errors. See wiki for error details and ignore options: https://github.com/koalaman/shellcheck/wiki/SC1000"

wget -qO- "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz" | tar -xJv
sudo mv "shellcheck-stable/shellcheck" /usr/bin/
rm -r "shellcheck-stable"
shellcheck ./scripts/*.sh