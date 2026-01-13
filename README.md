# Chrome Audio Transcription

Pipeline completo de gravação e transcrição automática de áudio para macOS Silicon, com dashboard web integrado e suporte a análise com Gemini AI.

## 🎯 Funcionalidades

- ✅ **Gravação de áudio** via BlackHole 2ch (captura de áudio do sistema)
- ✅ **Transcrição automática** com Whisper (local, sem API externa)
- ✅ **Dashboard web moderno** (React + FastAPI)
- ✅ **Análise com Gemini AI** (resumo, pontos-chave, ações)
- ✅ **Chat contextual** com transcrições
- ✅ **Múltiplos formatos** de saída (TXT, SRT, VTT)
- ✅ **Integração Raycast** para acesso rápido
- ✅ **Controle via CLI** ou interface web

## 📁 Arquitetura

```
chrome-audio-transcription/
├── .env                    # Configuração de paths (gitignored)
├── env.example             # Template de configuração
├── bin/
│   ├── start-record.sh     # Inicia gravação
│   ├── stop-record.sh      # Para gravação e transcreve
│   ├── transcribe.sh       # Script de transcrição
│   └── *-raycast.sh        # Scripts para Raycast
├── audio/
│   ├── raw/                # Gravações originais
│   └── processed/          # Áudios processados
├── transcripts/
│   ├── txt/                # Transcrições em texto
│   ├── srt/                # Legendas SRT
│   ├── vtt/                # Legendas VTT
│   └── clean/              # Versões limpas (sem timestamps)
├── dashboard/              # Dashboard web completo
│   ├── app.py              # Backend FastAPI
│   ├── frontend/           # Frontend React + Vite
│   └── requirements.txt
├── logs/                   # Logs de execução
└── tmp/
    └── whisper_cache/      # Cache do Whisper
```

## 🚀 Instalação Rápida

### 1. Pré-requisitos

```bash
# Homebrew (se ainda não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# FFmpeg para gravação
brew install ffmpeg

# BlackHole para captura de áudio do sistema
brew install blackhole-2ch

# Whisper para transcrição
pip install openai-whisper

# Node.js para dashboard (se usar dashboard)
brew install node
```

### 2. Configurar Projeto

```bash
# Clonar ou navegar até o projeto
cd chrome-audio-transcription

# Copiar template de configuração
cp env.example .env

# Tornar scripts executáveis
chmod +x bin/*.sh
```

### 3. Configurar PATH (Opcional)

Adicionar ao `~/.zshrc`:

```bash
# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Projeto
export PROJECT_ROOT="/Users/luiz.sena88/Projects/chrome-audio-transcription"
export PATH="$PROJECT_ROOT/bin:$PATH"
```

## 💻 Uso via CLI

### Gravação e Transcrição

```bash
# Iniciar gravação
./bin/start-record.sh

# Parar gravação e transcrever automaticamente
./bin/stop-record.sh

# Transcrever arquivo existente
./bin/transcribe.sh audio/raw/meu_audio.m4a

# Com modelo e idioma específicos
./bin/transcribe.sh audio/raw/meu_audio.m4a large pt
```

### Scripts Legados

```bash
# Listar dispositivos de áudio
./bin/record_and_transcribe.sh list

# Gravar por 60 segundos
./bin/record_and_transcribe.sh record aula.mp3 -d 60

# Gravar até Ctrl+C
./bin/record_and_transcribe.sh record aula.mp3

# Transcrever arquivo existente
./bin/transcribe.sh audio/raw/aula.mp3
```

## 🌐 Dashboard Web

### Instalação do Dashboard

```bash
# Backend
cd dashboard
pip install -r requirements.txt

# Frontend
cd frontend
npm install
```

### Configuração

Crie `.env.local` em `dashboard/frontend/` (opcional para Gemini AI):

```env
VITE_GEMINI_API_KEY=sua_chave_gemini_aqui
VITE_API_URL=http://localhost:8000
```

### Execução

**Desenvolvimento:**

```bash
# Terminal 1 - Backend
cd dashboard
python app.py

# Terminal 2 - Frontend
cd dashboard/frontend
npm run dev
```

Acesse: **http://localhost:3000**

**Produção:**

```bash
# Build do frontend
cd dashboard/frontend
npm run build

# Executar backend (servirá frontend automaticamente)
cd dashboard
python app.py
```

Acesse: **http://localhost:8000**

### Funcionalidades do Dashboard

- 📚 **Biblioteca de Arquivos**: Visualize todos os áudios/vídeos gravados
- 🎙️ **Gravação em Tempo Real**: Inicie/pare gravações diretamente da interface
- 📝 **Visualização de Transcrições**: Veja transcrições completas com formatação
- 🤖 **Análise com Gemini AI**: 
  - Resumo automático
  - Pontos-chave destacados
  - Itens de ação extraídos
  - Análise de sentimento
- 💬 **Chat Contextual**: Faça perguntas sobre a transcrição usando Gemini
- 📥 **Exportação**: Baixe transcrições em múltiplos formatos

## ⚙️ Configuração

Editar `.env` para personalizar:

| Variável        | Descrição              | Padrão        |
| --------------- | ---------------------- | ------------- |
| `AUDIO_DEVICE`  | Dispositivo de captura | BlackHole 2ch |
| `LANGUAGE`      | Idioma da transcrição  | pt            |
| `WHISPER_MODEL` | Modelo Whisper         | medium        |

### Modelos Whisper Disponíveis

- `tiny` - Mais rápido, menor qualidade
- `base` - Equilíbrio básico
- `small` - Boa qualidade
- `medium` - **Recomendado** - Excelente qualidade
- `large-v3` - Melhor qualidade, mais lento

## 🔌 Integração Raycast

Configure dois Script Commands no Raycast:

1. **Start Chrome Recording**
   - Script: `bin/start-record.sh`
   - Atalho: `⌃⌥⌘R`

2. **Stop Chrome Recording**
   - Script: `bin/stop-record.sh`
   - Atalho: `⌃⌥⌘S`

## 📡 API Endpoints

O dashboard expõe uma API REST completa:

### Arquivos
- `GET /api/files` - Lista todos os arquivos
- `GET /api/files/{id}` - Detalhes de um arquivo específico

### Transcrições
- `GET /api/transcripts/{id}` - Transcrição completa (TXT)
- `GET /api/transcripts/{id}/srt` - Transcrição em formato SRT
- `GET /api/transcripts/{id}/vtt` - Transcrição em formato VTT

### Gravação
- `POST /api/record/start` - Inicia gravação
- `POST /api/record/stop` - Para gravação e inicia transcrição
- `GET /api/record/status` - Status atual da gravação

### Transcrição Manual
- `POST /api/transcribe/{id}?model=medium&language=pt` - Transcreve arquivo manualmente

## 🛠️ Troubleshooting

### BlackHole não aparece nos dispositivos

```bash
# Verificar se está instalado
brew list blackhole-2ch

# Reinstalar se necessário
brew reinstall blackhole-2ch

# Verificar dispositivos disponíveis
ffmpeg -f avfoundation -list_devices true -i ""
```

### Whisper não encontrado

```bash
# Instalar Whisper
pip install openai-whisper

# Verificar instalação
whisper --help
```

### Erro de permissão nos scripts

```bash
# Tornar todos os scripts executáveis
chmod +x bin/*.sh
```

### Dashboard não carrega arquivos

- Verifique se o backend está rodando na porta 8000
- Verifique se os arquivos estão em `audio/raw/`
- Verifique os logs do backend para erros

## 📝 Estrutura de Saída

Após transcrição, os arquivos são organizados em:

```
transcripts/
├── txt/
│   └── nome_arquivo.txt          # Transcrição completa
├── srt/
│   └── nome_arquivo.srt          # Legendas SRT
├── vtt/
│   └── nome_arquivo.vtt          # Legendas VTT
└── clean/
    └── nome_arquivo.txt          # Texto limpo (sem timestamps)
```

## 🎨 Tecnologias Utilizadas

- **Backend**: FastAPI (Python)
- **Frontend**: React 19 + TypeScript + Vite
- **Transcrição**: OpenAI Whisper (local)
- **IA**: Google Gemini API (opcional)
- **Gravação**: FFmpeg + BlackHole 2ch
- **UI**: Tailwind CSS

## 📄 Licença

MIT

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

---

**Desenvolvido para macOS Silicon** 🍎
