#!/usr/bin/env bash

set -euo pipefail

: "${RESOURCE_GROUP_NAME:?RESOURCE_GROUP_NAME is required}"
: "${CARGO_TRACKER_IMAGE:?CARGO_TRACKER_IMAGE is required}"

namespace=${AZURE_AKS_NAMESPACE:-default}
deadline=$((SECONDS + 900))
until [[ "$(kubectl --namespace "${namespace}" get \
  openlibertyapplication/cargo-tracker-cluster \
  --output jsonpath='{.status.imageReference}' 2>/dev/null)" == "${CARGO_TRACKER_IMAGE}" ]]; do
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for Open Liberty Operator to reconcile ${CARGO_TRACKER_IMAGE}." >&2
    exit 1
  fi
  sleep 5
done

until [[ "$(kubectl --namespace "${namespace}" get \
  deployment/cargo-tracker-cluster \
  --output jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)" == "${CARGO_TRACKER_IMAGE}" ]]; do
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for the generated Deployment to use ${CARGO_TRACKER_IMAGE}." >&2
    exit 1
  fi
  sleep 5
done

kubectl --namespace "${namespace}" rollout status \
  deployment/cargo-tracker-cluster \
  --timeout=15m
kubectl --namespace "${namespace}" wait \
  --for=condition=Ready \
  openlibertyapplication/cargo-tracker-cluster \
  --timeout=15m

gateway_public_ip_id=$(az network application-gateway list \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query '[0].frontendIPConfigurations[0].publicIPAddress.id' \
  --output tsv | tr -d '\r')

gateway_hostname=$(az network public-ip show \
  --ids "${gateway_public_ip_id}" \
  --query dnsSettings.fqdn \
  --output tsv | tr -d '\r')

cargo_tracker_url="http://${gateway_hostname}/cargo-tracker/"
deadline=$((SECONDS + 900))
until [[ "$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --max-time 30 "${cargo_tracker_url}" || true)" == "200" ]]; do
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for ${cargo_tracker_url} to return HTTP 200." >&2
    exit 1
  fi
  sleep 10
done

azd env set CARGO_TRACKER_URL "${cargo_tracker_url}"
echo "Cargo Tracker URL: ${cargo_tracker_url}"
