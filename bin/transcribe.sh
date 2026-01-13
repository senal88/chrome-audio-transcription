#!/bin/zsh
# ============================================================================
# TRANSCRIÇÃO AUTOMÁTICA DE ÁUDIO - macOS Silicon
# Pipeline: Áudio/Vídeo → Whisper → TXT/SRT/VTT
# ============================================================================

set -e

# Carregar configurações do .env
PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Fallbacks (caso .env não exista)
AUDIO_RAW_DIR="${AUDIO_RAW_DIR:-$PROJECT_ROOT/audio/raw}"
TRANSCRIPT_TXT_DIR="${TRANSCRIPT_TXT_DIR:-$PROJECT_ROOT/transcripts/txt}"
TRANSCRIPT_SRT_DIR="${TRANSCRIPT_SRT_DIR:-$PROJECT_ROOT/transcripts/srt}"
TRANSCRIPT_VTT_DIR="${TRANSCRIPT_VTT_DIR:-$PROJECT_ROOT/transcripts/vtt}"
TRANSCRIPT_CLEAN_DIR="${TRANSCRIPT_CLEAN_DIR:-$PROJECT_ROOT/transcripts/clean}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/logs}"
TMP_DIR="${TMP_DIR:-$PROJECT_ROOT/tmp}"
LANGUAGE="${LANGUAGE:-pt}"
WHISPER_MODEL="${WHISPER_MODEL:-medium}"

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
# VERIFICAÇÃO DE DEPENDÊNCIAS
# ============================================================================
check_dependencies() {
    if ! command -v whisper &> /dev/null; then
        print_error "Whisper não encontrado. Instale com: pip install openai-whisper"
        exit 1
    fi

    if ! command -v ffmpeg &> /dev/null; then
        print_error "FFmpeg não encontrado. Instale com: brew install ffmpeg"
        exit 1
    fi
}

# ============================================================================
# VALIDAÇÃO DO ARQUIVO DE ENTRADA
# ============================================================================
validate_input() {
    local input_file="$1"

    if [ -z "$input_file" ]; then
        print_error "Nenhum arquivo especificado"
        echo ""
        echo "Uso: $0 <arquivo_audio> [modelo] [idioma]"
        echo ""
        echo "Exemplo:"
        echo "  $0 audio/raw/meu_audio.m4a"
        echo "  $0 audio/raw/meu_audio.m4a medium pt"
        exit 1
    fi

    if [ ! -f "$input_file" ]; then
        print_error "Arquivo não encontrado: $input_file"
        exit 1
    fi

    print_success "Arquivo encontrado: $input_file"

    # Mostrar informações do arquivo
    local file_size=$(ls -lh "$input_file" | awk '{print $5}')
    print_info "Tamanho: $file_size"
}

# ============================================================================
# EXTRAIR ÁUDIO DE VÍDEO (se necessário)
# ============================================================================
extract_audio_if_needed() {
    local input_file="$1"
    local temp_audio="$TMP_DIR/$(basename "$input_file" | sed 's/\.[^.]*$//').wav"

    # Verificar se o arquivo tem stream de áudio
    if ! ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1 "$input_file" 2>/dev/null | grep -q "audio"; then
        print_warning "Arquivo não contém stream de áudio, tentando extrair..." >&2

        # Tentar extrair áudio do vídeo
        if ffmpeg -i "$input_file" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$temp_audio" -y 2>/dev/null; then
            print_success "Áudio extraído: $temp_audio" >&2
            echo "$temp_audio"
            return 0
        else
            print_error "Não foi possível extrair áudio do arquivo" >&2
            return 1
        fi
    fi

    # Arquivo já tem áudio, retornar original
    echo "$input_file"
    return 0
}

# ============================================================================
# TRANSCRIÇÃO - COMANDO DEFINITIVO (CLI)
# ============================================================================
transcribe() {
    local input_file="$1"
    local model="${2:-$WHISPER_MODEL}"
    local lang="${3:-$LANGUAGE}"

    print_header "INICIANDO TRANSCRIÇÃO"

    # Converter para path absoluto
    if [[ ! "$input_file" = /* ]]; then
        input_file="$(cd "$(dirname "$input_file")" && pwd)/$(basename "$input_file")"
    fi

    # Criar diretórios de saída
    mkdir -p "$TRANSCRIPT_TXT_DIR"
    mkdir -p "$TRANSCRIPT_SRT_DIR"
    mkdir -p "$TRANSCRIPT_VTT_DIR"
    mkdir -p "$TRANSCRIPT_CLEAN_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$TMP_DIR"

    # Extrair áudio se necessário
    local audio_file=$(extract_audio_if_needed "$input_file")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Converter áudio para path absoluto também
    if [[ ! "$audio_file" = /* ]]; then
        audio_file="$(cd "$(dirname "$audio_file")" && pwd)/$(basename "$audio_file")"
    fi

    print_info "Arquivo: $input_file"
    if [ "$audio_file" != "$input_file" ]; then
        print_info "Áudio extraído: $audio_file"
    fi
    print_info "Modelo: $model"
    print_info "Idioma: $lang"
    print_info "Task: transcribe"
    print_info "Saída: $TRANSCRIPT_TXT_DIR"

    echo ""
    print_warning "A transcrição pode levar alguns minutos dependendo do tamanho do áudio..."
    echo ""

    # COMANDO DEFINITIVO DE TRANSCRIÇÃO (CLI)
    # Usando múltiplos --output_format conforme especificado
    whisper \
        "$audio_file" \
        --language "$lang" \
        --model "$model" \
        --task transcribe \
        --output_dir "$TRANSCRIPT_TXT_DIR" \
        --output_format txt \
        --output_format srt \
        --output_format vtt \
        --verbose False \
        --fp16 False

    # Limpar arquivo temporário se foi criado
    if [ "$audio_file" != "$input_file" ] && [ -f "$audio_file" ]; then
        rm -f "$audio_file"
    fi

    # Organizar arquivos nos diretórios corretos
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')

    # Mover SRT para diretório específico
    if [ -f "$TRANSCRIPT_TXT_DIR/${basename}.srt" ]; then
        mv "$TRANSCRIPT_TXT_DIR/${basename}.srt" "$TRANSCRIPT_SRT_DIR/${basename}.srt"
    fi

    # Mover VTT para diretório específico
    if [ -f "$TRANSCRIPT_TXT_DIR/${basename}.vtt" ]; then
        mv "$TRANSCRIPT_TXT_DIR/${basename}.vtt" "$TRANSCRIPT_VTT_DIR/${basename}.vtt"
    fi

    # EXTRAIR TEXTO LIMPO (SEM TIMESTAMPS) - Comando definitivo
    if [ -f "$TRANSCRIPT_SRT_DIR/${basename}.srt" ]; then
        sed 's/\[[0-9:.,]* --> [0-9:.,]*\]//g' \
            "$TRANSCRIPT_SRT_DIR/${basename}.srt" \
            | sed '/^$/d' \
            | grep -v '^[0-9]*$' \
            | grep -v '^[0-9]*:[0-9]*:[0-9]*,[0-9]* --> [0-9]*:[0-9]*:[0-9]*,[0-9]*$' \
            > "$TRANSCRIPT_CLEAN_DIR/${basename}.txt"

        print_success "Texto limpo gerado: $TRANSCRIPT_CLEAN_DIR/${basename}.txt"
    fi

    echo ""
    print_success "Transcrição concluída!"
}

# ============================================================================
# LISTAR RESULTADOS
# ============================================================================
list_results() {
    local input_file="$1"
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')

    print_header "ARQUIVOS GERADOS"

    # Verificar arquivos em cada diretório
    if [ -f "$TRANSCRIPT_TXT_DIR/${basename}.txt" ]; then
        local size=$(ls -lh "$TRANSCRIPT_TXT_DIR/${basename}.txt" | awk '{print $5}')
        print_success "$TRANSCRIPT_TXT_DIR/${basename}.txt (${size})"
    fi

    if [ -f "$TRANSCRIPT_SRT_DIR/${basename}.srt" ]; then
        local size=$(ls -lh "$TRANSCRIPT_SRT_DIR/${basename}.srt" | awk '{print $5}')
        print_success "$TRANSCRIPT_SRT_DIR/${basename}.srt (${size})"
    fi

    if [ -f "$TRANSCRIPT_VTT_DIR/${basename}.vtt" ]; then
        local size=$(ls -lh "$TRANSCRIPT_VTT_DIR/${basename}.vtt" | awk '{print $5}')
        print_success "$TRANSCRIPT_VTT_DIR/${basename}.vtt (${size})"
    fi

    if [ -f "$TRANSCRIPT_CLEAN_DIR/${basename}.txt" ]; then
        local size=$(ls -lh "$TRANSCRIPT_CLEAN_DIR/${basename}.txt" | awk '{print $5}')
        print_success "$TRANSCRIPT_CLEAN_DIR/${basename}.txt (${size})"
    fi

    echo ""
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    local input_file="$1"
    local model="${2:-$WHISPER_MODEL}"
    local lang="${3:-$LANGUAGE}"

    print_header "🎙️  TRANSCRIÇÃO AUTOMÁTICA DE ÁUDIO"

    check_dependencies
    validate_input "$input_file"
    transcribe "$input_file" "$model" "$lang"
    list_results "$input_file"

    print_success "Pipeline concluído com sucesso!"
    echo ""
}

# Executar
main "$@"
