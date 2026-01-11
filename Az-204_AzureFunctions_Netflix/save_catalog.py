import logging
import json
import os
import uuid
from datetime import datetime
import azure.functions as func
from azure.cosmos import CosmosClient, exceptions

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('SaveCatalog function processando requisição.')

    try:
        # Obter dados do request
        try:
            req_body = req.get_json()
        except ValueError:
            return func.HttpResponse(
                json.dumps({
                    "error": "JSON inválido",
                    "message": "O corpo da requisição deve ser um JSON válido"
                }),
                status_code=400,
                mimetype="application/json"
            )

        # Validar campos obrigatórios
        required_fields = ['title', 'category', 'type']
        missing_fields = [field for field in required_fields if field not in req_body]
        
        if missing_fields:
            return func.HttpResponse(
                json.dumps({
                    "error": "Campos obrigatórios faltando",
                    "missing_fields": missing_fields,
                    "required_fields": required_fields
                }),
                status_code=400,
                mimetype="application/json"
            )

        # Conectar ao Cosmos DB
        connection_string = os.environ["CosmosDBConnection"]
        database_name = os.environ["COSMOSDB_DATABASE"]
        container_name = os.environ["COSMOSDB_CONTAINER"]

        client = CosmosClient.from_connection_string(connection_string)
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)

        # Preparar documento
        catalog_item = {
            "id": str(uuid.uuid4()),
            "title": req_body["title"],
            "category": req_body["category"],  # Partition key
            "type": req_body["type"],  # movie ou series
            "description": req_body.get("description", ""),
            "release_year": req_body.get("release_year"),
            "rating": req_body.get("rating"),
            "duration": req_body.get("duration"),
            "cast": req_body.get("cast", []),
            "director": req_body.get("director"),
            "cover_url": req_body.get("cover_url"),
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }

        # Inserir no Cosmos DB
        created_item = container.create_item(body=catalog_item)

        response_data = {
            "success": True,
            "message": "Catálogo salvo com sucesso",
            "data": created_item
        }

        logging.info(f'Catálogo criado: {created_item["id"]}')

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=201,
            mimetype="application/json"
        )

    except exceptions.CosmosHttpResponseError as e:
        logging.error(f'Erro Cosmos DB: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Erro no banco de dados",
                "message": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )

    except KeyError as e:
        logging.error(f'Variável de ambiente não encontrada: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Configuração inválida",
                "message": f"Variável de ambiente não encontrada: {str(e)}"
            }),
            status_code=500,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f'Erro ao salvar catálogo: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Erro interno",
                "message": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )