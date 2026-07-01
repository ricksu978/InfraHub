---
name: create-bicep
description: Create and edit Azure Bicep infrastructure from requested Azure resources. Use when generating Bicep files, modules, or bicepparam files for Azure infrastructure.
---

# Create Bicep

Generate or edit Azure Bicep files from the user's requested infrastructure. This skill only authors files. To validate, preview, or deploy them, use the `preflight-bicep` skill.

## Context config

Before asking the user anything, read `config.json` next to this skill (`.claude/skills/create-bicep/config.json`). It holds project-wide defaults — `projectName` and `location` — and lives with the skill, not in the generated infra folder. Use those values instead of re-asking. If the file is missing or a value is blank, ask once and write it back so future runs and the `preflight-bicep` skill reuse it.

Everything else (environments, SKUs, resource groups, secrets) is per-request and comes from intake or naming convention, not this file.

## Intake

Determine the Azure resources the user wants. If they already listed them, proceed; if vague, ask one concise question.

For anything not already in `infra.config.json`: ask which environments to target (staging only, or staging plus production) — this drives how many `.bicepparam` variants to generate — and ask for configuration that affects cost, security, or architecture (SKU/tier/size, identity, networking, backup/retention). If the user does not specify, use the lowest-cost practical option and state the assumptions after generating.

## Bicep practices

- Drive project name, environment name, and location from root parameters in `main.bicep`; pass them into modules instead of hardcoding. Derive resource names from a shared naming pattern, keeping resource-specific rules in modules.
- Use `.bicepparam` files, not ARM JSON parameter files.
- Prefer symbolic references (`appServicePlan.id`) over `resourceId()` / `reference()`.
- Use typed parameters for grouped inputs instead of loose `object` / `array` when practical.
- Use `@secure()` for sensitive parameters.
- For child resources, use the `parent` property instead of embedding parent names with `/`.

## Output style

Generate concise Bicep. Do not add `@description` to every parameter, property, variable, or output — use it only when purpose, allowed values, cost/security impact, or deployment behavior is not obvious from the name. Avoid boilerplate and file-header comments; comment only non-obvious decisions.

## Placement

Create AI-generated infrastructure in the `ai-infra/` folder. Treat this as the required output folder for generated Bicep files unless the user explicitly names a different path. Do not create or use `infra-ai/`. Do not edit the existing `infra/` folder unless explicitly asked.

## After generating

Tell the user they can validate and preview the changes with the `preflight-bicep` skill.
