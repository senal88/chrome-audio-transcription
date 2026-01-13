# Chrome Audio Transcription

Pipeline de gravação e transcrição automática de áudio para macOS Silicon.

## Arquitetura

```
/Users/luiz.sena88/Projects/chrome-audio-transcription/
├── .env                    # Configuração de paths (gitignored)
├── env.example             # Template de configuração
├── bin/
│   └── record_and_transcribe.sh
├── audio/
│   ├── raw/                # Gravações originais
│   └── processed/          # Áudios processados
├── transcripts/
│   ├── txt/                # Transcrições em texto
│   ├── srt/                # Legendas SRT
│   ├── vtt/                # Legendas VTT
│   └── clean/              # Versões limpas
├── logs/                   # Logs de execução
└── tmp/
    └── whisper_cache/      # Cache do Whisper
```

## Instalação

### 1. Configurar ambiente

```bash
# Copiar template de configuração
cp env.example .env

# Tornar scripts executáveis
chmod +x bin/*.sh
```

### 2. Dependências (Homebrew)

```bash
# FFmpeg para gravação
brew install ffmpeg

# BlackHole para captura de áudio do sistema
brew install blackhole-2ch

# Whisper para transcrição
pip install openai-whisper
```

### 3. Configurar PATH no shell

Adicionar ao `~/.zshrc`:

```bash
# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Projeto
export PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
export PATH="$PROJECT_ROOT/bin:$PATH"
```

## Uso

```bash
# Listar dispositivos de áudio
./bin/record_and_transcribe.sh list

# Gravar por 60 segundos
./bin/record_and_transcribe.sh record aula.mp3 -d 60

# Gravar até Ctrl+C
./bin/record_and_transcribe.sh record aula.mp3

# Transcrever arquivo existente
./bin/record_and_transcribe.sh transcribe audio/raw/aula.mp3

# Gravar E transcrever automaticamente
./bin/record_and_transcribe.sh full aula.mp3 -d 60
```

## Configuração

Editar `.env` para personalizar:

| Variável        | Descrição              | Padrão        |
| --------------- | ---------------------- | ------------- |
| `AUDIO_DEVICE`  | Dispositivo de captura | BlackHole 2ch |
| `LANGUAGE`      | Idioma da transcrição  | pt            |
| `WHISPER_MODEL` | Modelo Whisper         | medium        |

## Licença

MIT
