#!/bin/bash

# Configurações
RESOURCE_GROUP="rg-netflix-catalog"
LOCATION="eastus"
STORAGE_ACCOUNT="stnetflixcatalog$(date +%s)"
COSMOSDB_ACCOUNT="cosmos-netflix-catalog"
FUNCTION_APP="func-netflix-catalog"
APP_SERVICE_PLAN="plan-netflix-catalog"

echo "🚀 Iniciando deploy da infraestrutura Azure..."

# 1. Criar Resource Group
echo "📦 Criando Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# 2. Criar Storage Account
echo "💾 Criando Storage Account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# Criar container para arquivos
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

az storage container create \
  --name netflix-files \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY

# 3. Criar Cosmos DB Account
echo "🌐 Criando Cosmos DB..."
az cosmosdb create \
  --name $COSMOSDB_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --locations regionName=$LOCATION failoverPriority=0 \
  --default-consistency-level Session

# Criar Database e Container
az cosmosdb sql database create \
  --account-name $COSMOSDB_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --name NetflixDB

az cosmosdb sql container create \
  --account-name $COSMOSDB_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --database-name NetflixDB \
  --name Catalogs \
  --partition-key-path "/category" \
  --throughput 400

# 4. Criar App Service Plan (Consumption)
echo "⚡ Criando App Service Plan..."
az functionapp plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Y1 \
  --is-linux true

# 5. Criar Function App
echo "⚙️ Criando Function App..."
az functionapp create \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime python \
  --runtime-version 3.11 \
  --storage-account $STORAGE_ACCOUNT \
  --os-type Linux \
  --functions-version 4

# 6. Obter connection strings
COSMOS_CONNECTION=$(az cosmosdb keys list \
  --name $COSMOSDB_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --type connection-strings \
  --query 'connectionStrings[0].connectionString' -o tsv)

STORAGE_CONNECTION=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query 'connectionString' -o tsv)

# 7. Configurar App Settings
echo "🔧 Configurando variáveis de ambiente..."
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "CosmosDBConnection=$COSMOS_CONNECTION" \
    "StorageConnection=$STORAGE_CONNECTION" \
    "COSMOSDB_DATABASE=NetflixDB" \
    "COSMOSDB_CONTAINER=Catalogs"

echo "✅ Infraestrutura criada com sucesso!"
echo ""
echo "📝 Informações importantes:"
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Cosmos DB: $COSMOSDB_ACCOUNT"
echo "Function App: $FUNCTION_APP"
echo ""
echo "🔑 Connection Strings salvas nas configurações da Function App"