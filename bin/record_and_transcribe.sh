#!/bin/zsh
# ============================================================================
# GRAVAÇÃO E TRANSCRIÇÃO AUTOMÁTICA - macOS Silicon
# Pipeline completo: BlackHole → FFmpeg → MP3 → Whisper → TXT/SRT/VTT
# ============================================================================

set -e

# Carregar .env com paths absolutos
source "/Users/luiz.sena88/Projects/chrome-audio-transcription/.env"

# Fallbacks (caso .env não exista)
AUDIO_RAW_DIR="${AUDIO_RAW_DIR:-$PROJECT_ROOT/audio/raw}"
AUDIO_PROCESSED_DIR="${AUDIO_PROCESSED_DIR:-$PROJECT_ROOT/audio/processed}"
TRANSCRIPT_TXT_DIR="${TRANSCRIPT_TXT_DIR:-$PROJECT_ROOT/transcripts/txt}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/logs}"
LANGUAGE="${LANGUAGE:-pt}"
WHISPER_MODEL="${WHISPER_MODEL:-medium}"
AUDIO_DEVICE="${AUDIO_DEVICE:-BlackHole 2ch}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo "${BLUE}============================================================${NC}"
    echo "${BLUE}  $1${NC}"
    echo "${BLUE}============================================================${NC}"
    echo ""
}

print_success() { echo "${GREEN}✓ $1${NC}"; }
print_warning() { echo "${YELLOW}⚠ $1${NC}"; }
print_error() { echo "${RED}✗ $1${NC}"; }
print_info() { echo "${BLUE}ℹ $1${NC}"; }

# ============================================================================
# LISTAR DISPOSITIVOS DE ÁUDIO
# ============================================================================
list_audio_devices() {
    print_header "DISPOSITIVOS DE ÁUDIO DISPONÍVEIS"
    print_info "Listando dispositivos AVFoundation..."
    echo ""
    ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -E "^\[AVFoundation" | grep -E "(audio|Audio)" || true
    echo ""
    print_info "Procure por 'BlackHole 2ch' ou similar na lista acima"
    echo ""
}

# ============================================================================
# GRAVAR ÁUDIO
# ============================================================================
record_audio() {
    local output_file="$1"
    local duration="${2:-0}"  # 0 = sem limite (Ctrl+C para parar)
    local device="${3:-:$AUDIO_DEVICE}"

    # Garantir que o diretório existe
    mkdir -p "$AUDIO_RAW_DIR"

    # Se for path relativo, colocar no diretório padrão
    if [[ ! "$output_file" = /* ]]; then
        output_file="$AUDIO_RAW_DIR/$output_file"
    fi

    print_header "INICIANDO GRAVAÇÃO"

    print_info "Dispositivo: $device"
    print_info "Arquivo de saída: $output_file"

    if [ "$duration" -gt 0 ]; then
        print_info "Duração: ${duration} segundos"
        echo ""
        print_warning "Gravando por ${duration} segundos..."

        ffmpeg -y -f avfoundation -i "$device" \
            -ac 2 -ar 44100 -ab 192k \
            -t "$duration" \
            "$output_file"
    else
        echo ""
        print_warning "Gravando... Pressione Ctrl+C para parar"
        echo ""

        ffmpeg -y -f avfoundation -i "$device" \
            -ac 2 -ar 44100 -ab 192k \
            "$output_file" || true
    fi

    if [ -f "$output_file" ]; then
        print_success "Gravação salva: $output_file"
        local size=$(ls -lh "$output_file" | awk '{print $5}')
        print_info "Tamanho: $size"
    else
        print_error "Falha na gravação"
        exit 1
    fi

    echo ""
    echo "$output_file"
}

# ============================================================================
# TRANSCREVER
# ============================================================================
transcribe() {
    local input_file="$1"

    print_header "INICIANDO TRANSCRIÇÃO"

    mkdir -p "$TRANSCRIPT_TXT_DIR"

    print_info "Modelo: $WHISPER_MODEL"
    print_info "Idioma: $LANGUAGE"
    print_info "Saída: $TRANSCRIPT_TXT_DIR"
    print_warning "Processando..."
    echo ""

    whisper "$input_file" \
        --language "$LANGUAGE" \
        --model "$WHISPER_MODEL" \
        --output_dir "$TRANSCRIPT_TXT_DIR" \
        --output_format all \
        --verbose False \
        --fp16 False

    print_success "Transcrição concluída!"
    echo ""

    # Organizar arquivos por tipo
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')

    mkdir -p "$TRANSCRIPT_SRT_DIR" "$TRANSCRIPT_VTT_DIR"

    [ -f "$TRANSCRIPT_TXT_DIR/${basename}.srt" ] && mv "$TRANSCRIPT_TXT_DIR/${basename}.srt" "$TRANSCRIPT_SRT_DIR/"
    [ -f "$TRANSCRIPT_TXT_DIR/${basename}.vtt" ] && mv "$TRANSCRIPT_TXT_DIR/${basename}.vtt" "$TRANSCRIPT_VTT_DIR/"

    print_info "Arquivos organizados por formato"
}

# ============================================================================
# MOSTRAR USO
# ============================================================================
show_usage() {
    echo "Uso: $0 <comando> [opções]"
    echo ""
    echo "Comandos:"
    echo "  list              Lista dispositivos de áudio disponíveis"
    echo "  record <arquivo>  Grava áudio do BlackHole para arquivo MP3"
    echo "  transcribe <arq>  Transcreve arquivo de áudio existente"
    echo "  full <arquivo>    Grava e transcreve automaticamente"
    echo ""
    echo "Opções para 'record' e 'full':"
    echo "  -d <segundos>     Duração da gravação (0 = manual, Ctrl+C)"
    echo "  -i <dispositivo>  Dispositivo de entrada (padrão: $AUDIO_DEVICE)"
    echo ""
    echo "Paths configurados:"
    echo "  PROJECT_ROOT:     $PROJECT_ROOT"
    echo "  AUDIO_RAW_DIR:    $AUDIO_RAW_DIR"
    echo "  TRANSCRIPT_TXT:   $TRANSCRIPT_TXT_DIR"
    echo ""
    echo "Exemplos:"
    echo "  $0 list"
    echo "  $0 record aula.mp3 -d 60"
    echo "  $0 transcribe $AUDIO_RAW_DIR/aula.mp3"
    echo "  $0 full minha_aula.mp3"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    local command="$1"
    shift || true

    case "$command" in
        list)
            list_audio_devices
            ;;
        record)
            local output_file="$1"
            local duration=0
            local device=":$AUDIO_DEVICE"
            shift || true

            while getopts "d:i:" opt; do
                case $opt in
                    d) duration="$OPTARG" ;;
                    i) device="$OPTARG" ;;
                esac
            done

            if [ -z "$output_file" ]; then
                output_file="chrome_$(date +%Y%m%d_%H%M%S).mp3"
            fi

            record_audio "$output_file" "$duration" "$device"
            ;;
        transcribe)
            local input_file="$1"
            if [ -z "$input_file" ]; then
                print_error "Especifique o arquivo de áudio"
                exit 1
            fi
            transcribe "$input_file"
            ;;
        full)
            local output_file="$1"
            local duration=0
            local device=":$AUDIO_DEVICE"
            shift || true

            while getopts "d:i:" opt; do
                case $opt in
                    d) duration="$OPTARG" ;;
                    i) device="$OPTARG" ;;
                esac
            done

            if [ -z "$output_file" ]; then
                output_file="chrome_$(date +%Y%m%d_%H%M%S).mp3"
            fi

            local recorded_file=$(record_audio "$output_file" "$duration" "$device" | tail -1)
            transcribe "$recorded_file"

            # Mostrar resultados
            local basename=$(basename "$recorded_file" | sed 's/\.[^.]*$//')
            print_header "ARQUIVOS GERADOS"
            echo "Áudio:"
            ls -lh "$recorded_file" 2>/dev/null || true
            echo ""
            echo "Transcrições:"
            ls -lh "$TRANSCRIPT_TXT_DIR/${basename}"* 2>/dev/null || true
            ls -lh "$TRANSCRIPT_SRT_DIR/${basename}"* 2>/dev/null || true
            ls -lh "$TRANSCRIPT_VTT_DIR/${basename}"* 2>/dev/null || true
            echo ""
            ;;
        *)
            show_usage
            ;;
    esac
}

main "$@"
