[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$DeploymentName,

    [Parameter(Mandatory = $true)]
    [string]$TemplateFile,

    [Parameter(Mandatory = $true)]
    [string]$ParameterFile,

    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,

    [Parameter(Mandatory = $true)]
    [string]$SqlAdministratorLogin,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

if ([string]::IsNullOrWhiteSpace($env:SQL_ADMIN_PASSWORD)) {
    throw "Environment variable SQL_ADMIN_PASSWORD is required."
}

# Values consumed by .bicepparam via readEnvironmentVariable()
$env:PROJECT_NAME = $ProjectName
$env:ENVIRONMENT_NAME = $EnvironmentName
$env:SQL_ADMIN_LOGIN = $SqlAdministratorLogin

if ($WhatIf) {
    az deployment group what-if `
        --resource-group $ResourceGroupName `
        --template-file $TemplateFile `
        --parameters $ParameterFile

    return
}

$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --name $DeploymentName `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --output json | ConvertFrom-Json -Depth 100

$outputs = $deploymentResult.properties.outputs

[pscustomobject]@{
    apiHostName     = $outputs.apiHostName.value
    keyVaultName    = $outputs.keyVaultName.value
    sqlServerFqdn   = $outputs.sqlServerFqdn.value
    sqlDatabaseName = $outputs.sqlDatabaseName.value
} | ConvertTo-Json -Depth 10