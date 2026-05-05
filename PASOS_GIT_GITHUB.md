# 🚀 GUÍA COMPLETA: Configurar Git y GitHub

## ✅ Tu proyecto YA ESTÁ ORGANIZADO

Descarga la carpeta `proyecto-final-organizado` que te acabo de preparar.

**Contiene TODO:**
- ✅ 3 Lambdas en Python (validate, classify, route)
- ✅ Archivos Terraform (main.tf, step_function.tf, iam.tf, variables.tf, outputs.tf)
- ✅ Módulo lambda_function completo
- ✅ 3 tests JSON
- ✅ GitHub Actions workflow
- ✅ Documentación completa
- ✅ .gitignore configurado

---

## 📋 PASO 1: Mover el proyecto a tu Mac

```bash
# Ir a Desktop
cd ~/Desktop

# Si ya tienes una carpeta ticket-classifier-tofu, renómbrala
mv ticket-classifier-tofu ticket-classifier-tofu-old 2>/dev/null

# Copiar la carpeta descargada y renombrarla
# (Ajusta la ruta según dónde descargaste proyecto-final-organizado)
cp -r ~/Downloads/proyecto-final-organizado ticket-classifier-tofu

# O arrastra la carpeta con Finder al Desktop y renómbrala a:
# ticket-classifier-tofu

# Ir al proyecto
cd ticket-classifier-tofu

# Verificar que todo está
ls -la
```

---

## 📋 PASO 2: Crear archivo terraform.tfvars

```bash
# Crear el archivo (NO se sube a Git)
cat > terraform.tfvars <<'EOF'
student_id   = "TU-MATRICULA-AQUI"
project_name = "ticket-classifier"
aws_region   = "us-east-1"
EOF

# Reemplazar TU-MATRICULA-AQUI con tu matrícula real
# Ejemplo: nano terraform.tfvars
# O ábrelo con cualquier editor y edita la línea
```

**⚠️ IMPORTANTE:** Este archivo NO debe subirse a GitHub (ya está en .gitignore)

---

## 📋 PASO 3: Configurar AWS CLI (si no lo has hecho)

```bash
# Configurar credenciales AWS
aws configure

# Te pedirá:
# AWS Access Key ID: [pegar tu key]
# AWS Secret Access Key: [pegar tu secret]
# Default region name: us-east-1
# Default output format: json

# Verificar que funciona
aws sts get-caller-identity
```

---

## 📋 PASO 4: Inicializar Git en tu proyecto

```bash
# Asegúrate de estar en la carpeta del proyecto
cd ~/Desktop/ticket-classifier-tofu

# Inicializar repositorio Git
git init

# Verificar archivos
git status

# Agregar todos los archivos
git add .

# Hacer el primer commit
git commit -m "Initial commit: Support Ticket Classifier con OpenTofu

- Pipeline de clasificación de tickets con 3 Lambdas
- Step Function con Choice state (7 estados, 3 branches)
- Tests automatizados para casos urgent/normal/low
- CI/CD con GitHub Actions
- Documentación completa >3000 palabras
- Escenario C: Support Ticket Classifier"

# Verificar que se hizo el commit
git log --oneline
```

---

## 📋 PASO 5: Crear repositorio en GitHub

### 5.1 Desde la web de GitHub:

1. Ve a https://github.com
2. Click en **+** (arriba derecha) → **New repository**
3. Configuración:
   - **Repository name**: `ticket-classifier-tofu`
   - **Description**: `Sistema de clasificación automática de tickets de soporte con OpenTofu y AWS Step Functions - UAG`
   - **Public** ✓ (debe ser público para la tarea)
   - **NO** marques "Initialize with README"
   - **NO** agregues .gitignore ni licencia
4. Click **Create repository**

---

## 📋 PASO 6: Conectar tu repo local con GitHub

GitHub te mostrará comandos. Ignóralos y usa estos:

```bash
# Conectar con el repo remoto (reemplaza TU-USUARIO)
git remote add origin https://github.com/TU-USUARIO/ticket-classifier-tofu.git

# Verificar
git remote -v

# Renombrar rama a main
git branch -M main

# Subir a GitHub
git push -u origin main
```

### Si te pide usuario/contraseña:

GitHub ya no acepta contraseñas. Necesitas un **Personal Access Token (PAT)**.

---

## 🔑 PASO 7: Crear Personal Access Token

1. Ve a GitHub → **Settings** (tu perfil)
2. Scroll hasta abajo → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token (classic)**
5. Configuración:
   - **Note**: `Token para ticket-classifier-tofu`
   - **Expiration**: `90 days`
   - **Select scopes**:
     - ✅ `repo` (todos los sub-items)
     - ✅ `workflow`
6. **Generate token**
7. **COPIAR EL TOKEN** (solo se muestra una vez)

### Usar el token:

```bash
# Cuando hagas push y pida contraseña:
git push -u origin main

# Username: TU-USUARIO-GITHUB
# Password: [pega el token aquí]

# Para guardar el token y no ingresarlo siempre:
git config credential.helper store
```

---

## 📋 PASO 8: Configurar GitHub Actions

### 8.1 Agregar Secrets al repositorio:

1. Ve a tu repo en GitHub
2. **Settings** (del repo)
3. **Secrets and variables** → **Actions**
4. **New repository secret**

**Crear estos 3 secrets:**

#### Secret 1:
- Name: `AWS_ACCESS_KEY_ID`
- Value: [Tu AWS Access Key ID]
- Click **Add secret**

#### Secret 2:
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: [Tu AWS Secret Access Key]
- Click **Add secret**

#### Secret 3:
- Name: `STUDENT_ID`
- Value: [Tu matrícula] (ejemplo: `301234567`)
- Click **Add secret**

### 8.2 Configurar Environment para aprobación manual:

1. En GitHub → **Settings** (del repo)
2. **Environments**
3. **New environment**
4. Name: `production`
5. ✅ **Required reviewers** → Agrégarte
6. **Save protection rules**

---

## 📋 PASO 9: Probar localmente ANTES de GitHub Actions

```bash
cd ~/Desktop/ticket-classifier-tofu

# Inicializar OpenTofu/Terraform
tofu init

# Si no tienes tofu, usa terraform:
terraform init

# Validar configuración
tofu validate

# Ver el plan
tofu plan

# Si todo se ve bien, desplegar
tofu apply
# Escribir: yes

# Probar el pipeline
chmod +x test_pipeline.sh
./test_pipeline.sh

# Limpiar (IMPORTANTE antes de la defensa)
tofu destroy
# Escribir: yes
```

---

## 📋 PASO 10: Actualizar README con tu información

```bash
# Editar README.md
nano README.md

# O abrirlo con cualquier editor

# Buscar la sección "Autor" y cambiar:
## 👨‍💻 Autor
**Tu Nombre Completo**
Matrícula: Tu-Matricula
Universidad Autónoma de Guadalajara
AWS Academy Data Engineering - Módulo 12

# Guardar y cerrar

# Hacer commit del cambio
git add README.md
git commit -m "Actualizar información del autor"
git push
```

---

## 📋 PASO 11: Workflow normal de trabajo

### Cuando necesites hacer cambios:

```bash
# 1. Crear una rama
git checkout -b feature/nombre-del-cambio

# 2. Hacer tus cambios
# (editar archivos...)

# 3. Commit
git add .
git commit -m "Descripción clara del cambio"

# 4. Push
git push -u origin feature/nombre-del-cambio

# 5. En GitHub:
# - Crear Pull Request
# - Revisar el Terraform Plan en los comentarios
# - Merge a main

# 6. GitHub Actions desplegará automáticamente
# (después de tu aprobación manual)
```

---

## ✅ CHECKLIST FINAL

Antes de entregar:

- [ ] Proyecto descargado y renombrado a `ticket-classifier-tofu`
- [ ] `terraform.tfvars` creado con tu matrícula
- [ ] AWS CLI configurado
- [ ] Git inicializado con commit
- [ ] Repo creado en GitHub (público)
- [ ] Repo local conectado con GitHub
- [ ] Código subido a GitHub (`git push`)
- [ ] Secrets configurados en GitHub:
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] STUDENT_ID
- [ ] Environment `production` creado
- [ ] `tofu apply` funciona localmente
- [ ] Tests pasan correctamente
- [ ] README actualizado con tu nombre
- [ ] `tofu destroy` ejecutado antes de entregar

---

## 🆘 Comandos útiles

```bash
# Ver estado de Git
git status

# Ver historial
git log --oneline

# Ver diferencias
git diff

# Deshacer cambios no guardados
git checkout -- archivo.tf

# Ver configuración de Git
git config --list

# Ver remotes
git remote -v

# Actualizar desde GitHub
git pull

# Ver ramas
git branch -a
```

---

## 🐛 Troubleshooting

### Error: "Permission denied (publickey)"
```bash
git remote set-url origin https://github.com/TU-USUARIO/ticket-classifier-tofu.git
```

### Error: "fatal: not a git repository"
```bash
git init
```

### Error: Token expiró
- Generar nuevo token en GitHub
- `git push` y pegar el nuevo token

### Error: "terraform: command not found"
```bash
# Usar tofu en vez de terraform
tofu init
tofu apply
```

---

## 📞 Resumen de URLs importantes

- **Tu repo**: https://github.com/TU-USUARIO/ticket-classifier-tofu
- **GitHub Settings**: https://github.com/settings/profile
- **Crear PAT**: https://github.com/settings/tokens
- **AWS Console**: https://console.aws.amazon.com

---

## 🎯 Próximos pasos después de configurar Git:

1. ✅ Probar localmente con `tofu apply`
2. ✅ Ejecutar los 3 tests
3. ✅ Verificar que funciona en AWS Console
4. ✅ Hacer `tofu destroy`
5. ✅ Prepararte para la defensa oral

**¡Éxito! 🚀**
