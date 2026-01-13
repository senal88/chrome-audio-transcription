#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Transcrever Último Áudio
# @raycast.mode silent
# @raycast.packageName Audio Transcription

# Optional parameters:
# @raycast.icon 📝
# @raycast.description Transcrever o áudio mais recente

set -e

eval "$(/opt/homebrew/bin/brew shellenv)"

PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
source "$PROJECT_ROOT/.env"

# Pegar último arquivo de áudio
LATEST=$(ls -t "$AUDIO_RAW_DIR"/*.mp3 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
    osascript -e 'display notification "Nenhum áudio encontrado" with title "Chrome Audio"'
    exit 1
fi

osascript -e 'display notification "Transcrevendo..." with title "Chrome Audio"'

whisper "$LATEST" \
    --language "$LANGUAGE" \
    --model "$WHISPER_MODEL" \
    --output_dir "$TRANSCRIPT_TXT_DIR" \
    --output_format all \
    --verbose False \
    --fp16 False

osascript -e 'display notification "Transcrição concluída!" with title "Chrome Audio"'

# Abrir dashboard
open "http://127.0.0.1:8000"
