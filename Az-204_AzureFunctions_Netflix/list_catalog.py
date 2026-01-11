import logging
import json
import os
import azure.functions as func
from azure.cosmos import CosmosClient, exceptions

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('ListCatalog function processando requisição.')

    try:
        # Obter parâmetros de paginação
        limit = req.params.get('limit', '50')
        offset = req.params.get('offset', '0')

        try:
            limit = int(limit)
            offset = int(offset)
        except ValueError:
            return func.HttpResponse(
                json.dumps({
                    "error": "Parâmetros inválidos",
                    "message": "limit e offset devem ser números inteiros"
                }),
                status_code=400,
                mimetype="application/json"
            )

        # Validar limites
        if limit > 100:
            limit = 100
        if limit < 1:
            limit = 10

        # Conectar ao Cosmos DB
        connection_string = os.environ["CosmosDBConnection"]
        database_name = os.environ["COSMOSDB_DATABASE"]
        container_name = os.environ["COSMOSDB_CONTAINER"]

        client = CosmosClient.from_connection_string(connection_string)
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)

        # Query para listar todos os itens ordenados por data de criação
        query = """
            SELECT * FROM c 
            ORDER BY c.created_at DESC 
            OFFSET @offset LIMIT @limit
        """

        parameters = [
            {"name": "@offset", "value": offset},
            {"name": "@limit", "value": limit}
        ]

        # Executar query
        items = list(container.query_items(
            query=query,
            parameters=parameters,
            enable_cross_partition_query=True
        ))

        # Query para contar total de registros
        count_query = "SELECT VALUE COUNT(1) FROM c"
        total_count = list(container.query_items(
            query=count_query,
            enable_cross_partition_query=True
        ))[0]

        # Calcular estatísticas
        stats = {
            "total_records": total_count,
            "returned_records": len(items),
            "offset": offset,
            "limit": limit,
            "has_more": (offset + limit) < total_count
        }

        # Agrupar por categoria
        categories = {}
        types = {}
        for item in items:
            cat = item.get('category', 'Unknown')
            typ = item.get('type', 'Unknown')
            categories[cat] = categories.get(cat, 0) + 1
            types[typ] = types.get(typ, 0) + 1

        response_data = {
            "success": True,
            "message": "Catálogos listados com sucesso",
            "statistics": stats,
            "summary": {
                "by_category": categories,
                "by_type": types
            },
            "data": items
        }

        logging.info(f'Listados {len(items)} de {total_count} catálogos (offset: {offset})')

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
        logging.error(f'Erro ao listar catálogos: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Erro interno",
                "message": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )