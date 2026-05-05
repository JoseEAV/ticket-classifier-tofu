# 📋 INSTRUCCIONES PARA IMPLEMENTAR TU TAREA

## Resumen del Proyecto
Has elegido el **Escenario C: Support Ticket Classifier** - un sistema que clasifica automáticamente tickets de soporte en 3 niveles de urgencia (urgent, normal, low).

## 🎯 Lo que te he preparado

He creado TODOS los archivos que necesitas:

1. **3 Lambdas en Python** (validate, classify, route)
2. **Step Function con Choice** (7 estados, 3 branches)
3. **README.md completo** (más de 200 palabras ✓)
4. **3 archivos JSON de prueba** (urgent, normal, low)
5. **GitHub Actions workflow** (CI/CD opcional)
6. **Scripts de testing**
7. **Documentación adicional**

---

## 📂 PASO 1: Organiza tu repositorio

### 1.1 Clona tu repo base de clase
```bash
git clone https://github.com/agusvillarreal/demo-tofu.git tu-ticket-classifier
cd tu-ticket-classifier
```

### 1.2 Copia los archivos que te he creado

Necesitas copiar estos archivos de mi respuesta a tu repositorio:

```
TU REPO/
├── lambdas/
│   ├── validate_ticket/
│   │   └── lambda_function.py        ← COPIAR: lambda_validate_ticket.py
│   ├── classify_ticket/
│   │   └── lambda_function.py        ← COPIAR: lambda_classify_ticket.py
│   └── route_ticket/
│       └── lambda_function.py        ← COPIAR: lambda_route_ticket.py
│
├── tests/
│   ├── test_urgent_ticket.json       ← COPIAR
│   ├── test_normal_ticket.json       ← COPIAR
│   └── test_low_ticket.json          ← COPIAR
│
├── .github/
│   └── workflows/
│       └── terraform.yml             ← COPIAR: github-workflow.yml
│
├── main.tf                           ← REEMPLAZAR con el nuevo main.tf
├── step_function.tf                  ← NUEVO ARCHIVO
├── iam.tf                            ← MANTENER el de clase (no cambiar)
├── variables.tf                      ← MANTENER el de clase (no cambiar)
├── outputs.tf                        ← MANTENER el de clase
├── .gitignore                        ← COPIAR el nuevo
├── README.md                         ← REEMPLAZAR con el nuevo README
├── QUICKSTART.md                     ← COPIAR (opcional)
└── test_pipeline.sh                  ← COPIAR (opcional)
```

### 1.3 Estructura de módulos (NO tocar)
```
modules/
└── lambda_function/
    ├── main.tf          ← De clase, NO MODIFICAR
    ├── variables.tf     ← De clase, NO MODIFICAR
    └── outputs.tf       ← De clase, NO MODIFICAR
```

---

## 🔧 PASO 2: Actualiza tu main.tf

El `main.tf` que te preparé tiene estas diferencias vs el de clase:

```hcl
# ANTES (clase - EICAR)
module "validate_json" { ... }
module "scan_content" { ... }
module "route_file" { ... }

# AHORA (tu proyecto - Tickets)
module "validate_ticket" { ... }
module "classify_ticket" { ... }
module "route_ticket" { ... }
```

**Cambios importantes:**
- Nombres de Lambda actualizados
- Bucket se llama `tickets` en lugar de `quarantine`
- Variable de entorno `BUCKET_NAME` para la Lambda de routing

---

## 🔄 PASO 3: Crea step_function.tf

Este es un archivo NUEVO que no existía en el repo de clase. Contiene:

1. **Resource `aws_sfn_state_machine`**: La definición del pipeline
2. **7 estados**:
   - ValidateTicket (Task)
   - ClassifyTicket (Task)
   - RouteBySeverity (Choice) ← 3 branches
   - RouteUrgent (Task)
   - RouteNormal (Task)
   - RouteLow (Task)
   - TicketProcessedSuccessfully (Succeed)
   - ValidationFailed (Fail)

3. **IAM roles y policies** para Step Functions
4. **CloudWatch Logs** para debugging

---

## ⚙️ PASO 4: Configura las variables

### 4.1 Crea `terraform.tfvars` (NO lo subas a Git)
```hcl
student_id   = "TU-MATRICULA-AQUI"  # Ejemplo: "301234567"
project_name = "ticket-classifier"
aws_region   = "us-east-1"
```

### 4.2 Verifica que `variables.tf` tiene:
```hcl
variable "student_id" {
  description = "Identificador único del estudiante"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "ticket-classifier"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}
```

---

## 🚀 PASO 5: Despliega

```bash
# 1. Configura AWS CLI
aws configure
# Access Key ID: [tu key]
# Secret Access Key: [tu secret]
# Region: us-east-1

# 2. Inicializa OpenTofu
tofu init

# 3. Valida la configuración
tofu validate

# 4. Ve el plan
tofu plan

# 5. Despliega
tofu apply
# Escribir: yes
```

**Tiempo estimado**: 2-3 minutos

**Recursos creados**:
- 1 S3 bucket: `ticket-classifier-{tu-id}-tickets`
- 3 Lambdas: validate, classify, route
- 1 Step Function: `ticket-classifier-{tu-id}-ticket-classifier`
- 2 IAM roles
- 3 IAM policies
- 1 CloudWatch Log Group

---

## 🧪 PASO 6: Prueba el pipeline

### Opción A: Script automático
```bash
chmod +x test_pipeline.sh
./test_pipeline.sh
```

### Opción B: Manual
```bash
# Obtener ARN de Step Function
STEP_ARN=$(tofu output -raw step_function_arn)

# Test 1: Ticket urgente
aws stepfunctions start-execution \
  --state-machine-arn $STEP_ARN \
  --input file://tests/test_urgent_ticket.json \
  --name test-urgent-$(date +%s)

# Test 2: Ticket normal
aws stepfunctions start-execution \
  --state-machine-arn $STEP_ARN \
  --input file://tests/test_normal_ticket.json \
  --name test-normal-$(date +%s)

# Test 3: Ticket low
aws stepfunctions start-execution \
  --state-machine-arn $STEP_ARN \
  --input file://tests/test_low_ticket.json \
  --name test-low-$(date +%s)

# Verificar resultados
BUCKET=$(tofu output -raw bucket_name)
aws s3 ls s3://$BUCKET/ --recursive

# Deberías ver:
# urgent/tk-001.json
# normal/tk-002.json
# low/tk-003.json
```

---

## 📊 PASO 7: Verifica que todo funciona

### Checklist de validación:

- [ ] `tofu apply` completó sin errores
- [ ] `tofu output` muestra bucket_name y step_function_arn
- [ ] Puedes ver la Step Function en AWS Console
- [ ] Las 3 Lambdas aparecen en AWS Lambda
- [ ] El bucket S3 existe y tiene carpetas: urgent/, normal/, low/
- [ ] Los 3 tests se ejecutaron exitosamente
- [ ] Los 3 archivos JSON están en las carpetas correctas de S3

### Comandos de verificación:

```bash
# Ver recursos desplegados
aws s3 ls | grep tickets
aws lambda list-functions | grep ticket
aws stepfunctions list-state-machines | grep classifier

# Ver contenido del bucket
aws s3 ls s3://$(tofu output -raw bucket_name)/ --recursive

# Descargar un ticket procesado
aws s3 cp s3://$(tofu output -raw bucket_name)/urgent/tk-001.json - | jq .
```

---

## 📝 PASO 8: Personaliza el README

El README que te di es muy completo, pero deberías:

1. **Cambiar el autor**:
   ```markdown
   ## 👨‍💻 Autor
   **Tu Nombre Completo**
   Matrícula: Tu-Matricula-Real
   ```

2. **Agregar tu repositorio**:
   ```markdown
   **Repositorio**: https://github.com/tu-usuario/ticket-classifier-tofu
   ```

3. **Opcional - Agregar diagrama visual**:
   - Puedes crear un diagrama con draw.io o Lucidchart
   - Exportar como PNG
   - Agregar al README

---

## 🔄 PASO 9: Sube a GitHub

```bash
# Inicializar Git (si no lo has hecho)
git init
git add .
git commit -m "Initial commit - Support Ticket Classifier with OpenTofu"

# Crear repo en GitHub (desde la web)
# Luego:
git remote add origin https://github.com/TU-USUARIO/ticket-classifier-tofu.git
git branch -M main
git push -u origin main
```

---

## 🎓 PASO 10: Prepárate para la defensa oral

### Preguntas que probablemente te harán:

1. **¿Por qué elegiste este escenario?**
   - "Elegí el clasificador de tickets porque simula un problema real de empresas con alto volumen de soporte. Es relevante para mi aprendizaje en data engineering."

2. **Explica el flujo de datos**
   - "El ticket entra como JSON → Lambda 1 valida campos → Lambda 2 analiza prioridad y keywords → Choice decide la ruta → Lambda 3 guarda en S3/urgent o /normal o /low"

3. **¿Qué pasa si un campo falta?**
   - "Lambda 1 lanza ValueError → Step Function Catch lo captura → Va a estado ValidationFailed (Fail state)"

4. **¿Cómo clasificas un ticket como urgente?**
   - "Si priority_score >= 70 O si contiene palabras clave como 'urgent', 'down', 'critical', etc. Es un OR lógico."

5. **¿Por qué usaste 3 Lambdas separadas?**
   - "Separación de responsabilidades. Cada Lambda tiene un propósito claro. Facilita testing, debugging y reutilización. Sigue principios SOLID."

6. **¿Qué modificarías en el IAM?**
   - "El rol actual sigue mínimo privilegio - solo acceso al bucket específico. En producción agregaría KMS para cifrado, y separaría roles por Lambda."

7. **¿Cómo escalarías esto?**
   - "Para millones de tickets: agregar SQS como buffer, DynamoDB para índices, SNS para notificaciones de urgentes, EventBridge para scheduling."

---

## 🧹 PASO 11: IMPORTANTE - Limpia antes de la defensa

```bash
# Eliminar toda la infraestructura
tofu destroy
# Escribir: yes

# Verificar que todo se eliminó
aws s3 ls | grep tickets          # Debe estar vacío
aws lambda list-functions | grep ticket  # Debe estar vacío

# Si te penalizan 10 puntos por dejar recursos corriendo!
```

**Re-desplegar para la defensa:**
```bash
tofu apply
# Toma 2-3 minutos
```

---

## 🎯 Criterios de Evaluación

### Funcional IaC code (15 pts)
✅ **Tu código cumple**: `tofu apply` despliega todo, `tofu destroy` limpia todo

### Coherent business logic (15 pts)  
✅ **Tu código cumple**: La clasificación de tickets tiene reglas de negocio reales

### Python code quality (10 pts)
✅ **Tu código cumple**: Try-catch, logging, validaciones, comentarios útiles

### Folder structure (10 pts)
✅ **Tu código cumple**: Estructura idéntica a la de clase, módulos reutilizables

### README quality (10 pts)
✅ **Tu código cumple**: >200 palabras, diagramas, ejemplos, instrucciones completas

**Total potencial**: 60/60 puntos base + oral defense

---

## 📚 Recursos para Estudiar

Antes de la defensa, lee:

1. **Tu propio código**: Entiende CADA línea
2. **AWS Step Functions ASL**: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html
3. **Choice state**: https://docs.aws.amazon.com/step-functions/latest/dg/amazon-states-language-choice-state.html
4. **Lambda best practices**: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html

---

## 💡 Tips Finales

1. **Entiende el código**: Si copias algo que no entiendes, lo detectarán en la oral
2. **Prueba varias veces**: Ejecuta los 3 casos de test múltiples veces
3. **Lee los logs**: Familiarízate con CloudWatch Logs
4. **Modifica algo**: Cambia una palabra clave, ajusta un threshold, para demostrar comprensión
5. **Ten métricas**: Cuánto tardó cada ejecución, cuántos tickets de cada tipo

---

## ✅ Checklist Final

Antes de entregar:

- [ ] Código funciona localmente
- [ ] Los 3 tests pasan
- [ ] README >200 palabras
- [ ] Repo público en GitHub
- [ ] terraform.tfvars en .gitignore
- [ ] CI/CD configurado (opcional)
- [ ] Screenshots de ejecuciones exitosas
- [ ] Recursos limpiados con `tofu destroy`
- [ ] Entiendes cada línea de código
- [ ] Puedes explicar las decisiones de arquitectura

---

## 🆘 Si tienes problemas

**Error común 1**: "Bucket already exists"
```bash
# Solución: Cambiar student_id
student_id = "tu-id-v2"
```

**Error común 2**: "Permission denied"
```bash
# Solución: Revisar permisos IAM de tu usuario AWS
aws iam get-user
```

**Error común 3**: Lambda timeout
```bash
# Solución: Ya está en 10-15 segundos, suficiente para estas operaciones
```

---

## 📞 Contacto

Si tienes dudas específicas sobre el código que te generé, puedes:
1. Revisar los comentarios en el código (están muy documentados)
2. Consultar el README (tiene ejemplos detallados)
3. Leer el QUICKSTART.md (troubleshooting)

---

**¡Mucha suerte con tu tarea! 🚀**

Recuerda: Lo más importante es que ENTIENDAS el código. La oral defense está diseñada precisamente para detectar si lo entiendes o solo lo copiaste.
