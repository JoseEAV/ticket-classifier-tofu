#!/bin/bash

# Script de configuración automática de Git
# Para el proyecto ticket-classifier-tofu

echo "🚀 Configuración automática de Git para ticket-classifier-tofu"
echo ""

# Verificar que estamos en la carpeta correcta
if [ ! -f "main.tf" ] || [ ! -f "step_function.tf" ]; then
    echo "❌ Error: No estás en la carpeta del proyecto"
    echo "Por favor ejecuta este script desde la carpeta ticket-classifier-tofu"
    exit 1
fi

echo "✅ Carpeta del proyecto detectada"
echo ""

# Verificar que terraform.tfvars existe
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars no encontrado. Creando..."
    cat > terraform.tfvars <<'EOF'
student_id   = "TU-MATRICULA-AQUI"
project_name = "ticket-classifier"
aws_region   = "us-east-1"
EOF
    echo "📝 Archivo terraform.tfvars creado"
    echo "⚠️  IMPORTANTE: Edita terraform.tfvars y cambia TU-MATRICULA-AQUI"
    echo ""
fi

# Inicializar Git si no está inicializado
if [ ! -d ".git" ]; then
    echo "📦 Inicializando repositorio Git..."
    git init
    echo "✅ Git inicializado"
else
    echo "✅ Repositorio Git ya existe"
fi

echo ""

# Agregar archivos
echo "📁 Agregando archivos al staging area..."
git add .

# Mostrar estado
echo ""
echo "📋 Estado actual:"
git status --short

echo ""

# Preguntar si hacer commit
read -p "¿Hacer commit inicial? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "💾 Creando commit inicial..."
    git commit -m "Initial commit: Support Ticket Classifier con OpenTofu

- Pipeline de clasificación de tickets con 3 Lambdas
- Step Function con Choice state (7 estados, 3 branches)
- Tests automatizados para casos urgent/normal/low
- CI/CD con GitHub Actions
- Documentación completa >3000 palabras
- Escenario C: Support Ticket Classifier"
    
    echo "✅ Commit creado"
    echo ""
    git log --oneline -1
fi

echo ""
echo "📌 Siguiente paso: Crear repositorio en GitHub"
echo ""
echo "1. Ve a https://github.com/new"
echo "2. Repository name: ticket-classifier-tofu"
echo "3. Público ✓"
echo "4. NO inicialices con README"
echo "5. Crea el repositorio"
echo ""

read -p "¿Ya creaste el repositorio en GitHub? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    read -p "Ingresa tu usuario de GitHub: " github_user
    
    # Configurar remote
    git remote remove origin 2>/dev/null
    git remote add origin "https://github.com/${github_user}/ticket-classifier-tofu.git"
    
    # Renombrar rama a main
    git branch -M main
    
    echo "✅ Remote configurado: https://github.com/${github_user}/ticket-classifier-tofu.git"
    echo ""
    echo "🚀 Para subir a GitHub, ejecuta:"
    echo "   git push -u origin main"
    echo ""
    echo "⚠️  Si te pide contraseña, necesitas un Personal Access Token:"
    echo "   https://github.com/settings/tokens"
fi

echo ""
echo "✅ ¡Configuración completa!"
echo ""
echo "📚 Próximos pasos:"
echo "   1. git push -u origin main"
echo "   2. Configurar Secrets en GitHub (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, STUDENT_ID)"
echo "   3. tofu init && tofu apply (probar localmente)"
echo ""
