#!/bin/bash

# Configuração
FUNCTION_APP_URL="https://func-netflix-catalog.azurewebsites.net"
FUNCTION_KEY="YOUR_FUNCTION_KEY"

echo "🧪 Testando Azure Functions - Gerenciador de Catálogos Netflix"
echo "================================================================"

# Teste 1: Upload de arquivo
echo ""
echo "1️⃣ Testando Upload de Arquivo..."
curl -X POST \
  "${FUNCTION_APP_URL}/api/UploadFile?code=${FUNCTION_KEY}" \
  -F "file=@./test-cover.jpg" \
  -w "\nStatus: %{http_code}\n"

# Teste 2: Salvar catálogo - Filme
echo ""
echo "2️⃣ Testando Salvar Catálogo (Filme)..."
curl -X POST \
  "${FUNCTION_APP_URL}/api/SaveCatalog?code=${FUNCTION_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Stranger Things",
    "category": "Sci-Fi",
    "type": "series",
    "description": "Uma série sobre eventos sobrenaturais em uma pequena cidade",
    "release_year": 2016,
    "rating": 8.7,
    "cast": ["Millie Bobby Brown", "Finn Wolfhard", "Winona Ryder"],
    "director": "The Duffer Brothers"
  }' \
  -w "\nStatus: %{http_code}\n"

# Teste 3: Salvar catálogo - Série
echo ""
echo "3️⃣ Testando Salvar Catálogo (Série)..."
curl -X POST \
  "${FUNCTION_APP_URL}/api/SaveCatalog?code=${FUNCTION_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "A Origem",
    "category": "Ação",
    "type": "movie",
    "description": "Um ladrão que rouba segredos corporativos através do uso da tecnologia de compartilhamento de sonhos",
    "release_year": 2010,
    "rating": 8.8,
    "duration": "148 min",
    "cast": ["Leonardo DiCaprio", "Joseph Gordon-Levitt", "Ellen Page"],
    "director": "Christopher Nolan"
  }' \
  -w "\nStatus: %{http_code}\n"

# Teste 4: Salvar mais catálogos
echo ""
echo "4️⃣ Adicionando mais catálogos..."

curl -X POST "${FUNCTION_APP_URL}/api/SaveCatalog?code=${FUNCTION_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Breaking Bad",
    "category": "Drama",
    "type": "series",
    "description": "Um professor de química se torna produtor de metanfetamina",
    "release_year": 2008,
    "rating": 9.5,
    "cast": ["Bryan Cranston", "Aaron Paul"]
  }' > /dev/null 2>&1

curl -X POST "${FUNCTION_APP_URL}/api/SaveCatalog?code=${FUNCTION_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Matrix",
    "category": "Sci-Fi",
    "type": "movie",
    "description": "Um hacker descobre a verdadeira natureza da realidade",
    "release_year": 1999,
    "rating": 8.7,
    "duration": "136 min",
    "cast": ["Keanu Reeves", "Laurence Fishburne"]
  }' > /dev/null 2>&1

echo "✓ Catálogos adicionados"

# Teste 5: Listar todos os catálogos
echo ""
echo "5️⃣ Testando Listar Catálogos..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/ListCatalog?code=${FUNCTION_KEY}&limit=10" \
  -w "\nStatus: %{http_code}\n"

# Teste 6: Filtrar por categoria
echo ""
echo "6️⃣ Testando Filtro por Categoria (Sci-Fi)..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&category=Sci-Fi" \
  -w "\nStatus: %{http_code}\n"

# Teste 7: Filtrar por tipo
echo ""
echo "7️⃣ Testando Filtro por Tipo (series)..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&type=series" \
  -w "\nStatus: %{http_code}\n"

# Teste 8: Filtro por título
echo ""
echo "8️⃣ Testando Filtro por Título (Matrix)..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&title=Matrix" \
  -w "\nStatus: %{http_code}\n"

# Teste 9: Filtro por ano
echo ""
echo "9️⃣ Testando Filtro por Ano (2010)..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&year=2010" \
  -w "\nStatus: %{http_code}\n"

# Teste 10: Filtro por rating mínimo
echo ""
echo "🔟 Testando Filtro por Rating Mínimo (9.0)..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&rating_min=9.0" \
  -w "\nStatus: %{http_code}\n"

# Teste 11: Filtros combinados
echo ""
echo "1️⃣1️⃣ Testando Filtros Combinados..."
curl -X GET \
  "${FUNCTION_APP_URL}/api/FilterCatalog?code=${FUNCTION_KEY}&category=Sci-Fi&type=movie" \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ Testes concluídos!"