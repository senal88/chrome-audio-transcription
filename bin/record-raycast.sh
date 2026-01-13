#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Gravar Chrome Audio
# @raycast.mode silent
# @raycast.packageName Audio Transcription

# Optional parameters:
# @raycast.icon 🔴
# @raycast.description Iniciar gravação de áudio do sistema (60s)
# @raycast.argument1 { "type": "text", "placeholder": "duração (s)", "optional": true }

set -e

eval "$(/opt/homebrew/bin/brew shellenv)"

PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
source "$PROJECT_ROOT/.env"

DURATION="${1:-60}"
OUTPUT_FILE="$AUDIO_RAW_DIR/chrome_$(date +%Y%m%d_%H%M%S).mp3"

osascript -e 'display notification "Gravando por '$DURATION's..." with title "Chrome Audio"'

ffmpeg -y -f avfoundation -i ":$AUDIO_DEVICE" \
    -ac 2 -ar 44100 -ab 192k \
    -t "$DURATION" \
    "$OUTPUT_FILE" 2>/dev/null

osascript -e 'display notification "Gravação salva!" with title "Chrome Audio"'
