# Contributing to Virtual Network Integration Recipes

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

- [Code of Conduct](#code-of-conduct)
- [Issues and Bugs](#found-an-issue)
- [Feature Requests](#want-a-feature)
- [Submission Guidelines](#submission-guidelines)

## Code of Conduct

Help us keep this project open and inclusive. Please read and follow our [Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

## Found an Issue?

If you find a bug in the source code or a mistake in the documentation, you can help us by
[submitting an issue](#submitting-an-issue) to the GitHub Repository. Even better, you can
[submit a Pull Request](#submitting-a-pull-request) with a fix.

## Want a Feature?

You can *request* a new feature by [submitting an issue](#submitting-an-issue) to the GitHub
Repository. If you would like to *implement* a new feature, please submit an issue with
a proposal for your work first, to be sure that we can use it.

- **Small Features** can be crafted and directly [submitted as a Pull Request](#submitting-a-pull-request).

## Azure Resource Naming Convention

The Azure resource group should adhere to the following naming pattern: **rg-{workload/recipe}-{optional-info}**.

Azure resources within the resource group should should adhere to the following naming pattern: **{resource-type}-{unique-value}-{optional-info}**.

Each segment is defined as follows:

- **resource-type**: should be one of the resource abbreviations specified in the [Microsoft Cloud Adoption Framework (CAF) resource abbreviations](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) list.
- **workload/app**: should specify a lowercase short name for the recipe, using "rcp" as an abbreviation for recipe. For example:
  - funcevhrcp
  - funchttprcp
  - webapimrcp
- **unique-value**: should be a unique value scoped to the parent resource group.  The value should be no more than 13 characters in length.
- **optional info**: should include optional information which may useful in identifying the resource's purpose. For example:
  - 001 (index when there are multilpe resource types of the same general name)
  - bastion (to help indicate the resource is related to Azure Bastion)
  - tf (to indicate a Terraform-based deployment)
  - bcp (to indicate a Bicep-based deployment)

## Code Analysis / Formatting

### Linting

Various linting tools & processes are in place to help ensure consistency of documentation and source code.

### Markdown

If you use VS Code as your preferred editor, please install the [markdownlint extension](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint) and ensure that all rules are followed. This will help ensure consistency in the look and feel of the documentation in this repo.

Additionally, you can run the markdown linting from the command line:

```bash
npm install
npm run lint
```

If there is a linting error, you'll notice output similar to the following:

```bash
> markdownlint "**/*.md" --ignore node_modules

> markdownlint "**/*.md" --ignore node_modules

CHANGELOG.md:3:1 MD033/no-inline-html Inline HTML [Element: a]
npm ERR! code ELIFECYCLE
npm ERR! errno 1
npm ERR! @ lint: `markdownlint "**/*.md" --ignore node_modules`
npm ERR! Exit status 1
npm ERR! 
npm ERR! Failed at the @ lint script.
npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

npm ERR! A complete log of this run can be found in:
npm ERR!     /home/vscode/.npm/_logs/2022-10-04T19_44_18_330Z-debug.log
```

Resolve the error(s) and run the linter again to ensure a clean output.

#### Markdown Link Checks

The [markdown-link-check](https://github.com/tcort/markdown-link-check) package can be used to validate the links in Markdown files. The following command can be used:

```bash
find . -name \*.md ! -path "./node_modules/*"  -exec markdown-link-check --verbose --config link-check-config.json {} \;
```

The above command will find all Markdown (.md) files that are not in the `node_modules` folder, passing each file to the `markdown-link-check` package. The `link-check-config.json` file is used to set [configuration values](https://github.com/tcort/markdown-link-check#config-file-format) for checking the links.

### Shell Scripts

Bash shell scripts should adhere to linting rules defined in [shellcheck](https://github.com/koalaman/shellcheck).

Bash shell scripts are expected to follow [Google's Bash Style Guide](https://google.github.io/styleguide/shell.xml).

Developers can use the [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) extension in VS Code to get a local linting experience.
The extension requires [shellcheck](https://github.com/koalaman/shellcheck) to be installed.
There are [many options to install shellcheck](https://github.com/koalaman/shellcheck#installing); choose the option best for your local development environment.

For more information, please refer to the [CSE Code with Engineering playbook](https://microsoft.github.io/code-with-engineering-playbook/) recipe for [Bash Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/bash/).

Running `shellcheck` against an invalid .sh file will show an error where the lint check failed.

```bash
shellcheck test.sh

In test.sh line 1:

^-- SC2148: Tips depend on target shell and yours is unknown. Add a shebang or a 'shell' directive.

For more information:
  https://www.shellcheck.net/wiki/SC2148 -- Tips depend on target shell and y...
```

### Azure Bicep

It is possible to run a linting process against Azure Bicep files as of Azure Bicep v0.4. The liniting process is automatic in the execution of the `az bicep build` command.

Additionally, the [Azure Bicep extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep&ssr=false#overview) will perform real-time linting when editing .bicep files.

Azure Bicep linting rules are configured via the `bicepconfig.json` file.

To learn more about Azure Bicep linting, please refer to documentation on [using the Bicep linter](https://docs.microsoft.com/azure/azure-resource-manager/bicep/linter).

### Terraform

Terraform scripts should adhere to linting rules defined by [TFLint](https://github.com/terraform-linters/tflint). Rules for the Terraform language are built into the TFLint binary, so you don't need to install any plugins for enforcing best practices, naming conventions, warn about deprecated syntax, unused declarations, etc. The terraform version is currently set to be 0.15.4 and the TFLint version is set to be 0.28.1 in the terraform linting Azure DevOPs pipeline.

Follow the link here to [install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

Running tflint locally will require you to [install TFLint](https://github.com/terraform-linters/tflint/blob/master/README.md#installation); using the option best for your local development environment and then running the below commands:

```bash
# Rewrite Terraform configuration files to a canonical format and style.
# If this fails use 'terraform fmt -recursive' command to resolve
terraform fmt -recursive -diff -check

# Apply linting rules
tflint

# Initialize working directory containing Terraform configuration files
terraform init

# Validate the configuration files in the directory
terraform validate
```

The details for the [`terraform fmt`](https://www.terraform.io/docs/cli/commands/fmt.html), [`terraform init`](https://www.terraform.io/docs/cli/commands/init.html) and [`terraform validate`](https://www.terraform.io/docs/cli/commands/validate.html) commands can be found in the respective links.

Developers can use the [Hashicorp Terraform Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=hashicorp.terraform) extension in VS Code to get a local linting experience.
The [VSCode Azure Terraform](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureterraform) extension in VS Code provides terraform command support for Azure.

For more information, please refer to the [CSE Code with Engineering playbook](https://microsoft.github.io/code-with-engineering-playbook/) recipe for [Terraform Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/terraform/).

Running `tflint` against an invalid .tf file will show an error where the lint check failed.

```bash
tflint

modules/resource-group/main.tf
--- old/modules/resource-group/main.tf
+++ new/modules/resource-group/main.tf
@@ -1,4 +1,4 @@
 resource "azurerm_resource_group" "example" {
-  name   = "example"
+  name     = "example"
   location = "West US"
 }
\ No newline at end of file
```

## Folder Structure

Code-related assets (application source code, scripts, infrastructure-as-code, related README files, etc.) should be placed within the following folder hierarchy.

```text
\.azuredevops (Azure DevOps pull request template(s) and YAML pipelines)
    \pipelines
        \templates
        \variables
\.devcontainer (Visual Studio Code dev container)
\.vscode
\docs (documentation that applies to the overall project)
\scripts (utility scripts for builds)
\src
    \common
        \app_code
            \app1 (function app, web app, etc.)
                \src (code for the app)
            \app2
                \src
        \infrastructure
            \bicep
                \modules
                    \network
                        main.bicep
                    \storage
                        main.bicep
            \terraform
                \modules
                    \network
                        main.tf
                    \storage
                        main.tf
    \recipe-1
        \.vscode
        \deploy
            \terraform
                \foo (module that isn't applicable to other recipes)
                    foo.tf
                main.tf (reference modules in the \src\common\infrastructure\terraform\modules directory)
            \bicep
                main.bicep (references modules in the \src\common\infrastructure\bicep\modules directory)
            \scripts (.ps1, .sh, etc. scripts to use the recipe)
        \docs (documentation specific to a recipe)
        README.md (initial content describing the recipe)
    \recipe-2
```

## Submission Guidelines

### Submitting an Issue

Before you submit an issue, search the archive, maybe your question was already answered.

If your issue appears to be a bug, and hasn't been reported, open a new issue.
Help us to maximize the effort we can spend fixing issues and adding new
features, by not reporting duplicate issues.  Providing the following information will increase the
chances of your issue being dealt with quickly:

- **Overview of the Issue** - if an error is being thrown a non-minified stack trace helps
- **Version** - what version is affected (e.g. 0.1.2)
- **Motivation for or Use Case** - explain what are you trying to do and why the current behavior is a bug for you
- **Browsers and Operating System** - is this a problem with all browsers?
- **Reproduce the Error** - provide a live example or a unambiguous set of steps
- **Related Issues** - has a similar issue been reported before?
- **Suggest a Fix** - if you can't fix the bug yourself, perhaps you can point to what might be
  causing the problem (line of code or commit)

You can file new issues by providing the above information at the corresponding repository's issues link: <https://github.com/Azure-Samples/virtual-network-integration-recipes/issues/new>.

### Submitting a Pull Request

Before you submit your Pull Request (PR) consider the following guidelines:

- Search the [repository](https://github.com/Azure-Samples/virtual-network-integration-recipes/pulls) for an open or closed PR that relates to your submission. You don't want to duplicate effort.
- Run the GitHub workflows to validate the changes are likely to succeed when deployed to Azure.  Please include a link to the workflow runs in your PR.
  - Authenticate to Azure from the GitHub Actions workflow.  [Setting up OpenID Connect is the preferred approach](https://learn.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-openid-connect).
  - Set the following secrets in your forked repository in order workflows to authenticate with your Azure subscription:
    - AZURE_TENANT_ID
    - AZURE_CLIENT_ID
    - AZURE_SUBSCRIPTION_ID

Make your changes in a new git fork:

- Commit your changes using a descriptive commit message
- Push your fork to GitHub:
  - In GitHub, create a pull request
  - If we suggest changes then:
    - Make the required updates.
    - Rebase your fork and force push to your GitHub repository (this will update your Pull Request):

        ```shell
        git rebase master -i
        git push -f
        ```

That's it! Thank you for your contribution!
