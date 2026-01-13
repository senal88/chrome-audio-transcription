#!/bin/zsh
set -e

PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
PID_FILE="$PROJECT_ROOT/tmp/record.pid"
LOG_DIR="$PROJECT_ROOT/logs"
TRANSCRIPTS_DIR="$PROJECT_ROOT/transcripts"

if [ ! -f "$PID_FILE" ]; then
  echo "NO_ACTIVE_RECORDING"
  exit 1
fi

PID=$(cat "$PID_FILE")
kill -INT "$PID"
rm "$PID_FILE"

LAST_AUDIO=$(ls -t "$PROJECT_ROOT/audio/raw"/*.mp3 | head -n 1)

whisper "$LAST_AUDIO" \
  --language pt \
  --model medium \
  --task transcribe \
  --output_dir "$TRANSCRIPTS_DIR" \
  --output_format txt \
  --output_format srt \
  --output_format vtt \
  >> "$LOG_DIR/transcribe.log" 2>&1

echo "RECORDING_STOPPED_AND_TRANSCRIBED $LAST_AUDIO"
