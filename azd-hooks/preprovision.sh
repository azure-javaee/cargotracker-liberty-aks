#!/usr/bin/env bash

set -euo pipefail

repo_root=$(pwd)
template_ref=${LIBERTY_AKS_REPO_REF:-1bfcc50b1bfdb4165d4ce5a5deb62b5b5346a3cc}
output_dir="${repo_root}/infra/azure.liberty.aks"
tmp_dir=$(mktemp -d "${repo_root}/tmp-build.XXXXXX")

cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

for command in gh mvn; do
  command -v "${command}" >/dev/null 2>&1 || {
    echo "Required command not found: ${command}" >&2
    exit 1
  }
done

echo "Building WASdev/azure.liberty.aks at ${template_ref}"
gh repo clone WASdev/azure.liberty.aks "${tmp_dir}/azure.liberty.aks" -- --no-checkout
git -C "${tmp_dir}/azure.liberty.aks" checkout --detach "${template_ref}"

parent_version=$(sed -n '/<parent>/,/<\/parent>/s:.*<version>\(.*\)</version>.*:\1:p' \
  "${tmp_dir}/azure.liberty.aks/pom.xml" | head -n 1)
parent_asset="azure-javaee-iaas-parent-${parent_version}.pom"

gh release download "azure-javaee-iaas-parent-${parent_version}" \
  --repo azure-javaee/azure-javaee-iaas \
  --pattern "${parent_asset}" \
  --dir "${tmp_dir}"

mvn install:install-file \
  -Dfile="${tmp_dir}/${parent_asset}" \
  -DgroupId=com.microsoft.azure.iaas \
  -DartifactId=azure-javaee-iaas-parent \
  -Dversion="${parent_version}" \
  -Dpackaging=pom

mvn --file "${tmp_dir}/azure.liberty.aks/pom.xml" clean package -DskipTests

rm -rf "${output_dir}"
mkdir -p "${output_dir}"
cp -R "${tmp_dir}/azure.liberty.aks/target/bicep/." "${output_dir}/"
