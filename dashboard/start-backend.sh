#!/bin/zsh
# Script para iniciar apenas o backend

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar se porta 8000 está em uso
if lsof -ti:8000 > /dev/null 2>&1; then
    PID=$(lsof -ti:8000 | head -1)
    echo "⚠️  Porta 8000 já está em uso pelo processo $PID"
    echo ""
    read "?Deseja matar o processo e continuar? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill -9 $PID 2>/dev/null || true
        echo "✓ Processo finalizado"
        sleep 1
    else
        echo "❌ Abortado. Libere a porta 8000 manualmente."
        exit 1
    fi
fi

# Verificar dependências
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📦 Instalando dependências..."
    pip install -r requirements.txt
fi

echo "🚀 Iniciando backend FastAPI..."
echo "📍 http://localhost:8000"
echo ""

python app.py
