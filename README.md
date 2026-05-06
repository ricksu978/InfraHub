# SSW.2026MayUserGroup

Demo repository for the **SSW User Group — Introduction to Azure IaC using Bicep** session.

It contains:

- A simple **.NET 10 minimal API** with **Swagger UI** (`src/Api`).
- **Bicep** templates to provision the supporting Azure resources (`infra/`):
  - **API backend** — Linux App Service Plan + Web App configured for .NET 10, with a system-assigned managed identity.
  - **Key Vault** — RBAC-enabled, with the API's managed identity granted the *Key Vault Secrets User* role.
  - **Database** — Azure SQL logical server + database.

This repo is intentionally small enough for a live demo, but it still shows several production-relevant patterns:

- modular Bicep
- secure parameters
- managed identity
- Key Vault references in App Service settings
- deterministic naming and useful deployment outputs

> Naming in this repo follows Microsoft's Cloud Adoption Framework guidance for Azure resource abbreviations:
> https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

## Repository layout

```
.
├── src/
│   └── Api/                  # .NET 10 minimal API + Swagger UI
├── infra/
│   ├── main.bicep            # Orchestrates the three resources
│   ├── main.bicepparam       # Preferred Bicep parameters file
│   └── modules/
│       ├── api.bicep         # App Service Plan + Web App
│       ├── keyvault.bicep    # Key Vault + role assignments
│       └── database.bicep    # SQL server + database
├── global.json               # Pins the .NET SDK used locally for the sample API
└── SSW.2026MayUserGroup.slnx
```

## What This Demo Shows

- `infra/main.bicep` owns orchestration, naming, tags, outputs, and module wiring.
- `infra/modules/*.bicep` keep each resource area focused and reusable.
- The App Service is created with a system-assigned managed identity.
- The Key Vault module grants that identity the *Key Vault Secrets User* role.
- The web app reads `ConnectionStrings__DefaultConnection` using a `@Microsoft.KeyVault(...)` reference.

One important clarification for the audience: the sample API does **not** currently query SQL Server. The database is provisioned to demonstrate multi-resource deployments, secret management, and application configuration patterns.

## Run the API locally

```bash
dotnet run --project src/Api
```

Swagger UI is served at the application root (e.g. `https://localhost:<port>/`).

## Validate The Bicep Before Deploying

These are worth showing in the talk because they demonstrate how Bicep fits into a safe delivery workflow.

```bash
# PowerShell example for the secure SQL password used by infra/main.bicepparam
$env:SQL_ADMIN_PASSWORD = '<your-strong-password>'

# Restore/validate the Bicep graph locally
az bicep build --file infra/main.bicep

# Validate against Azure before deployment
az deployment group validate \
  --resource-group rg-usergroup-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Preview the changes
az deployment group what-if \
  --resource-group rg-usergroup-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## Deploy the Azure resources

Prerequisites: Azure CLI and a target resource group.

```bash
# 1. Sign in and pick a subscription
az login
az account set --subscription <subscription-id>

# 2. Create a resource group (one-time)
az group create --name rg-usergroup-dev --location australiaeast

# 3. Deploy using the Bicep parameters file
az deployment group create \
  --resource-group rg-usergroup-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

> ⚠️ Do **not** commit a real SQL password into source control.
> Pass it via an environment variable, a CI/CD pipeline secret, or a Key Vault parameter reference.
> `infra/main.bicepparam` includes a clearly fake fallback value so the repo can compile in a clean clone, but you should always override it for real deployments.

## Post-Deploy Bootstrap

After deployment, add the SQL connection string into Key Vault so the App Service can resolve it at runtime.

```bash
az keyvault secret set \
  --vault-name <key-vault-name> \
  --name SqlConnectionString \
  --value 'Server=tcp:<sql-server-name>.database.windows.net,1433;Initial Catalog=<database-name>;Persist Security Info=False;User ID=<sql-admin>;Password=<sql-password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
```

You can get the values from the deployment outputs:

```bash
az deployment group show \
  --resource-group rg-usergroup-dev \
  --name <deployment-name> \
  --query properties.outputs
```

## Verify The Deployment

```bash
# Show the deployed app hostname
az deployment group show \
  --resource-group rg-usergroup-dev \
  --name <deployment-name> \
  --query properties.outputs.apiHostName.value \
  --output tsv

# Inspect the app settings to confirm the Key Vault reference was deployed
az webapp config appsettings list \
  --resource-group rg-usergroup-dev \
  --name <web-app-name>
```

Then browse to `https://<web-app-name>.azurewebsites.net/` and confirm Swagger UI loads.

## Deployment Pipelines

The repo now includes two GitHub Actions workflows:

- `.github/workflows/deploy-dev.yml`
- `.github/workflows/deploy-prod.yml`

Both workflows call one reusable deployment workflow:

- `.github/workflows/template-cd.yml`

### Workflow Triggers

- `deploy-dev.yml` triggers on push to `main` and on `workflow_dispatch`
- `deploy-prod.yml` triggers on `workflow_dispatch`

### Delivery Model

- The pipelines are now infrastructure-only.
- There is no application build, no application deployment, and no artifact promotion.
- Each deployment checks out the repository source and deploys the Bicep files directly from `infra/`.
- The shared logic lives in `template-cd.yml`, so dev and prod only define trigger and target environment behavior.

### Required GitHub Variables

Create these environment variables for both the `dev` and `prod` GitHub environments:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_RESOURCE_GROUP`

### Required GitHub Secrets

Create these environment secrets for both the `dev` and `prod` GitHub environments:

- `SQL_ADMIN_PASSWORD`

### Azure Setup For OIDC

The GitHub workflow uses `azure/login` with OpenID Connect instead of a stored client secret. The service principal or federated identity needs permission to:

- deploy resources to the target resource group
- set Key Vault secrets

At minimum, assign it rights equivalent to resource-group deployment plus Key Vault secret write access for the target environment.

### Pipeline Notes

- `template-cd.yml` is the reusable CD unit.
- `infra/scripts/deploy.ps1` wraps `az deployment group create` for local and pipeline use.
- The SQL admin password comes from the environment-scoped `SQL_ADMIN_PASSWORD` secret and is passed into the Bicep deployment as an environment variable.
- Each deployment checks out the repository and deploys `infra/main.bicep` with `infra/main.bicepparam`.
- After infra deployment, each workflow reads the deployment outputs directly from the `az deployment group create` JSON result to discover the Key Vault, SQL server FQDN, and database name.
- The workflow then seeds the `SqlConnectionString` secret into Key Vault as part of the environment bootstrap.

### Where Bicep Fits

For this repo, Bicep now lives only in CD.

- `deploy-dev.yml` deploys the checked-out Bicep source to the `dev` environment.
- `deploy-prod.yml` deploys the checked-out Bicep source to the `prod` environment.

That keeps the pipeline aligned with the talk focus: infrastructure authoring and deployment with Bicep.

## Recommendations For This Repo

- Keep `main.bicep` as the orchestration layer and resist putting full resource definitions there once the demo grows.
- Use `.bicepparam` as the main teaching path. It is easier to read and more obviously tied to the Bicep template.
- Show `validate` and `what-if`, not just `create`. Mid-level DevOps engineers usually care more about safe change review than raw deployment syntax.
- Be explicit that the Key Vault secret is a second operational step. Without it, the infrastructure deploys successfully but the app configuration is incomplete.
- Call out that the API does not yet use SQL. That avoids audience confusion when they see a database but no data access code.

## Valuable Topics To Add In The Talk

- `bicepparam` vs ARM JSON parameters and when each appears in real teams.
- `what-if`, `validate`, and deployment outputs as part of pull request review.
- Why modules improve reuse, ownership boundaries, and testability.
- Managed identity plus Key Vault references as a safer alternative to storing secrets in app settings.
- Deterministic naming with `uniqueString()` and where it helps or hurts.
- The tradeoff between demo simplicity and production hardening, for example firewall rules, private endpoints, and App Service plan SKU choices.
- CI/CD integration: how the same commands translate into GitHub Actions or Azure DevOps.
- Decompiling existing ARM JSON to Bicep and using Azure Verified Modules for larger real-world estates.

## Suggested Demo Flow

1. Start in `infra/main.bicep` and explain the orchestration role: parameters, naming, tags, modules, and outputs.
2. Open one module at a time: `api.bicep`, `keyvault.bicep`, `database.bicep`, and explain why each concern is isolated.
3. Show the managed identity to Key Vault access path: App Service identity output feeds the Key Vault role assignment.
4. Show `infra/main.bicepparam` and explain why it is preferable to raw ARM parameter JSON for Bicep-first projects.
5. Run `az bicep build` to prove the file compiles locally.
6. Run `az deployment group validate` and explain the difference between local compilation and Azure-side validation.
7. Run `az deployment group what-if` and narrate the predicted resource changes.
8. Run `az deployment group create` to deploy the stack.
9. Show the deployment outputs and use them to identify the web app, Key Vault, and SQL server.
10. Seed the `SqlConnectionString` secret into Key Vault and explain why this step is operationally separate from infrastructure deployment.
11. Open the deployed Swagger UI and show that the app is running with Azure-hosted configuration.
12. Close by summarizing the production follow-ups: private networking, tighter SQL firewall rules, CI/CD, and adding real database access code.

## Speaker Notes

- If time is tight, skip local API execution and focus on Bicep authoring, validation, preview, deployment, and verification.
- If you want one extra stretch goal, add a GitHub Actions workflow after the main demo to show how little the commands change in CI.
- If someone asks why the app does not use SQL yet, answer directly: the repo is optimized to teach infrastructure composition and secret flow first, application data access second.

After deployment the API expects the SQL connection string to be stored in Key Vault as a secret named `SqlConnectionString`. The deployed App Service is already wired up to read it via a `@Microsoft.KeyVault(...)` reference on the `ConnectionStrings__DefaultConnection` app setting.
