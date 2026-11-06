#!/usr/bin/env bash
set -euo pipefail

# Recursos compartilhados: criados e mantidos pelo script do Java.
RESOURCE_GROUP="rg-zeroviagem"
APP_SERVICE_PLAN="plan-zeroviagem"
WEBAPP_NAME="app-zeroviagem-dotnet"
RUNTIME="DOTNETCORE:8.0"

command -v az >/dev/null 2>&1 || { echo 'Erro: Azure CLI nao instalada.' >&2; exit 1; }
az account show >/dev/null 2>&1 || { echo 'Erro: autentique-se antes com az login.' >&2; exit 1; }

if [[ "$(az group exists --name "$RESOURCE_GROUP" -o tsv)" != "true" ]]; then
  echo "Erro: Resource Group '$RESOURCE_GROUP' nao existe. Execute primeiro o script Java." >&2
  exit 1
fi

PLAN_ID="$(az appservice plan show --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_PLAN" --query id -o tsv 2>/dev/null || true)"
if [[ -z "$PLAN_ID" ]]; then
  echo "Erro: App Service Plan '$APP_SERVICE_PLAN' nao existe. Execute primeiro o script Java." >&2
  exit 1
fi

if [[ "$(az appservice plan show --ids "$PLAN_ID" --query reserved -o tsv)" != "true" ]]; then
  echo 'Erro: o App Service Plan existente nao e Linux.' >&2
  exit 1
fi

if az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEBAPP_NAME" >/dev/null 2>&1; then
  echo "App Service '$WEBAPP_NAME' ja existe. Nenhuma alteracao realizada."
else
  az webapp create \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --name "$WEBAPP_NAME" \
    --runtime "$RUNTIME"
fi

az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEBAPP_NAME" --query '{name:name,url:defaultHostName,state:state}' -o table
