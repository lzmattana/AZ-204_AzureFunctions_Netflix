#!/bin/bash

# Configurações (ajuste conforme criado na infraestrutura)
FUNCTION_APP="func-netflix-catalog"
RESOURCE_GROUP="rg-netflix-catalog"

echo "🚀 Deploy das Azure Functions..."
echo ""

# 1. Verificar se Azure Functions Core Tools está instalado
if ! command -v func &> /dev/null; then
    echo "❌ Azure Functions Core Tools não está instalado"
    echo "Instale com: npm install -g azure-functions-core-tools@4 --unsafe-perm true"
    exit 1
fi

# 2. Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI não está instalado"
    echo "Instale em: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# 3. Login no Azure (se necessário)
echo "🔐 Verificando autenticação Azure..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "Fazendo login no Azure..."
    az login
fi

# 4. Criar arquivo .funcignore se não existir
if [ ! -f .funcignore ]; then
    echo "📝 Criando .funcignore..."
    cat > .funcignore << EOF
.git*
.vscode
__pycache__
*.pyc
.python_packages
local.settings.json
test*.py
*.sh
.env
venv/
env/
EOF
fi

# 5. Instalar dependências Python localmente
echo "📦 Instalando dependências..."
pip install -r requirements.txt --target .python_packages/lib/site-packages

# 6. Deploy para Azure
echo "☁️ Fazendo deploy para Azure..."
func azure functionapp publish $FUNCTION_APP --python

# 7. Verificar status
echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📊 Verificando status da Function App..."
az functionapp show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query "{Name:name, State:state, DefaultHostName:defaultHostName}" \
  --output table

# 8. Obter Function Key
echo ""
echo "🔑 Obtendo Function Key..."
FUNCTION_KEY=$(az functionapp keys list \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query "functionKeys.default" \
  --output tsv)

# 9. Mostrar URLs
echo ""
echo "🌐 URLs das Functions:"
echo "========================================="
BASE_URL="https://${FUNCTION_APP}.azurewebsites.net"

echo "Upload File:"
echo "${BASE_URL}/api/UploadFile?code=${FUNCTION_KEY}"
echo ""
echo "Save Catalog:"
echo "${BASE_URL}/api/SaveCatalog?code=${FUNCTION_KEY}"
echo ""
echo "Filter Catalog:"
echo "${BASE_URL}/api/FilterCatalog?code=${FUNCTION_KEY}"
echo ""
echo "List Catalog:"
echo "${BASE_URL}/api/ListCatalog?code=${FUNCTION_KEY}"
echo "========================================="

# 10. Testar endpoint
echo ""
echo "🧪 Testando endpoint de listagem..."
curl -s "${BASE_URL}/api/ListCatalog?code=${FUNCTION_KEY}&limit=1" | head -n 20

echo ""
echo "✅ Deploy completo!"