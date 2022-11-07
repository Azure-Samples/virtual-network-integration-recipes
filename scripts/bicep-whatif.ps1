# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $resourceGroup,
    [Parameter()]
    [string]
    $templateFile,
    [Parameter()]
    [string]
    $templateParams
)

# Declare a hashtable to use for template parameters.
$templateParamsHash = @{}

# Split on whitespace.
$splitResult = $templateParams.Split();

# Split each parameter pair on the equals sign ("=").
foreach ($item in $splitResult) {
    $param = $item.Split("=");

    # Build up the hashtable to use for template parameters.
    <# Need to ensure that Boolean values are added to the hashtable as Booleans.
     
       Otherwise, may get this error:
       InvalidTemplate - Long running operation failed with status 'Failed'. Additional Info:'Deployment template validation failed: 'Template parameter JToken type is not valid. Expected 'Boolean'. Actual 'String'. Please see
      | https://aka.ms/resource-manager-parameter-files for usage details.'.'
    #>
    if ($param[1] -ieq "true" -Or $param[1] -ieq "false")
    {
        $templateParamsHash.Add($param[0], [System.Convert]::ToBoolean($param[1]) );
    }
    else
    {
        $templateParamsHash.Add($param[0], $param[1]);
    }
}

New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroup `
    -WhatIf `
    -SkipTemplateParameterPrompt `
    -TemplateFile $templateFile `
    -TemplateParameterObject $templateParamsHash