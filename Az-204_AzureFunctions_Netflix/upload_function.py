import logging
import json
import os
import uuid
from datetime import datetime
import azure.functions as func
from azure.storage.blob import BlobServiceClient

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('UploadFile function processando requisição.')

    try:
        # Obter connection string do Storage
        connection_string = os.environ["StorageConnection"]
        container_name = "netflix-files"

        # Obter arquivo do request
        file = req.files.get('file')
        if not file:
            return func.HttpResponse(
                json.dumps({
                    "error": "Nenhum arquivo fornecido",
                    "message": "Envie um arquivo usando o campo 'file'"
                }),
                status_code=400,
                mimetype="application/json"
            )

        # Gerar nome único para o arquivo
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else ''
        unique_filename = f"{uuid.uuid4()}.{file_extension}"

        # Upload para o Blob Storage
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        blob_client = blob_service_client.get_blob_client(
            container=container_name,
            blob=unique_filename
        )

        # Fazer upload
        file_content = file.stream.read()
        blob_client.upload_blob(file_content, overwrite=True)

        # Gerar URL do arquivo
        blob_url = blob_client.url

        response_data = {
            "success": True,
            "message": "Arquivo enviado com sucesso",
            "data": {
                "original_filename": file.filename,
                "stored_filename": unique_filename,
                "blob_url": blob_url,
                "container": container_name,
                "size_bytes": len(file_content),
                "uploaded_at": datetime.utcnow().isoformat()
            }
        }

        logging.info(f'Arquivo {file.filename} enviado como {unique_filename}')

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=200,
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
        logging.error(f'Erro ao fazer upload: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Erro no upload",
                "message": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )