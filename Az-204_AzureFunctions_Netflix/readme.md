# 🎬 Gerenciador de Catálogos Netflix - Azure Functions

Sistema completo de gerenciamento de catálogos de filmes e séries utilizando Azure Functions, Cosmos DB e Storage Account.

## 📋 Índice

- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [APIs Disponíveis](#apis-disponíveis)
- [Exemplos de Uso](#exemplos-de-uso)
- [Deploy](#deploy)
- [Custos Estimados](#custos-estimados)

## 🏗 Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                  HTTP Requests                       │
└───────────────────┬─────────────────────────────────┘
                    │
        ┌───────────▼──────────────┐
        │   Azure Function App     │
        │  ┌────────────────────┐  │
        │  │ UploadFile         │──┼──► Storage Account
        │  │ SaveCatalog        │  │      (Blob Container)
        │  │ FilterCatalog      │──┼──►
        │  │ ListCatalog        │  │    Cosmos DB
        │  └────────────────────┘  │    (NoSQL Database)
        └──────────────────────────┘
```

### Componentes

- **Azure Functions**: Serverless compute para processar requisições
- **Cosmos DB**: Banco de dados NoSQL para armazenar catálogos
- **Storage Account**: Armazenamento de arquivos (capas, imagens)
- **Application Insights**: Monitoramento e logs

## ✅ Pré-requisitos

### Software Necessário

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) >= 2.40.0
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local) v4
- [Python](https://www.python.org/downloads/) 3.9, 3.10 ou 3.11
- [Git](https://git-scm.com/)
- Conta Azure ativa

### Verificar Instalação

```bash
az --version
func --version
python --version
```

## 🚀 Instalação

### 1. Clonar o Repositório

```bash
git clone [https://github.com/seu-usuario/netflix-catalog-manager.git](https://github.com/lzmattana/AZ-204_AzureFunctions_Netflix)
cd netflix-catalog-manager
```

### 2. Criar Infraestrutura Azure

```bash
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```

Este script criará:
- Resource Group
- Storage Account com container `netflix-files`
- Cosmos DB com database `NetflixDB` e container `Catalogs`
- Function App com runtime Python

**Tempo estimado**: 5-10 minutos

### 3. Configurar Ambiente Local (Opcional)

```bash
# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r requirements.txt
```

### 4. Deploy das Functions

```bash
chmod +x deploy-functions.sh
./deploy-functions.sh
```

**Tempo estimado**: 2-3 minutos

## 📁 Estrutura do Projeto

```
netflix-catalog-manager/
├── UploadFile/
│   ├── __init__.py          # Função de upload
│   └── function.json        # Configuração
├── SaveCatalog/
│   ├── __init__.py          # Função de salvamento
│   └── function.json
├── FilterCatalog/
│   ├── __init__.py          # Função de filtro
│   └── function.json
├── ListCatalog/
│   ├── __init__.py          # Função de listagem
│   └── function.json
├── requirements.txt          # Dependências Python
├── host.json                # Configuração do host
├── local.settings.json      # Variáveis locais
├── deploy-infrastructure.sh # Script de infra
├── deploy-functions.sh      # Script de deploy
├── test-requests.sh         # Script de testes
└── README.md
```

## 🔌 APIs Disponíveis

### 1. Upload de Arquivo

**Endpoint**: `POST /api/UploadFile`

**Descrição**: Faz upload de arquivos (capas, imagens) para o Storage Account.

**Request**:
```bash
curl -X POST "https://func-netflix-catalog.azurewebsites.net/api/UploadFile?code=YOUR_KEY" \
  -F "file=@./cover.jpg"
```

**Response**:
```json
{
  "success": true,
  "message": "Arquivo enviado com sucesso",
  "data": {
    "original_filename": "cover.jpg",
    "stored_filename": "a1b2c3d4-e5f6.jpg",
    "blob_url": "https://storage.blob.core.windows.net/netflix-files/a1b2c3d4-e5f6.jpg",
    "size_bytes": 245678,
    "uploaded_at": "2026-01-10T15:30:00"
  }
}
```

### 2. Salvar Catálogo

**Endpoint**: `POST /api/SaveCatalog`

**Descrição**: Salva um novo filme ou série no Cosmos DB.

**Request**:
```bash
curl -X POST "https://func-netflix-catalog.azurewebsites.net/api/SaveCatalog?code=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Inception",
    "category": "Sci-Fi",
    "type": "movie",
    "description": "A thief who steals corporate secrets",
    "release_year": 2010,
    "rating": 8.8,
    "duration": "148 min",
    "cast": ["Leonardo DiCaprio", "Joseph Gordon-Levitt"],
    "director": "Christopher Nolan",
    "cover_url": "https://..."
  }'
```

**Campos**:
- `title` (obrigatório): Título
- `category` (obrigatório): Categoria (Ação, Drama, Comédia, Sci-Fi, etc)
- `type` (obrigatório): movie ou series
- `description`: Descrição
- `release_year`: Ano de lançamento
- `rating`: Nota (0-10)
- `duration`: Duração (filmes)
- `cast`: Array de atores
- `director`: Diretor
- `cover_url`: URL da capa

**Response**:
```json
{
  "success": true,
  "message": "Catálogo salvo com sucesso",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "Inception",
    "category": "Sci-Fi",
    "type": "movie",
    "created_at": "2026-01-10T15:30:00"
  }
}
```

### 3. Filtrar Catálogos

**Endpoint**: `GET /api/FilterCatalog`

**Descrição**: Filtra catálogos por diversos critérios.

**Parâmetros**:
- `category`: Filtrar por categoria
- `type`: Filtrar por tipo (movie/series)
- `title`: Buscar no título (parcial)
- `year`: Filtrar por ano
- `rating_min`: Nota mínima

**Exemplos**:

```bash
# Filtrar por categoria
curl "https://func-netflix-catalog.azurewebsites.net/api/FilterCatalog?code=YOUR_KEY&category=Sci-Fi"

# Filtrar por tipo
curl "https://func-netflix-catalog.azurewebsites.net/api/FilterCatalog?code=YOUR_KEY&type=series"

# Buscar por título
curl "https://func-netflix-catalog.azurewebsites.net/api/FilterCatalog?code=YOUR_KEY&title=Matrix"

# Filtros combinados
curl "https://func-netflix-catalog.azurewebsites.net/api/FilterCatalog?code=YOUR_KEY&category=Drama&rating_min=9.0"
```

**Response**:
```json
{
  "success": true,
  "message": "3 registro(s) encontrado(s)",
  "filters_applied": {
    "category": "Sci-Fi",
    "type": null,
    "title": null,
    "year": null,
    "rating_min": null
  },
  "count": 3,
  "data": [...]
}
```

### 4. Listar Catálogos

**Endpoint**: `GET /api/ListCatalog`

**Descrição**: Lista todos os catálogos com paginação.

**Parâmetros**:
- `limit`: Número de registros (padrão: 50, máximo: 100)
- `offset`: Deslocamento para paginação (padrão: 0)

**Request**:
```bash
curl "https://func-netflix-catalog.azurewebsites.net/api/ListCatalog?code=YOUR_KEY&limit=20&offset=0"
```

**Response**:
```json
{
  "success": true,
  "message": "Catálogos listados com sucesso",
  "statistics": {
    "total_records": 150,
    "returned_records": 20,
    "offset": 0,
    "limit": 20,
    "has_more": true
  },
  "summary": {
    "by_category": {
      "Ação": 45,
      "Drama": 38,
      "Sci-Fi": 27
    },
    "by_type": {
      "movie": 89,
      "series": 61
    }
  },
  "data": [...]
}
```

## 💡 Exemplos de Uso

### Exemplo Completo: Adicionar um Filme

```bash
# 1. Upload da capa
UPLOAD_RESPONSE=$(curl -X POST \
  "https://func-netflix-catalog.azurewebsites.net/api/UploadFile?code=YOUR_KEY" \
  -F "file=@./inception-cover.jpg")

# 2. Extrair URL da capa
COVER_URL=$(echo $UPLOAD_RESPONSE | jq -r '.data.blob_url')

# 3. Salvar catálogo com a capa
curl -X POST \
  "https://func-netflix-catalog.azurewebsites.net/api/SaveCatalog?code=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Inception\",
    \"category\": \"Sci-Fi\",
    \"type\": \"movie\",
    \"description\": \"A thief who steals corporate secrets through dream-sharing technology\",
    \"release_year\": 2010,
    \"rating\": 8.8,
    \"duration\": \"148 min\",
    \"cast\": [\"Leonardo DiCaprio\", \"Joseph Gordon-Levitt\", \"Ellen Page\"],
    \"director\": \"Christopher Nolan\",
    \"cover_url\": \"$COVER_URL\"
  }"
```

### Exemplo: Buscar Séries de Drama com Nota Alta

```bash
curl "https://func-netflix-catalog.azurewebsites.net/api/FilterCatalog?code=YOUR_KEY&type=series&category=Drama&rating_min=8.5"
```

## 🧪 Testes

Execute o script de testes automatizados:

```bash
chmod +x test-requests.sh
./test-requests.sh
```

Este script testa todas as 4 funções com diversos cenários.

## 💰 Custos Estimados

### Configuração de Desenvolvimento

| Serviço | Tier | Custo Mensal Estimado |
|---------|------|----------------------|
| Azure Functions | Consumption | $0 - $5 (1M execuções grátis) |
| Cosmos DB | 400 RU/s | ~$25 |
| Storage Account | Standard LRS | ~$2 |
| **Total** | | **~$27 - $32/mês** |

### Configuração de Produção

| Serviço | Tier | Custo Mensal Estimado |
|---------|------|----------------------|
| Azure Functions | Premium EP1 | ~$150 |
| Cosmos DB | 1000 RU/s autoscale | ~$60 |
| Storage Account | Standard GRS | ~$5 |
| **Total** | | **~$215/mês** |

## 🔒 Segurança

### Boas Práticas Implementadas

✅ Function Keys para autenticação
✅ CORS configurado
✅ HTTPS obrigatório
✅ Connection strings em variáveis de ambiente
✅ Validação de entrada em todas as funções
✅ Logs detalhados para auditoria

### Melhorias Recomendadas para Produção

- Implementar Azure AD Authentication
- Adicionar rate limiting
- Configurar Azure API Management
- Habilitar Azure Key Vault para secrets
- Implementar backup automático do Cosmos DB

## 📊 Monitoramento

### Application Insights

Todas as funções enviam logs para Application Insights automaticamente.

**Acessar logs**:
```bash
az monitor app-insights component show \
  --app func-netflix-catalog \
  --resource-group rg-netflix-catalog
```

### Métricas Importantes

- Tempo de execução das funções
- Taxa de erro
- Número de requisições
- Uso de RU/s no Cosmos DB

## 🛠 Troubleshooting

### Erro: "Connection string not found"

Verifique as variáveis de ambiente:
```bash
az functionapp config appsettings list \
  --name func-netflix-catalog \
  --resource-group rg-netflix-catalog
```

### Erro: "Cosmos DB throttling"

Aumente os RU/s do container:
```bash
az cosmosdb sql container throughput update \
  --account-name cosmos-netflix-catalog \
  --resource-group rg-netflix-catalog \
  --database-name NetflixDB \
  --name Catalogs \
  --throughput 1000
```

### Erro no deploy

Limpe o cache e tente novamente:
```bash
func azure functionapp publish func-netflix-catalog --python --build remote
```

## 📚 Recursos Adicionais

- [Documentação Azure Functions](https://docs.microsoft.com/azure/azure-functions/)
- [Cosmos DB Best Practices](https://docs.microsoft.com/azure/cosmos-db/best-practices)
- [Azure Storage Documentation](https://docs.microsoft.com/azure/storage/)

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT.

## ✨ Autor

Desenvolvido com ❤️ para demonstrar Azure Functions + Cosmos DB

---

**Pronto para uso em produção!** 🚀
