# Sistema Automatizado de Clasificación de Tickets de Soporte 🎫

**Proyecto de Infraestructura como Código usando OpenTofu**  
*Curso de AWS Academy Data Engineering — Universidad Autónoma de Guadalajara*  
*Módulo 12: Automatización de Pipelines*

---

## 📋 Descripción del Proyecto

Este proyecto implementa un **sistema inteligente de triaje automatizado** para tickets de soporte técnico, desplegado completamente en AWS usando infraestructura como código (IaC) con OpenTofu. El pipeline está diseñado para simular el procesamiento que ocurre en sistemas reales de helpdesk como Zendesk, Jira Service Management o ServiceNow.

El sistema recibe tickets de usuarios, valida su integridad, clasifica automáticamente su severidad basándose en múltiples factores (puntuación de prioridad y análisis de contenido), y finalmente los enruta a las colas correspondientes para su atención. Esta automatización permite que los tickets críticos reciban atención inmediata, mientras que consultas menores se procesan de manera eficiente sin intervención manual inicial.

### ¿Por qué es importante este tipo de sistema?

En organizaciones con alto volumen de solicitudes de soporte (cientos o miles por día), el triaje manual es:
- **Lento**: cada ticket requiere lectura y evaluación humana
- **Inconsistente**: diferentes agentes pueden clasificar el mismo problema de forma distinta
- **Costoso**: requiere personal dedicado exclusivamente a clasificación

Un sistema automatizado como este:
- Procesa tickets en milisegundos
- Aplica reglas consistentes basadas en datos objetivos
- Reduce costos operativos significativamente
- Permite que el equipo de soporte se enfoque en resolver problemas, no en clasificarlos

---

## 🏗️ Arquitectura del Pipeline

El pipeline implementa un flujo de 3 etapas orquestado por AWS Step Functions:

```
    ┌─────────────────────────────────────────────────┐
    │         Entrada: Ticket JSON                    │
    │   {ticket_id, customer, priority_score, ...}    │
    └──────────────────┬──────────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────────┐
    │  LAMBDA 1: Validate Ticket                       │
    │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
    │  ✓ Verifica campos obligatorios                  │
    │  ✓ Valida tipo de datos (score: 0-100)           │
    │  ✓ Comprueba formato de email                    │
    │  ✓ Agrega: validation_passed = true              │
    └──────────────────┬───────────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────────┐
    │  LAMBDA 2: Classify Ticket                       │
    │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
    │  🔍 Analiza priority_score                       │
    │  🔍 Busca palabras clave urgentes:               │
    │     • urgent, emergency, down, critical, asap    │
    │  📊 Determina severidad:                         │
    │     • urgent: score ≥ 70 O palabras urgentes     │
    │     • low: score < 30 Y sin palabras urgentes    │
    │     • normal: resto de casos                     │
    │  ✓ Agrega: severity, classification_reason       │
    └──────────────────┬───────────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────────┐
    │  STEP FUNCTION: Choice State                     │
    │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
    │  if severity == "urgent"  → RouteUrgent          │
    │  if severity == "normal"  → RouteNormal          │
    │  if severity == "low"     → RouteLow             │
    └──────────┬───────────┬────────────┬───────────────┘
               │           │            │
        ┌──────▼────┐ ┌───▼─────┐ ┌───▼──────┐
        │  LAMBDA 3 │ │LAMBDA 3 │ │ LAMBDA 3 │
        │   urgent  │ │ normal  │ │   low    │
        └──────┬────┘ └────┬────┘ └────┬─────┘
               │           │            │
               ▼           ▼            ▼
    ┌──────────────────────────────────────────────────┐
    │           S3 Bucket: Tickets                     │
    │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
    │  📁 urgent/     → Atención inmediata             │
    │  📁 normal/     → Cola estándar                  │
    │  📁 low/        → Revisión periódica             │
    └──────────────────────────────────────────────────┘
```

### Estados de la Step Function

| Estado | Tipo | Función |
|--------|------|---------|
| `ValidateTicket` | Task | Invoca Lambda 1 para validación |
| `ClassifyTicket` | Task | Invoca Lambda 2 para clasificación |
| `RouteBySeverity` | Choice | Decide la ruta según severity |
| `RouteUrgent` | Task | Procesa tickets urgentes |
| `RouteNormal` | Task | Procesa tickets normales |
| `RouteLow` | Task | Procesa tickets de baja prioridad |
| `TicketProcessedSuccessfully` | Succeed | Finalización exitosa |
| `ValidationFailed` | Fail | Error en validación |

**Total de estados**: 7 (cumple con el máximo permitido)

---

## 📁 Estructura del Repositorio

```
ticket-classifier-tofu/
├── main.tf                          # Recursos principales (S3, Lambdas)
├── step_function.tf                 # Definición de Step Function y estados
├── iam.tf                           # Roles y políticas IAM
├── variables.tf                     # Variables de entrada
├── outputs.tf                       # Outputs del proyecto
├── terraform.tfvars                 # Valores específicos (NO versionado)
├── .gitignore                       # Archivos excluidos de Git
├── README.md                        # Esta documentación
│
├── lambdas/
│   ├── validate_ticket/
│   │   └── lambda_function.py       # L1: Validación de campos
│   ├── classify_ticket/
│   │   └── lambda_function.py       # L2: Clasificación de severidad
│   └── route_ticket/
│       └── lambda_function.py       # L3: Enrutamiento a S3
│
├── modules/
│   └── lambda_function/             # Módulo reutilizable
│       ├── main.tf                  # Empaquetado y despliegue
│       ├── variables.tf             # Variables del módulo
│       └── outputs.tf               # ARNs y nombres de función
│
├── tests/
│   ├── test_urgent_ticket.json      # Caso 1: Ticket urgente
│   ├── test_normal_ticket.json      # Caso 2: Ticket normal
│   └── test_low_ticket.json         # Caso 3: Ticket bajo
│
└── .github/
    └── workflows/
        └── terraform.yml            # CI/CD con GitHub Actions
```

---

## 🔧 Lógica de Negocio Detallada

### Lambda 1: Validate Ticket

**Propósito**: Actuar como gateway de entrada, rechazando datos malformados antes de procesamiento.

**Validaciones implementadas**:

1. **Campos obligatorios presentes**:
   - `ticket_id`: Identificador único
   - `customer`: Email del reportante
   - `priority_score`: Puntuación numérica
   - `description`: Descripción del problema

2. **Validación de tipos y rangos**:
   - `priority_score` debe ser numérico entre 0 y 100
   - Campos de texto no pueden estar vacíos

3. **Formato de email**:
   - Debe contener `@`
   - Debe tener dominio con `.`

**Salida**: Evento original + `validation_passed: true`

**Manejo de errores**: Si cualquier validación falla, lanza `ValueError` que activa el estado `ValidationFailed` en Step Function.

---

### Lambda 2: Classify Ticket

**Propósito**: Determinar la urgencia real combinando métricas cuantitativas y cualitativas.

**Algoritmo de clasificación**:

```python
if priority_score >= 70 OR contiene_palabras_urgentes:
    severity = "urgent"
elif priority_score < 30 AND NOT contiene_palabras_urgentes:
    severity = "low"
else:
    severity = "normal"
```

**Palabras clave detectadas** (case-insensitive):
- **Inglés**: urgent, emergency, down, not working, critical, production, outage, broken, asap, immediately
- **Español**: urgente, emergencia, caído, no funciona, crítico, producción, interrupción, roto, inmediatamente

**Ejemplo de clasificación**:

| Caso | Priority Score | Descripción | Severidad | Razón |
|------|----------------|-------------|-----------|-------|
| A | 85 | "Sistema caído" | `urgent` | High score (85) + keyword "caído" |
| B | 50 | "Nueva funcionalidad" | `normal` | Moderate score, no keywords |
| C | 15 | "Pregunta sobre docs" | `low` | Low score (15), no keywords |

**Salida**: Evento + `severity` + `classification_reason`

---

### Lambda 3: Route Ticket

**Propósito**: Persistir el ticket clasificado en la estructura de carpetas de S3 para consumo posterior.

**Estructura de almacenamiento**:

```
s3://proyecto-studentid-tickets/
  ├── urgent/
  │   ├── tk-001.json
  │   └── tk-042.json
  ├── normal/
  │   ├── tk-002.json
  │   └── tk-015.json
  └── low/
      ├── tk-003.json
      └── tk-008.json
```

**Formato del archivo guardado**:
```json
{
  "ticket_id": "tk-042",
  "customer": "student@uag.mx",
  "priority_score": 85,
  "description": "Sistema caído",
  "validation_passed": true,
  "severity": "urgent",
  "classification_reason": "high priority score (85); urgent keywords detected: caído",
  "s3_destination": "s3://bucket/urgent/tk-042.json",
  "routed_at": "abc123-request-id"
}
```

**Beneficios de esta estructura**:
- Fácil integración con sistemas downstream (notificaciones, dashboards)
- Auditoría completa del procesamiento
- Posibilidad de re-procesamiento sin pérdida de información

---

## ☁️ Recursos AWS Desplegados

| Recurso | Cantidad | Nombre | Costo Estimado |
|---------|----------|--------|----------------|
| **S3 Bucket** | 1 | `{project}-{student_id}-tickets` | ~$0.01/mes (1000 objetos) |
| **Lambda Functions** | 3 | validate/classify/route-ticket | Gratis (Free Tier: 1M req/mes) |
| **IAM Roles** | 2 | lambda-role, step-function-role | Gratis |
| **IAM Policies** | 3 | s3-access, lambda-invoke, logs | Gratis |
| **Step Functions** | 1 | ticket-classifier | $0.025 per 1000 transiciones |
| **CloudWatch Logs** | 1 | step-function-logs | ~$0.50/GB |

**Costo mensual estimado** (uso ligero): **< $1 USD**

---

## 🚀 Guía de Despliegue

### Prerrequisitos

1. **OpenTofu** instalado (`>= 1.6`):
   ```bash
   # macOS
   brew install opentofu
   
   # Linux
   curl -fsSL https://get.opentofu.org | sh
   ```

2. **AWS CLI** configurado:
   ```bash
   aws configure
   # AWS Access Key ID: [tu_key]
   # AWS Secret Access Key: [tu_secret]
   # Default region: us-east-1
   ```

3. **Credenciales con permisos**:
   - S3: CreateBucket, PutObject, GetObject
   - Lambda: CreateFunction, InvokeFunction
   - IAM: CreateRole, AttachRolePolicy
   - Step Functions: CreateStateMachine

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/ticket-classifier-tofu.git
cd ticket-classifier-tofu
```

### Paso 2: Configurar variables

Crear `terraform.tfvars`:

```hcl
student_id   = "tu-matricula"
project_name = "ticket-classifier"
aws_region   = "us-east-1"
```

### Paso 3: Inicializar Terraform

```bash
tofu init
```

**Salida esperada**:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Paso 4: Revisar el plan

```bash
tofu plan
```

Revisar que se crearán:
- 1 S3 bucket
- 3 Lambda functions
- 1 Step Function
- 2 IAM roles
- 3 IAM policies

### Paso 5: Desplegar

```bash
tofu apply
```

Escribir `yes` cuando se solicite confirmación.

**Tiempo estimado**: 2-3 minutos

### Paso 6: Verificar despliegue

```bash
# Listar recursos creados
aws s3 ls | grep tickets
aws lambda list-functions | grep ticket
aws stepfunctions list-state-machines | grep classifier
```

---

## 🧪 Pruebas del Pipeline

### Ejecutar un ticket urgente

```bash
# Obtener ARN de la Step Function
STEP_ARN=$(tofu output -raw step_function_arn)

# Ejecutar con ticket urgente
aws stepfunctions start-execution \
  --state-machine-arn $STEP_ARN \
  --input file://tests/test_urgent_ticket.json \
  --name "test-urgent-$(date +%s)"
```

**Resultado esperado**:
```json
{
  "executionArn": "arn:aws:states:us-east-1:...:execution:ticket-classifier:test-urgent-1234567890",
  "startDate": "2024-01-15T10:30:00.000Z"
}
```

### Verificar resultado en S3

```bash
# Listar archivos en carpeta urgent
aws s3 ls s3://ticket-classifier-tu-id-tickets/urgent/

# Descargar y ver contenido
aws s3 cp s3://ticket-classifier-tu-id-tickets/urgent/tk-001.json -
```

### Casos de prueba incluidos

| Archivo | Severidad Esperada | Razón |
|---------|-------------------|-------|
| `test_urgent_ticket.json` | `urgent` | Priority 85 + palabras clave |
| `test_normal_ticket.json` | `normal` | Priority 50, sin keywords |
| `test_low_ticket.json` | `low` | Priority 15, sin keywords |

### Verificar estructura completa

```bash
aws s3 ls --recursive s3://ticket-classifier-tu-id-tickets/
```

**Salida esperada**:
```
2024-01-15 10:30:15    342 urgent/tk-001.json
2024-01-15 10:31:22    298 normal/tk-002.json
2024-01-15 10:32:08    287 low/tk-003.json
```

---

## 🔄 CI/CD con GitHub Actions

El repositorio incluye un workflow de CI/CD que:

1. **En cada push a `main`**:
   - Ejecuta `tofu fmt -check` (verifica formato)
   - Ejecuta `tofu validate` (valida sintaxis)

2. **En cada pull request**:
   - Ejecuta `tofu plan` (muestra cambios)
   - Comenta el plan en el PR

3. **En merge a `main` (con aprobación manual)**:
   - Ejecuta `tofu apply` automáticamente

### Configurar GitHub Actions

1. Agregar secrets al repositorio:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. El workflow está en `.github/workflows/terraform.yml`

---

## 🧹 Limpieza de Recursos

**IMPORTANTE**: Ejecutar antes de la defensa para evitar cargos.

```bash
# Destruir toda la infraestructura
tofu destroy

# Confirmar con: yes
```

Verificar que todo se eliminó:

```bash
aws s3 ls | grep tickets          # Debe estar vacío
aws lambda list-functions | grep ticket  # Debe estar vacío
```

---

## 📊 Métricas y Monitoreo

### Ver ejecuciones de Step Function

```bash
aws stepfunctions list-executions \
  --state-machine-arn $(tofu output -raw step_function_arn) \
  --max-results 10
```

### Consultar logs de CloudWatch

```bash
aws logs tail /aws/stepfunctions/ticket-classifier-tu-id-ticket-classifier \
  --follow
```

### Conteo de tickets por severidad

```bash
echo "Tickets urgentes:"
aws s3 ls s3://ticket-classifier-tu-id-tickets/urgent/ | wc -l

echo "Tickets normales:"
aws s3 ls s3://ticket-classifier-tu-id-tickets/normal/ | wc -l

echo "Tickets de baja prioridad:"
aws s3 ls s3://ticket-classifier-tu-id-tickets/low/ | wc -l
```

---

## 🛡️ Seguridad y Buenas Prácticas

### Implementadas

✅ **Principio de mínimo privilegio**: Cada Lambda solo tiene permisos sobre su bucket específico  
✅ **Bucket privado**: Acceso público bloqueado por defecto  
✅ **Versioning habilitado**: Permite recuperación de tickets modificados  
✅ **Logs centralizados**: CloudWatch Logs para auditoría  
✅ **Variables sensibles en `.gitignore`**: No se versionan credenciales  
✅ **Tags consistentes**: Todos los recursos etiquetados para facturación  

### Recomendaciones para producción

🔐 **Cifrado en reposo**: Habilitar S3 SSE-KMS  
🔐 **Cifrado en tránsito**: HTTPS obligatorio para S3  
📊 **Métricas personalizadas**: CloudWatch Metrics para SLAs  
🚨 **Alertas**: SNS para tickets críticos  
🔄 **Backup**: S3 Cross-Region Replication  

---

## 🎓 Aprendizajes Clave

Este proyecto demuestra competencias en:

1. **Infraestructura como Código (IaC)**
   - Modularización con Terraform/OpenTofu
   - Reutilización de módulos
   - Manejo de state y outputs

2. **Arquitectura Serverless**
   - Orquestación con Step Functions
   - Funciones Lambda stateless
   - Event-driven processing

3. **Ingeniería de Datos**
   - Pipeline ETL (Extract-Transform-Load)
   - Clasificación basada en reglas
   - Particionamiento de datos en S3

4. **DevOps**
   - CI/CD con GitHub Actions
   - Automatización de deployments
   - Gestión de configuración

---

## 📚 Referencias

- [AWS Step Functions Developer Guide](https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 👨‍💻 Autor

Jose Aceves
Matrícula: 4980353 
Universidad Autónoma de Guadalajara  
AWS Academy Data Engineering - Módulo 12

---

## 📄 Licencia

Proyecto académico desarrollado para el curso de Big Data - UAG.  
Código disponible bajo licencia MIT para fines educativos.

---

**Última actualización**: Enero 2024  
**Versión de OpenTofu**: 1.6.x  
**Versión de AWS Provider**: 5.x
