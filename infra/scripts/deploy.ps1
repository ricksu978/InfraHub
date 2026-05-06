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

    [Parameter(Mandatory = $true)]
    [string]$SqlAdministratorLoginPassword
)

$ErrorActionPreference = 'Stop'

$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --name $DeploymentName `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --parameters project=$ProjectName environmentName=$EnvironmentName sqlAdministratorLogin=$SqlAdministratorLogin sqlAdministratorLoginPassword=$SqlAdministratorLoginPassword `
    --output json | ConvertFrom-Json -Depth 100

$outputs = $deploymentResult.properties.outputs

[pscustomobject]@{
    keyVaultName = $outputs.keyVaultName.value
    sqlServerFqdn = $outputs.sqlServerFqdn.value
    sqlDatabaseName = $outputs.sqlDatabaseName.value
} | ConvertTo-Json -Depth 10