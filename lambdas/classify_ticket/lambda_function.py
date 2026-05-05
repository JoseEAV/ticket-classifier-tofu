"""
Lambda 2: Classify Ticket
Determina la severidad del ticket basándose en el priority_score
y palabras clave en la descripción.
"""
import json
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Palabras clave que incrementan la severidad
URGENT_KEYWORDS = [
    'urgent', 'urgente', 'emergency', 'emergencia',
    'down', 'caído', 'not working', 'no funciona',
    'critical', 'crítico', 'production', 'producción',
    'outage', 'interrupción', 'broken', 'roto',
    'asap', 'immediately', 'inmediatamente'
]


def lambda_handler(event, context):
    """
    Clasifica el ticket en urgent, normal, o low según:
    1. priority_score
    2. Palabras clave en description
    
    Lógica de clasificación:
    - urgent: priority_score >= 70 O contiene palabras urgentes
    - low: priority_score < 30 Y NO contiene palabras urgentes
    - normal: casos restantes
    
    Returns:
        dict: Evento con campo 'severity' agregado
    """
    logger.info(f"Clasificando ticket {event.get('ticket_id', 'unknown')}")
    
    priority_score = float(event['priority_score'])
    description = event['description'].lower()
    
    # Detectar palabras clave urgentes en la descripción
    has_urgent_keywords = any(
        keyword in description for keyword in URGENT_KEYWORDS
    )
    
    # Determinar severidad
    if priority_score >= 70 or has_urgent_keywords:
        severity = 'urgent'
        reason = []
        if priority_score >= 70:
            reason.append(f"high priority score ({priority_score})")
        if has_urgent_keywords:
            found_keywords = [kw for kw in URGENT_KEYWORDS if kw in description]
            reason.append(f"urgent keywords detected: {', '.join(found_keywords[:3])}")
        classification_reason = '; '.join(reason)
    elif priority_score < 30 and not has_urgent_keywords:
        severity = 'low'
        classification_reason = f"low priority score ({priority_score}) and no urgent keywords"
    else:
        severity = 'normal'
        classification_reason = f"moderate priority score ({priority_score})"
    
    # Agregar clasificación al evento
    event['severity'] = severity
    event['classification_reason'] = classification_reason
    
    logger.info(
        f"Ticket {event['ticket_id']} clasificado como '{severity}': "
        f"{classification_reason}"
    )
    
    return event
