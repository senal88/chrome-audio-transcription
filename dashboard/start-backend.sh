#!/bin/zsh
# Script para iniciar apenas o backend

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar se porta 8000 está em uso
if lsof -ti:8000 > /dev/null 2>&1; then
    PIDS=$(lsof -ti:8000)
    PID_COUNT=$(echo "$PIDS" | wc -l | tr -d ' ')
    echo "⚠️  Porta 8000 já está em uso por $PID_COUNT processo(s):"
    echo "$PIDS" | xargs ps -p 2>/dev/null | grep -v PID || echo "   PIDs: $PIDS"
    echo ""
    echo -n "Deseja matar todos os processos e continuar? (y/N) "
    read -r REPLY
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        echo "✓ Processos finalizados"
        # Aguardar liberação da porta
        sleep 2
        # Verificar novamente
        if lsof -ti:8000 > /dev/null 2>&1; then
            echo "⚠️  Porta ainda em uso, tentando novamente..."
            sleep 1
            lsof -ti:8000 | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
        if lsof -ti:8000 > /dev/null 2>&1; then
            echo "❌ Não foi possível liberar a porta 8000"
            echo "   Execute manualmente: kill -9 \$(lsof -ti:8000)"
            exit 1
        fi
        echo "✓ Porta 8000 liberada"
    else
        echo "❌ Abortado. Libere a porta 8000 manualmente:"
        echo "   kill -9 \$(lsof -ti:8000)"
        exit 1
    fi
fi

# Verificar dependências
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📦 Instalando dependências..."
    python3 -m pip install -q -r requirements.txt
fi

echo "🚀 Iniciando backend FastAPI..."
echo "📍 http://localhost:8000"
echo ""

python app.py
