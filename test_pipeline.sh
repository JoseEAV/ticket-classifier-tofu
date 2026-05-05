#!/bin/bash

# Script de prueba del pipeline de clasificación de tickets
# Ejecuta los 3 casos de prueba y verifica los resultados

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Pipeline de Clasificación de Tickets - Tests  ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Verificar que OpenTofu está desplegado
echo -e "${YELLOW}[1/5]${NC} Verificando que la infraestructura está desplegada..."
if ! tofu output -raw step_function_arn > /dev/null 2>&1; then
    echo -e "${RED}Error: La infraestructura no está desplegada.${NC}"
    echo "Por favor ejecuta primero: tofu apply"
    exit 1
fi

STEP_ARN=$(tofu output -raw step_function_arn)
BUCKET_NAME=$(tofu output -raw bucket_name)

echo -e "${GREEN}✓${NC} Infraestructura encontrada"
echo "  Step Function: $STEP_ARN"
echo "  Bucket S3: $BUCKET_NAME"
echo ""

# Función para ejecutar un test
run_test() {
    local test_file=$1
    local expected_severity=$2
    local test_name=$3
    
    echo -e "${YELLOW}[Test]${NC} Ejecutando: $test_name"
    echo "  Archivo: $test_file"
    echo "  Severidad esperada: $expected_severity"
    
    # Generar un nombre único para la ejecución
    EXECUTION_NAME="test-$(basename $test_file .json)-$(date +%s)"
    
    # Ejecutar Step Function
    EXECUTION_ARN=$(aws stepfunctions start-execution \
        --state-machine-arn "$STEP_ARN" \
        --name "$EXECUTION_NAME" \
        --input file://$test_file \
        --query 'executionArn' \
        --output text)
    
    echo "  Execution ARN: $EXECUTION_ARN"
    
    # Esperar a que termine (máximo 30 segundos)
    echo -n "  Esperando resultado"
    for i in {1..30}; do
        sleep 1
        echo -n "."
        
        STATUS=$(aws stepfunctions describe-execution \
            --execution-arn "$EXECUTION_ARN" \
            --query 'status' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo ""
            echo -e "  ${GREEN}✓ Ejecución exitosa${NC}"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            echo ""
            echo -e "  ${RED}✗ Ejecución fallida${NC}"
            aws stepfunctions describe-execution --execution-arn "$EXECUTION_ARN"
            return 1
        fi
    done
    
    if [ "$STATUS" = "RUNNING" ]; then
        echo ""
        echo -e "  ${YELLOW}⚠ Timeout esperando resultado${NC}"
        return 1
    fi
    
    # Obtener ticket_id del archivo
    TICKET_ID=$(jq -r '.ticket_id' $test_file)
    
    # Verificar que el archivo está en la carpeta correcta en S3
    echo "  Verificando ubicación en S3..."
    S3_KEY="${expected_severity}/${TICKET_ID}.json"
    
    if aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Archivo encontrado en s3://${BUCKET_NAME}/${S3_KEY}${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Archivo NO encontrado en la ubicación esperada${NC}"
        echo "  Buscando en otras carpetas..."
        aws s3 ls s3://${BUCKET_NAME}/ --recursive | grep ${TICKET_ID}
        return 1
    fi
}

# Ejecutar tests
echo -e "${YELLOW}[2/5]${NC} Test 1: Ticket urgente"
echo "----------------------------------------"
run_test "tests/test_urgent_ticket.json" "urgent" "Ticket con alta prioridad y palabras clave urgentes"
echo ""

echo -e "${YELLOW}[3/5]${NC} Test 2: Ticket normal"
echo "----------------------------------------"
run_test "tests/test_normal_ticket.json" "normal" "Ticket con prioridad media"
echo ""

echo -e "${YELLOW}[4/5]${NC} Test 3: Ticket de baja prioridad"
echo "----------------------------------------"
run_test "tests/test_low_ticket.json" "low" "Ticket con baja prioridad"
echo ""

# Mostrar resumen
echo -e "${YELLOW}[5/5]${NC} Resumen de resultados"
echo "----------------------------------------"
echo "Estructura de carpetas en S3:"
aws s3 ls s3://${BUCKET_NAME}/ --recursive

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Conteo de tickets por severidad               ${NC}"
echo -e "${GREEN}==================================================${NC}"

URGENT_COUNT=$(aws s3 ls s3://${BUCKET_NAME}/urgent/ | wc -l)
NORMAL_COUNT=$(aws s3 ls s3://${BUCKET_NAME}/normal/ | wc -l)
LOW_COUNT=$(aws s3 ls s3://${BUCKET_NAME}/low/ | wc -l)

echo "  Urgentes: $URGENT_COUNT"
echo "  Normales: $NORMAL_COUNT"
echo "  Bajos:    $LOW_COUNT"
echo ""

echo -e "${GREEN}✓ Todos los tests completados exitosamente${NC}"
echo ""
echo "Para ver el contenido de un ticket:"
echo "  aws s3 cp s3://${BUCKET_NAME}/urgent/tk-001.json -"
echo ""
echo "Para ver los logs de ejecución:"
echo "  aws logs tail /aws/stepfunctions/${BUCKET_NAME/tickets/ticket-classifier} --follow"
