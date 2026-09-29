#!/usr/bin/env bash

set -euo pipefail

: "${RESOURCE_GROUP_NAME:?RESOURCE_GROUP_NAME is required}"
: "${AZURE_AKS_CLUSTER_NAME:?AZURE_AKS_CLUSTER_NAME is required}"
: "${WORKSPACE_ID:?WORKSPACE_ID is required}"
: "${DB_RESOURCE_NAME:?DB_RESOURCE_NAME is required}"

azd config set alpha.aks.helm on

az aks get-credentials \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${AZURE_AKS_CLUSTER_NAME}" \
  --admin \
  --overwrite-existing

az aks enable-addons \
  --addons monitoring \
  --name "${AZURE_AKS_CLUSTER_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --workspace-resource-id "${WORKSPACE_ID}"

az postgres flexible-server parameter set \
  --name max_prepared_transactions \
  --value 10 \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --server-name "${DB_RESOURCE_NAME}"

az postgres flexible-server restart \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${DB_RESOURCE_NAME}"
