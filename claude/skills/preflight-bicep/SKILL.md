---
name: preflight-bicep
description: Validate and preview Azure Bicep before deploying — build/lint, ARM validation, and what-if change preview. Use after generating or editing Bicep, or when the user asks to validate, preview, or dry-run infrastructure changes.
---

# Preflight Bicep

Run preflight checks on Bicep templates before deployment. This skill does not author Bicep (use `create-bicep`) and does not deploy — it only builds, validates, and previews.

## Intake

First read `config.json` from the create-bicep skill (`.claude/skills/create-bicep/config.json`) if it exists — it provides project-wide `projectName` and `location`. Use it to avoid re-asking for those.

Identify the target before running anything:

- **Template**: the `main.bicep` (or module) to check. Default to `infra-ai/main.bicep` if present.
- **Environment / parameter file**: the `.bicepparam` to check, e.g. `main.<env>.bicepparam`. If more than one environment exists, ask which to check or run the checks for each.
- **Scope**: the resource group and current subscription for validate and what-if. Derive a default from convention (`rg-<projectName>-<env>`) but confirm with the user before using it.
- **Secrets**: `.bicepparam` files may read secrets from env vars (e.g. `readEnvironmentVariable('SQL_ADMIN_PASSWORD')`). Confirm required env vars are set before validate/what-if; do not invent values.

## Preflight steps

Run these in order and stop at the first failing step, reporting the error concisely.

1. **Build / lint** — catches syntax and linter issues locally, no Azure auth needed:
   ```bash
   az bicep build --file <template>.bicep
   ```
   Clean up any generated `<template>.json` afterward unless the user wants it.

2. **Auth / scope check** — validate and what-if need a logged-in CLI and an existing resource group:
   ```bash
   az account show
   az group show --name <rg>          # or: az group create -n <rg> -l <location>
   ```

3. **ARM validation** — checks the template against Azure without deploying:
   ```bash
   az deployment group validate \
     --resource-group <rg> \
     --template-file <template>.bicep \
     --parameters <params>.bicepparam
   ```

4. **What-if preview** — shows the exact resource changes (create/modify/delete) the deployment would make:
   ```bash
   az deployment group what-if \
     --resource-group <rg> \
     --template-file <template>.bicep \
     --parameters <params>.bicepparam
   ```

## Reporting

Summarize the what-if output for the user: which resources are being created, modified, or deleted, and flag anything destructive (deletes, replacements, or SKU/tier changes) before they deploy. Report validation errors with the file and line when available.

## Fallbacks

- If the Bicep CLI is only available through Azure CLI, use `az bicep ...`; standalone `bicep ...` also works if installed.
- If the user is not logged in or has no resource group, run step 1 (build/lint) and report that steps 2–4 need Azure auth and a resource group.
- This skill never runs `az deployment group create`; deploying is an explicit, separate action the user must request.
