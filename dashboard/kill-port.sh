#!/bin/zsh
# Script para matar todos os processos na porta 8000

PORT=${1:-8000}

echo "🔍 Verificando processos na porta $PORT..."

PIDS=$(lsof -ti:$PORT 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "✓ Porta $PORT está livre"
    exit 0
fi

PID_COUNT=$(echo "$PIDS" | wc -l | tr -d ' ')
echo "⚠️  Encontrados $PID_COUNT processo(s) na porta $PORT:"
echo "$PIDS" | xargs ps -p 2>/dev/null | grep -v PID || echo "   PIDs: $PIDS"
echo ""
echo -n "Deseja matar todos os processos? (y/N) "
read -r REPLY

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$PIDS" | xargs kill -9 2>/dev/null || true
    sleep 1
    
    # Verificar novamente
    if lsof -ti:$PORT > /dev/null 2>&1; then
        echo "⚠️  Ainda há processos, tentando novamente..."
        lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    if lsof -ti:$PORT > /dev/null 2>&1; then
        echo "❌ Não foi possível liberar a porta $PORT"
        exit 1
    else
        echo "✓ Porta $PORT liberada com sucesso"
    fi
else
    echo "❌ Abortado"
    exit 1
fi
