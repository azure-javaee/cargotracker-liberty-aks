#!/usr/bin/env bash

set -euo pipefail

: "${RESOURCE_GROUP_NAME:?RESOURCE_GROUP_NAME is required}"
: "${ACR_NAME:?ACR_NAME is required}"
: "${DB_RESOURCE_NAME:?DB_RESOURCE_NAME is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER_NAME:?DB_USER_NAME is required}"
: "${DB_ADMIN_PASSWORD:?DB_ADMIN_PASSWORD is required}"
: "${APP_INSIGHTS_CONNECTION_STRING:?APP_INSIGHTS_CONNECTION_STRING is required}"

export ACR_SERVER
ACR_SERVER=$(az acr show \
  --name "${ACR_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query loginServer \
  --output tsv | tr -d '\r')

export LOGIN_SERVER="${ACR_SERVER}"
export DB_SERVER_NAME="${DB_RESOURCE_NAME}.postgres.database.azure.com"
export DB_PORT_NUMBER=5432
export DB_USER="${DB_USER_NAME}"
export DB_PASSWORD="${DB_ADMIN_PASSWORD}"
export NAMESPACE="${AZURE_AKS_NAMESPACE:-default}"
export APPLICATIONINSIGHTS_CONNECTION_STRING="${APP_INSIGHTS_CONNECTION_STRING}"

mvn clean package -PopenLibertyOnAks

IMAGE_NAME=$(mvn -q -DforceStdout help:evaluate -Dexpression=project.artifactId)
IMAGE_VERSION=$(mvn -q -DforceStdout help:evaluate -Dexpression=project.version)
GIT_COMMIT=$(git rev-parse HEAD)
IMAGE_TAG="${IMAGE_VERSION}-$(git rev-parse --short=12 HEAD)-$(date -u +%Y%m%d%H%M%S)"

az acr build \
  --registry "${ACR_NAME}" \
  --platform linux/amd64 \
  --image "${IMAGE_NAME}:${IMAGE_TAG}" \
  --build-arg "BUILD_COMMIT=${GIT_COMMIT}" \
  target

cat > custom-values.yaml <<EOF
replicaCount: 2
namespace: "${NAMESPACE}"
appInsightConnectionString: "${APPLICATIONINSIGHTS_CONNECTION_STRING}"
loginServer: "${ACR_SERVER}"
imageName: "${IMAGE_NAME}"
imageTag: "${IMAGE_TAG}"
azureOpenAI:
  enabled: false
db:
  ServerName: "${DB_SERVER_NAME}"
  PortNumber: "${DB_PORT_NUMBER}"
  Name: "${DB_NAME}"
  User: "${DB_USER}"
  Password: "${DB_PASSWORD}"
EOF

azd env set CARGO_TRACKER_IMAGE "${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
