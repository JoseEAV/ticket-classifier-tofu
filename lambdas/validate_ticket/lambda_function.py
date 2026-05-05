"""
Lambda 1: Validate Ticket
Valida que el ticket de soporte contenga todos los campos requeridos
y que los valores estén en los rangos correctos.
"""
import json
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Valida los campos obligatorios del ticket de soporte.
    
    Campos requeridos:
    - ticket_id: string no vacío
    - customer: email válido
    - priority_score: número entre 0-100
    - description: string no vacío
    
    Returns:
        dict: Evento original con campo 'validation_passed' agregado
    
    Raises:
        ValueError: Si algún campo es inválido
    """
    logger.info(f"Validando ticket: {json.dumps(event)}")
    
    # Lista de campos obligatorios
    required_fields = ['ticket_id', 'customer', 'priority_score', 'description']
    
    # Verificar que existan todos los campos
    for field in required_fields:
        if field not in event:
            error_msg = f"Campo obligatorio faltante: {field}"
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        # Verificar que no estén vacíos (excepto priority_score que es numérico)
        if field != 'priority_score' and not event[field].strip():
            error_msg = f"El campo '{field}' no puede estar vacío"
            logger.error(error_msg)
            raise ValueError(error_msg)
    
    # Validar priority_score
    try:
        score = float(event['priority_score'])
        if score < 0 or score > 100:
            error_msg = f"priority_score debe estar entre 0 y 100, recibido: {score}"
            logger.error(error_msg)
            raise ValueError(error_msg)
    except (ValueError, TypeError) as e:
        error_msg = f"priority_score debe ser numérico: {str(e)}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    
    # Validar formato de email (validación básica)
    customer_email = event['customer']
    if '@' not in customer_email or '.' not in customer_email.split('@')[-1]:
        error_msg = f"Formato de email inválido: {customer_email}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    
    # Agregar campo de validación exitosa
    event['validation_passed'] = True
    
    logger.info(f"Validación exitosa para ticket {event['ticket_id']}")
    
    return event
