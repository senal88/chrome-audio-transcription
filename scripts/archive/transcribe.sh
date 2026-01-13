#!/bin/zsh
# ============================================================================
# TRANSCRIÇÃO AUTOMÁTICA DE ÁUDIO (MP3 → TEXTO) - macOS Silicon
# Pipeline: Chrome → BlackHole → FFmpeg → MP3 → Whisper → TXT/SRT/VTT
# ============================================================================

set -e

# ============================================================================
# CONFIGURAÇÃO PADRÃO
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-./transcricao}"
TRANSCRIPT_LANG="${TRANSCRIPT_LANG:-pt}"
TRANSCRIPT_MODEL="${TRANSCRIPT_MODEL:-medium}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNÇÕES DE UTILIDADE
# ============================================================================
print_header() {
    echo ""
    echo "${BLUE}============================================================${NC}"
    echo "${BLUE}  $1${NC}"
    echo "${BLUE}============================================================${NC}"
    echo ""
}

print_success() {
    echo "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo "${RED}✗ $1${NC}"
}

print_info() {
    echo "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# VERIFICAÇÃO DE DEPENDÊNCIAS
# ============================================================================
check_dependencies() {
    print_header "VERIFICANDO DEPENDÊNCIAS"

    local missing=0

    # FFmpeg
    if command -v ffmpeg &> /dev/null; then
        print_success "FFmpeg: $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
    else
        print_error "FFmpeg não encontrado. Instale com: brew install ffmpeg"
        missing=1
    fi

    # Whisper
    if command -v whisper &> /dev/null; then
        print_success "Whisper: instalado"
    else
        print_error "Whisper não encontrado. Instale com: pip install openai-whisper"
        missing=1
    fi

    # Python
    if command -v python3 &> /dev/null; then
        print_success "Python: $(python3 --version 2>&1)"
    else
        print_error "Python3 não encontrado"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi

    echo ""
}

# ============================================================================
# VALIDAÇÃO DO ARQUIVO DE ENTRADA
# ============================================================================
validate_input() {
    local input_file="$1"

    print_header "VALIDANDO ARQUIVO DE ENTRADA"

    if [ -z "$input_file" ]; then
        print_error "Nenhum arquivo de entrada especificado"
        echo ""
        echo "Uso: $0 <arquivo_audio.mp3> [modelo] [idioma]"
        echo ""
        echo "Modelos disponíveis: tiny, base, small, medium, large"
        echo "Idiomas: pt, en, es, fr, de, etc."
        echo ""
        echo "Exemplo:"
        echo "  $0 meu_audio.mp3 medium pt"
        echo ""
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

    # Validar com ffprobe
    if ffprobe "$input_file" 2>&1 | grep -q "Audio:"; then
        print_success "Arquivo de áudio válido"
        local duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null)
        if [ -n "$duration" ]; then
            local minutes=$(echo "$duration / 60" | bc)
            local seconds=$(echo "$duration % 60" | bc | cut -d'.' -f1)
            print_info "Duração: ${minutes}m ${seconds}s"
        fi
    else
        print_error "Arquivo não contém stream de áudio válido"
        exit 1
    fi

    echo ""
}

# ============================================================================
# TRANSCRIÇÃO
# ============================================================================
transcribe() {
    local input_file="$1"
    local model="$2"
    local lang="$3"

    print_header "INICIANDO TRANSCRIÇÃO"

    print_info "Arquivo: $input_file"
    print_info "Modelo: $model"
    print_info "Idioma: $lang"
    print_info "Saída: $OUTPUT_DIR"

    # Criar diretório de saída
    mkdir -p "$OUTPUT_DIR"

    echo ""
    print_warning "A transcrição pode levar alguns minutos dependendo do tamanho do áudio..."
    echo ""

    # Executar Whisper
    whisper "$input_file" \
        --language "$lang" \
        --model "$model" \
        --output_dir "$OUTPUT_DIR" \
        --output_format all \
        --verbose False \
        --fp16 False

    echo ""
    print_success "Transcrição concluída!"
}

# ============================================================================
# PÓS-PROCESSAMENTO
# ============================================================================
post_process() {
    local input_file="$1"
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')

    print_header "PÓS-PROCESSAMENTO"

    # Gerar versão limpa do texto (sem timestamps)
    if [ -f "$OUTPUT_DIR/${basename}.srt" ]; then
        sed 's/\[[0-9:.,]* --> [0-9:.,]*\]//g' "$OUTPUT_DIR/${basename}.srt" | \
        grep -v '^[0-9]*$' | \
        grep -v '^\s*$' | \
        sed 's/^[0-9]*:[0-9]*:[0-9]*,[0-9]* --> [0-9]*:[0-9]*:[0-9]*,[0-9]*$//g' | \
        grep -v '^$' \
        > "$OUTPUT_DIR/${basename}_limpo.txt"

        print_success "Texto limpo gerado: ${basename}_limpo.txt"
    fi

    echo ""
}

# ============================================================================
# LISTAR RESULTADOS
# ============================================================================
list_results() {
    local input_file="$1"
    local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')

    print_header "ARQUIVOS GERADOS"

    for ext in txt srt vtt json tsv; do
        if [ -f "$OUTPUT_DIR/${basename}.$ext" ]; then
            local size=$(ls -lh "$OUTPUT_DIR/${basename}.$ext" | awk '{print $5}')
            print_success "${basename}.$ext (${size})"
        fi
    done

    if [ -f "$OUTPUT_DIR/${basename}_limpo.txt" ]; then
        local size=$(ls -lh "$OUTPUT_DIR/${basename}_limpo.txt" | awk '{print $5}')
        print_success "${basename}_limpo.txt (${size})"
    fi

    echo ""
    print_info "Diretório de saída: $OUTPUT_DIR"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    local input_file="$1"
    local model="${2:-$TRANSCRIPT_MODEL}"
    local lang="${3:-$TRANSCRIPT_LANG}"

    print_header "🎙️  TRANSCRIÇÃO AUTOMÁTICA DE ÁUDIO - macOS Silicon"

    check_dependencies
    validate_input "$input_file"
    transcribe "$input_file" "$model" "$lang"
    post_process "$input_file"
    list_results "$input_file"

    print_success "Pipeline concluído com sucesso!"
    echo ""
}

# Executar
main "$@"
