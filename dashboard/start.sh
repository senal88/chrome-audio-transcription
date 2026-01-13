#!/bin/zsh
# Script para iniciar o dashboard completo

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"
FRONTEND_DIR="$DASHBOARD_DIR/frontend"

echo "🚀 Iniciando Chrome Audio Transcription Dashboard"
echo ""

# Verificar se porta 8000 está em uso
if lsof -ti:8000 > /dev/null 2>&1; then
    echo "⚠️  Porta 8000 já está em uso!"
    echo "   Processo usando a porta:"
    lsof -ti:8000 | xargs ps -p
    echo ""
    read "?Deseja matar o processo e continuar? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lsof -ti:8000 | xargs kill -9 2>/dev/null || true
        echo "✓ Processo finalizado"
        sleep 1
    else
        echo "❌ Abortado. Libere a porta 8000 manualmente."
        exit 1
    fi
fi

# Verificar dependências do backend
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📦 Instalando dependências do backend..."
    cd "$DASHBOARD_DIR"
    pip install -r requirements.txt
fi

# Verificar dependências do frontend
if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    echo "📦 Instalando dependências do frontend..."
    cd "$FRONTEND_DIR"
    npm install
fi

echo ""
echo "✅ Dependências verificadas"
echo ""
echo "📋 Para iniciar o dashboard:"
echo ""
echo "   Terminal 1 - Backend:"
echo "   cd $DASHBOARD_DIR"
echo "   python app.py"
echo ""
echo "   Terminal 2 - Frontend:"
echo "   cd $FRONTEND_DIR"
echo "   npm run dev"
echo ""
echo "   Acesse: http://localhost:5173"
echo ""
