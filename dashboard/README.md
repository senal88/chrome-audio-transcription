# TranscribeHub Dashboard

Dashboard completo para transcrição de áudio com integração Whisper e Gemini AI.

## Estrutura

```
dashboard/
├── app.py              # Backend FastAPI
├── frontend/           # Frontend React + Vite
│   ├── src/
│   │   ├── components/
│   │   ├── services/
│   │   └── types/
│   └── package.json
└── requirements.txt
```

## Instalação

### Backend

```bash
cd dashboard
pip install -r requirements.txt
```

### Frontend

```bash
cd dashboard/frontend
npm install
```

## Configuração

Crie um arquivo `.env.local` no diretório `frontend/`:

```env
VITE_GEMINI_API_KEY=sua_chave_aqui
VITE_API_URL=http://localhost:8000
```

## Execução

### Desenvolvimento

**Terminal 1 - Backend:**
```bash
cd dashboard
python app.py
```

**Terminal 2 - Frontend:**
```bash
cd dashboard/frontend
npm run dev
```

Acesse: http://localhost:3000

### Produção

**Build do frontend:**
```bash
cd dashboard/frontend
npm run build
```

O FastAPI servirá os arquivos estáticos automaticamente em `http://localhost:8000`

## Funcionalidades

- ✅ Biblioteca de arquivos de áudio/vídeo
- ✅ Gravação de áudio via BlackHole
- ✅ Transcrição automática com Whisper
- ✅ Visualização de transcrições
- ✅ Análise com Gemini AI
- ✅ Chat contextual com transcrições
- ✅ Exportação de transcrições

## API Endpoints

- `GET /api/files` - Lista todos os arquivos
- `GET /api/files/{id}` - Detalhes de um arquivo
- `GET /api/transcripts/{id}` - Transcrição de um arquivo
- `POST /api/record/start` - Inicia gravação
- `POST /api/record/stop` - Para gravação e transcreve
- `GET /api/record/status` - Status da gravação
- `POST /api/transcribe/{id}` - Transcreve arquivo manualmente
