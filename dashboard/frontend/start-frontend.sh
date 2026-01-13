#!/bin/zsh
# Script para iniciar apenas o frontend

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm install
fi

echo "🚀 Iniciando frontend React..."
echo "📍 http://localhost:5173"
echo ""

npm run dev
