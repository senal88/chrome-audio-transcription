#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Chrome Audio Dashboard
# @raycast.mode silent
# @raycast.packageName Audio Transcription

# Optional parameters:
# @raycast.icon 🎙️
# @raycast.description Abrir dashboard de áudio/transcrição local

set -e

# PATH HOMEBREW (APPLE SILICON)
eval "$(/opt/homebrew/bin/brew shellenv)"

# ROOT DO PROJETO
PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
LOG_DIR="$PROJECT_ROOT/logs"

# SUBIR DASHBOARD SE NÃO ESTIVER RODANDO
if ! lsof -i :8000 >/dev/null 2>&1; then
  nohup uvicorn app:app \
    --host 127.0.0.1 \
    --port 8000 \
    --app-dir "$PROJECT_ROOT/dashboard" \
    > "$LOG_DIR/dashboard.log" 2>&1 &
  sleep 1
fi

# ABRIR DASHBOARD
open "http://127.0.0.1:8000"
