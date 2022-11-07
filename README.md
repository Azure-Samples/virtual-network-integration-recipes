---
page_type: sample
languages:
- csharp
- javascript
- python
- bicep
- terraform
- bash
products:
- azure-functions
- azure-app-service-web
- azure-event-hubs
- azure-application-gateway
- azure-api-management
- azure-synapse-analytics
- azure-storage
- azure-purview
- azure-data-factory
- azure-virtual-network
name: Virtual Network Integration Recipes
urlFragment: virtual-network-integration-recipes
description: This repository contains multiple sample recipes to help developers create Azure solutions which integrate with, or are isolated within, a virtual network.
---

# Virtual Network Integration Recipes

[![Event Hub Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/event-hub-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/event-hub-recipe-ci.yml)

[![Private Function HTTP Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/private-http-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/private-http-recipe-ci.yml)

[![Web App Private HTTP Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/webapp-private-http-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/webapp-private-http-recipe-ci.yml)

[![API Management and App Gateway Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/apim-appgw-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/apim-appgw-recipe-ci.yml)

[![Azure Data Factory Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/adf-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/adf-recipe-ci.yml)

[![Azure Databricks Recipe CI](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/databricks-recipe-ci.yml/badge.svg?branch=main)](https://github.com/Azure-Samples/virtual-network-integration-recipes/actions/workflows/databricks-recipe-ci.yml)

This repository contains multiple sample recipes to help developers create Azure solutions which integrate with, or are isolated within, a virtual network.

The recipes consist of reusable reference Azure Bicep templates and/or Terraform configuration files, along with sample application code to demonstrate platfrom capabilities. The recipes demonstrate an approach for setting up virtual network integration and isolation, including private/service endpoints for Azure Web Apps, Functions, Synapse, Purview, Databricks, Data Factory, along with Event Hubs, Azure Storage and Key Vault.

## Getting Started

Please view the [Contributing](./CONTRIBUTING.md) guidance for more information on how to contriubte to this repository.

### Prerequisites

- Install [Visual Studio Code](https://code.visualstudio.com/).
- [Docker](https://www.docker.com/products/docker-desktop) (optional - for use with Visual Studio Code dev container)
- .NET Core 3.1
- Python 3.8
- Node 14
- [Azure Functions Core Tools v3](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI 2.40](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Azure Bicep 0.11.1](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- Terraform 1.3.2

### Recipies

Instructions on how to use [each recipe](./docs/Recipes.md) are provided in each recipe's README file.

### Developer Environment

Developers are free to use the environment of their choosing, so long as they're able to install the prerequisites.

When using Visual Studio Code, the developer is able to view a recommended set of extensions to aid in development. The recommended set of extensions is the same set of extensions that are configured for use in the Visual Studio Code dev container configuration.

#### Visual Studio Code Dev Container

A development container definition is provided to make it easier for developers to get started quickly contributing to the project, as well as using the assets of the project.

The dev container included with this project includes the following configuration:

- Docker image
  - Azure Functions Python 3.8 Core Tools base image ([Dockerfile](https://github.com/Azure/azure-functions-docker/blob/dev/host/3.0/buster/amd64/python/python38/python38-core-tools.Dockerfile))
  - [Bash git prompt](https://github.com/magicmonty/bash-git-prompt)
  - Terraform v1.3.2
  - TFLint v0.41.0
  - Azure CLI
  - Azure Bicep
  - Azure Functions Core Tools 3
- Software development languages
  - .NET Core 3.1 SDK
  - Python 3.8
  - Node 14
- Visual Studio code extensions:
  - [Azure Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)
  - [Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)
  - [Azure Terraform](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureterraform)
  - [Azure Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
  - [C#](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp)
  - [HashiCorp Terraform](https://marketplace.visualstudio.com/items?itemName=hashicorp.terraform)
  - [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio)
  - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
  - [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
  - [markdownlint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint)
  - [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
  - [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)
  - [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)

The dev container is configured to run as a non-root user, `vscode`.

Learn more about Visual Studio Code dev containers [here](https://code.visualstudio.com/docs/containers/overview).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft’s Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.
