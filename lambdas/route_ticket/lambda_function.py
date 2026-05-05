"""
Lambda 3: Route Ticket
Almacena el ticket en la carpeta de S3 correspondiente según su severidad.
"""
import json
import logging
import boto3
import os

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Cliente S3
s3_client = boto3.client('s3')


def lambda_handler(event, context):
    """
    Guarda el ticket en S3 según su severidad:
    - urgent -> s3://bucket/urgent/
    - normal -> s3://bucket/normal/
    - low -> s3://bucket/low/
    
    Returns:
        dict: Evento con 's3_destination' agregado
    """
    logger.info(f"Enrutando ticket {event.get('ticket_id', 'unknown')}")
    
    # Obtener severidad y ticket_id
    severity = event.get('severity', 'normal')
    ticket_id = event.get('ticket_id', 'unknown')
    
    # Obtener bucket desde variable de entorno (será inyectado por Terraform)
    bucket_name = os.environ.get('BUCKET_NAME')
    if not bucket_name:
        error_msg = "Variable de entorno BUCKET_NAME no configurada"
        logger.error(error_msg)
        raise EnvironmentError(error_msg)
    
    # Construir la ruta S3
    s3_key = f"{severity}/{ticket_id}.json"
    
    # Preparar contenido para guardar
    ticket_content = json.dumps(event, indent=2)
    
    try:
        # Guardar en S3
        s3_client.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=ticket_content,
            ContentType='application/json'
        )
        
        s3_uri = f"s3://{bucket_name}/{s3_key}"
        logger.info(f"Ticket guardado exitosamente en: {s3_uri}")
        
        # Agregar destino al evento
        event['s3_destination'] = s3_uri
        event['routed_at'] = context.request_id
        
    except Exception as e:
        error_msg = f"Error al guardar en S3: {str(e)}"
        logger.error(error_msg)
        raise
    
    return event
