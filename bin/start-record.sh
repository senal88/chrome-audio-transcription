#!/bin/zsh
set -e

eval "$(/opt/homebrew/bin/brew shellenv)"

PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
AUDIO_DIR="$PROJECT_ROOT/audio/raw"
LOG_DIR="$PROJECT_ROOT/logs"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$AUDIO_DIR/chrome_$TIMESTAMP.mp3"
PID_FILE="$PROJECT_ROOT/tmp/record.pid"

mkdir -p "$AUDIO_DIR" "$PROJECT_ROOT/tmp" "$LOG_DIR"

ffmpeg -f avfoundation \
  -i ":BlackHole 2ch" \
  -ac 2 -ar 44100 -ab 192k \
  "$OUTPUT_FILE" \
  > "$LOG_DIR/record.log" 2>&1 &

echo $! > "$PID_FILE"

echo "RECORDING_STARTED $OUTPUT_FILE"
