#!/bin/zsh
# ============================================================================
# GRAVAÇÃO E TRANSCRIÇÃO AUTOMÁTICA - macOS Silicon
# Pipeline completo: BlackHole → FFmpeg → MP3 → Whisper → TXT/SRT/VTT
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-./transcricao}"
TRANSCRIPT_LANG="${TRANSCRIPT_LANG:-pt}"
TRANSCRIPT_MODEL="${TRANSCRIPT_MODEL:-medium}"

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
    local device="${3:-:BlackHole 2ch}"

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
}

# ============================================================================
# TRANSCREVER
# ============================================================================
transcribe() {
    local input_file="$1"

    print_header "INICIANDO TRANSCRIÇÃO"

    mkdir -p "$OUTPUT_DIR"

    print_info "Modelo: $TRANSCRIPT_MODEL"
    print_info "Idioma: $TRANSCRIPT_LANG"
    print_warning "Processando..."
    echo ""

    whisper "$input_file" \
        --language "$TRANSCRIPT_LANG" \
        --model "$TRANSCRIPT_MODEL" \
        --output_dir "$OUTPUT_DIR" \
        --output_format all \
        --verbose False \
        --fp16 False

    print_success "Transcrição concluída!"
    echo ""
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
    echo "  full <arquivo>    Grava e transcreve automaticamente"
    echo ""
    echo "Opções para 'record' e 'full':"
    echo "  -d <segundos>     Duração da gravação (0 = manual, Ctrl+C)"
    echo "  -i <dispositivo>  Dispositivo de entrada (padrão: :BlackHole 2ch)"
    echo ""
    echo "Variáveis de ambiente:"
    echo "  OUTPUT_DIR        Diretório de saída (padrão: ./transcricao)"
    echo "  TRANSCRIPT_LANG   Idioma (padrão: pt)"
    echo "  TRANSCRIPT_MODEL  Modelo Whisper (padrão: medium)"
    echo ""
    echo "Exemplos:"
    echo "  $0 list"
    echo "  $0 record gravacao.mp3 -d 60"
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
            local device=":BlackHole 2ch"
            shift || true

            while getopts "d:i:" opt; do
                case $opt in
                    d) duration="$OPTARG" ;;
                    i) device="$OPTARG" ;;
                esac
            done

            if [ -z "$output_file" ]; then
                output_file="recording_$(date +%Y%m%d_%H%M%S).mp3"
            fi

            record_audio "$output_file" "$duration" "$device"
            ;;
        full)
            local output_file="$1"
            local duration=0
            local device=":BlackHole 2ch"
            shift || true

            while getopts "d:i:" opt; do
                case $opt in
                    d) duration="$OPTARG" ;;
                    i) device="$OPTARG" ;;
                esac
            done

            if [ -z "$output_file" ]; then
                output_file="recording_$(date +%Y%m%d_%H%M%S).mp3"
            fi

            record_audio "$output_file" "$duration" "$device"
            transcribe "$output_file"

            # Mostrar resultados
            local basename=$(basename "$output_file" | sed 's/\.[^.]*$//')
            print_header "ARQUIVOS GERADOS"
            ls -lh "$OUTPUT_DIR/${basename}"* 2>/dev/null || true
            echo ""
            ;;
        *)
            show_usage
            ;;
    esac
}

main "$@"
