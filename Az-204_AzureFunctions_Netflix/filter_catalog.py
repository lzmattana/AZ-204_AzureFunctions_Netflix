import logging
import json
import os
import azure.functions as func
from azure.cosmos import CosmosClient, exceptions

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('FilterCatalog function processando requisição.')

    try:
        # Obter parâmetros de filtro da query string
        category = req.params.get('category')
        content_type = req.params.get('type')
        title = req.params.get('title')
        year = req.params.get('year')
        rating_min = req.params.get('rating_min')

        # Conectar ao Cosmos DB
        connection_string = os.environ["CosmosDBConnection"]
        database_name = os.environ["COSMOSDB_DATABASE"]
        container_name = os.environ["COSMOSDB_CONTAINER"]

        client = CosmosClient.from_connection_string(connection_string)
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)

        # Construir query SQL
        query = "SELECT * FROM c WHERE 1=1"
        parameters = []

        if category:
            query += " AND c.category = @category"
            parameters.append({"name": "@category", "value": category})

        if content_type:
            query += " AND c.type = @type"
            parameters.append({"name": "@type", "value": content_type})

        if title:
            query += " AND CONTAINS(LOWER(c.title), LOWER(@title))"
            parameters.append({"name": "@title", "value": title})

        if year:
            query += " AND c.release_year = @year"
            parameters.append({"name": "@year", "value": int(year)})

        if rating_min:
            query += " AND c.rating >= @rating_min"
            parameters.append({"name": "@rating_min", "value": float(rating_min)})

        query += " ORDER BY c.created_at DESC"

        # Executar query
        items = list(container.query_items(
            query=query,
            parameters=parameters,
            enable_cross_partition_query=True
        ))

        response_data = {
            "success": True,
            "message": f"{len(items)} registro(s) encontrado(s)",
            "filters_applied": {
                "category": category,
                "type": content_type,
                "title": title,
                "year": year,
                "rating_min": rating_min
            },
            "count": len(items),
            "data": items
        }

        logging.info(f'Filtro aplicado. {len(items)} registros encontrados.')

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=200,
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

    except ValueError as e:
        logging.error(f'Erro de validação: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Parâmetros inválidos",
                "message": str(e)
            }),
            status_code=400,
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
        logging.error(f'Erro ao filtrar catálogos: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Erro interno",
                "message": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )