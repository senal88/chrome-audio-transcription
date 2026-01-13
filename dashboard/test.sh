#!/bin/zsh
# Script de teste completo do dashboard

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"
FRONTEND_DIR="$DASHBOARD_DIR/frontend"

echo "🧪 Testando Chrome Audio Transcription Dashboard"
echo "================================================"
echo ""

# Teste 1: Verificar estrutura de diretórios
echo "1️⃣  Verificando estrutura de diretórios..."
test -d "$DASHBOARD_DIR" && echo "   ✓ dashboard/ existe" || (echo "   ✗ dashboard/ não existe" && exit 1)
test -d "$FRONTEND_DIR" && echo "   ✓ dashboard/frontend/ existe" || (echo "   ✗ dashboard/frontend/ não existe" && exit 1)
test -f "$DASHBOARD_DIR/app.py" && echo "   ✓ app.py existe" || (echo "   ✗ app.py não existe" && exit 1)
test -f "$FRONTEND_DIR/package.json" && echo "   ✓ package.json existe" || (echo "   ✗ package.json não existe" && exit 1)
echo ""

# Teste 2: Verificar sintaxe Python
echo "2️⃣  Verificando sintaxe Python..."
python3 -m py_compile "$DASHBOARD_DIR/app.py" 2>&1 && echo "   ✓ app.py tem sintaxe válida" || (echo "   ✗ Erro de sintaxe em app.py" && exit 1)
echo ""

# Teste 3: Verificar dependências Python
echo "3️⃣  Verificando dependências Python..."
python3 -c "import fastapi, uvicorn" 2>&1 && echo "   ✓ Dependências Python instaladas" || (echo "   ⚠️  Dependências Python não encontradas (execute: pip install -r requirements.txt)" && exit 1)
echo ""

# Teste 4: Verificar sintaxe dos scripts shell
echo "4️⃣  Verificando sintaxe dos scripts shell..."
bash -n "$DASHBOARD_DIR/start-backend.sh" 2>&1 && echo "   ✓ start-backend.sh válido" || (echo "   ✗ Erro em start-backend.sh" && exit 1)
bash -n "$DASHBOARD_DIR/start.sh" 2>&1 && echo "   ✓ start.sh válido" || (echo "   ✗ Erro em start.sh" && exit 1)
bash -n "$FRONTEND_DIR/start-frontend.sh" 2>&1 && echo "   ✓ start-frontend.sh válido" || (echo "   ✗ Erro em start-frontend.sh" && exit 1)
echo ""

# Teste 5: Verificar dependências Node.js
echo "5️⃣  Verificando dependências Node.js..."
if [ -d "$FRONTEND_DIR/node_modules" ]; then
    echo "   ✓ node_modules existe"
else
    echo "   ⚠️  node_modules não existe (execute: cd frontend && npm install)"
fi
echo ""

# Teste 6: Verificar build do frontend
echo "6️⃣  Verificando build do frontend..."
cd "$FRONTEND_DIR"
if npm run build > /dev/null 2>&1; then
    echo "   ✓ Build do frontend OK"
else
    echo "   ⚠️  Build do frontend falhou (pode precisar de npm install)"
fi
echo ""

# Teste 7: Verificar portas
echo "7️⃣  Verificando portas..."
PORT_8000=$(lsof -ti:8000 2>/dev/null | wc -l | tr -d ' ')
PORT_5173=$(lsof -ti:5173 2>/dev/null | wc -l | tr -d ' ')

if [ "$PORT_8000" -gt 0 ]; then
    echo "   ⚠️  Porta 8000 em uso ($PORT_8000 processo(s))"
    echo "      Use: kill -9 \$(lsof -ti:8000)"
else
    echo "   ✓ Porta 8000 livre"
fi

if [ "$PORT_5173" -gt 0 ]; then
    echo "   ⚠️  Porta 5173 em uso ($PORT_5173 processo(s))"
    echo "      Use: kill -9 \$(lsof -ti:5173)"
else
    echo "   ✓ Porta 5173 livre"
fi
echo ""

echo "✅ Testes concluídos!"
echo ""
echo "Para iniciar o dashboard:"
echo "  Terminal 1: cd dashboard && ./start-backend.sh"
echo "  Terminal 2: cd dashboard/frontend && ./start-frontend.sh"
echo ""
