# SSW.2026MayUserGroup

Demo repository for the **SSW User Group — Introduction to Azure IaC using Bicep** session.

It contains:

- A simple **.NET 10 minimal API** with **Swagger UI** (`src/Api`).
- **Bicep** templates to provision the supporting Azure resources (`infra/`):
  - **API backend** — Linux App Service Plan + Web App configured for .NET 10, with a system-assigned managed identity.
  - **Key Vault** — RBAC-enabled, with the API's managed identity granted the *Key Vault Secrets User* role.
  - **Database** — Azure SQL logical server + database.

## Repository layout

```
.
├── src/
│   └── Api/                  # .NET 10 minimal API + Swagger UI
├── infra/
│   ├── main.bicep            # Orchestrates the three resources
│   ├── main.parameters.json  # Sample parameter file
│   └── modules/
│       ├── api.bicep         # App Service Plan + Web App
│       ├── keyvault.bicep    # Key Vault + role assignments
│       └── database.bicep    # SQL server + database
└── SSW.2026MayUserGroup.sln
```

## Run the API locally

```bash
dotnet run --project src/Api
```

Swagger UI is served at the application root (e.g. `https://localhost:<port>/`).

## Deploy the Azure resources

Prerequisites: Azure CLI and a target resource group.

```bash
# 1. Sign in and pick a subscription
az login
az account set --subscription <subscription-id>

# 2. Create a resource group (one-time)
az group create --name rg-sswdemo-dev --location australiaeast

# 3. (Optional) Validate / preview
az deployment group what-if \
  --resource-group rg-sswdemo-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters sqlAdministratorLoginPassword='<your-strong-password>'

# 4. Deploy
az deployment group create \
  --resource-group rg-sswdemo-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters sqlAdministratorLoginPassword='<your-strong-password>'
```

> ⚠️ Do **not** commit a real SQL password into `infra/main.parameters.json`.
> Pass it on the command line, via a CI/CD pipeline secret, or with a Key Vault parameter reference.

After deployment the API expects the SQL connection string to be stored in Key Vault as a secret named `SqlConnectionString`. The deployed App Service is already wired up to read it via a `@Microsoft.KeyVault(...)` reference on the `ConnectionStrings__DefaultConnection` app setting.
