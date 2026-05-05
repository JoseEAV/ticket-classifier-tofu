# 🚀 Guía Rápida de Inicio

## Setup Inicial (5 minutos)

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/ticket-classifier-tofu.git
cd ticket-classifier-tofu
```

### 2. Crear terraform.tfvars
```bash
cat > terraform.tfvars <<EOF
student_id   = "TU-MATRICULA"
project_name = "ticket-classifier"
aws_region   = "us-east-1"
EOF
```

### 3. Configurar AWS CLI (si no lo has hecho)
```bash
aws configure
# Ingresa tu Access Key ID
# Ingresa tu Secret Access Key
# Región: us-east-1
# Formato: json
```

---

## Despliegue (3 minutos)

```bash
# Inicializar
tofu init

# Ver plan
tofu plan

# Desplegar
tofu apply
# Escribir: yes
```

---

## Probar el Pipeline (2 minutos)

### Opción 1: Script automático
```bash
chmod +x test_pipeline.sh
./test_pipeline.sh
```

### Opción 2: Manual
```bash
# Obtener ARN
STEP_ARN=$(tofu output -raw step_function_arn)

# Ejecutar test urgente
aws stepfunctions start-execution \
  --state-machine-arn $STEP_ARN \
  --input file://tests/test_urgent_ticket.json \
  --name test-urgent-$(date +%s)

# Ver resultados
aws s3 ls s3://$(tofu output -raw bucket_name)/ --recursive
```

---

## Verificar Resultados

```bash
# Ver archivo procesado
BUCKET=$(tofu output -raw bucket_name)
aws s3 cp s3://$BUCKET/urgent/tk-001.json -

# Ver logs
aws logs tail /aws/stepfunctions/$BUCKET --follow
```

---

## Limpiar (IMPORTANTE - antes de la defensa)

```bash
# Eliminar todos los recursos
tofu destroy
# Escribir: yes

# Verificar
aws s3 ls | grep tickets  # Debe estar vacío
```

---

## Troubleshooting

### Error: "No valid credential sources found"
```bash
aws configure
# Volver a ingresar credenciales
```

### Error: "Bucket already exists"
```bash
# Cambiar student_id en terraform.tfvars
student_id = "TU-MATRICULA-v2"
```

### Error: Lambda execution failed
```bash
# Ver logs de CloudWatch
aws logs tail /aws/lambda/ticket-classifier-TU-ID-validate-ticket
```

### Ver estado de Step Function
```bash
# Listar ejecuciones recientes
aws stepfunctions list-executions \
  --state-machine-arn $(tofu output -raw step_function_arn) \
  --max-results 5
```

---

## Estructura de Carpetas Esperada

```
ticket-classifier-tofu/
├── lambdas/
│   ├── validate_ticket/
│   │   └── lambda_function.py
│   ├── classify_ticket/
│   │   └── lambda_function.py
│   └── route_ticket/
│       └── lambda_function.py
├── modules/
│   └── lambda_function/
├── tests/
│   ├── test_urgent_ticket.json
│   ├── test_normal_ticket.json
│   └── test_low_ticket.json
├── main.tf
├── step_function.tf
├── iam.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## Comandos Útiles

### Ver outputs
```bash
tofu output
```

### Ver estado
```bash
tofu show
```

### Refrescar estado
```bash
tofu refresh
```

### Formatear código
```bash
tofu fmt -recursive
```

### Validar configuración
```bash
tofu validate
```

---

## Checklist para la Defensa Oral

- [ ] Código desplegado y funcionando
- [ ] 3 pruebas ejecutadas exitosamente
- [ ] README de mínimo 200 palabras ✓
- [ ] Recursos limpiados con `tofu destroy`
- [ ] Repositorio público en GitHub
- [ ] CI/CD configurado (opcional)
- [ ] Entender cada línea de código

---

## Preguntas Frecuentes en la Defensa

**P: ¿Por qué usaste 3 Lambdas en lugar de 1?**
R: Separación de responsabilidades - cada Lambda tiene una función específica (validar, clasificar, enrutar). Esto facilita mantenimiento, testing y reutilización.

**P: ¿Qué pasa si el bucket ya existe?**
R: Terraform/OpenTofu falla. Solución: cambiar student_id o usar `tofu import` para importar el bucket existente.

**P: ¿Cómo manejas errores?**
R: Validaciones con raise ValueError en Python, estado Catch en Step Function que lleva a ValidationFailed, logs en CloudWatch.

**P: ¿Cuánto cuesta esto en producción?**
R: Para uso ligero (<1000 ejecuciones/día): ~$1/mes. Lambda y Step Functions tienen free tier generoso.

**P: ¿Por qué Choice en lugar de Lambda?**
R: Choice es declarativo y más eficiente para routing simple. Lambda solo para lógica compleja.
