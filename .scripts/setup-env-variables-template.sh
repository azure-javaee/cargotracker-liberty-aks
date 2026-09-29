export DB_RESOURCE_NAME="libertydb1110" # PostgreSQL server name, customize this
export RESOURCE_GROUP_NAME="abc1110rg" # customize this
export LOCATION=eastus # customize this, if desired

export APPINSIGHTS_NAME="appinsights$(date +%s)"
export DB_NAME=libertydb
export DB_PASSWORD="Secret123456" # PostgreSQL database password
export DB_PORT_NUMBER=5432
export DB_SERVER_NAME="${DB_RESOURCE_NAME}.postgres.database.azure.com" # PostgreSQL host name
export DB_USER=liberty
export LIBERTY_AKS_REPO_REF="1bfcc50b1bfdb4165d4ce5a5deb62b5b5346a3cc" # WASdev/azure.liberty.aks
export NAMESPACE=default
export WORKSPACE_NAME="${RESOURCE_GROUP_NAME}ws"

# Optional variables for OpenAI shortest path feature.
# Uncomment and set values as described in README.md.

# export AZURE_OPENAI_KEY=<your key>
# export AZURE_OPENAI_ENDPOINT=https://<yourdeployment>.openai.azure.com/
# export AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o
