"""
Chrome Audio Transcription - Local Dashboard
FastAPI backend para visualização do pipeline de transcrição.
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
from datetime import datetime
import json
import subprocess
import os
from typing import Optional, List

# Paths absolutos (padrão macOS Silicon)
PROJECT_ROOT = Path("/Users/luiz.sena88/Projects/chrome-audio-transcription")
AUDIO_RAW = PROJECT_ROOT / "audio/raw"
AUDIO_PROCESSED = PROJECT_ROOT / "audio/processed"
TRANSCRIPTS_TXT = PROJECT_ROOT / "transcripts/txt"
TRANSCRIPTS_SRT = PROJECT_ROOT / "transcripts/srt"
TRANSCRIPTS_VTT = PROJECT_ROOT / "transcripts/vtt"
TRANSCRIPTS_CLEAN = PROJECT_ROOT / "transcripts/clean"
LOGS = PROJECT_ROOT / "logs"
TMP_DIR = PROJECT_ROOT / "tmp"

app = FastAPI(title="Chrome Audio Dashboard", version="2.0.0")

# CORS para desenvolvimento React
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files e templates
static_dir = Path(__file__).parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=static_dir), name="static")
templates = Jinja2Templates(directory=Path(__file__).parent / "templates")

# Servir frontend React quando buildado
frontend_dist = Path(__file__).parent / "static"
if frontend_dist.exists() and (frontend_dist / "index.html").exists():
    @app.get("/{path:path}")
    async def serve_frontend(path: str):
        """Serve frontend React."""
        if path.startswith("api") or path.startswith("audio"):
            raise HTTPException(status_code=404)
        file_path = frontend_dist / path
        if file_path.exists() and file_path.is_file():
            return FileResponse(file_path)
        return FileResponse(frontend_dist / "index.html")


def get_file_info(file_path: Path) -> dict:
    """Extrai informações de um arquivo."""
    stat = file_path.stat()
    return {
        "name": file_path.stem,
        "filename": file_path.name,
        "extension": file_path.suffix,
        "size_mb": round(stat.st_size / 1024 / 1024, 2),
        "size_bytes": stat.st_size,
        "created": datetime.fromtimestamp(stat.st_ctime),
        "modified": datetime.fromtimestamp(stat.st_mtime),
        "path": str(file_path),
    }


def get_pipeline_status() -> list[dict]:
    """Coleta status de todos os arquivos do pipeline."""
    # Coletar todos os áudios
    audio_files = list(AUDIO_RAW.glob("*.mp3")) + list(AUDIO_RAW.glob("*.mov")) + list(AUDIO_RAW.glob("*.wav"))
    audio_files = sorted(audio_files, key=lambda x: x.stat().st_mtime, reverse=True)

    # Coletar transcrições
    txt_files = {f.stem: f for f in TRANSCRIPTS_TXT.glob("*.txt")}
    srt_files = {f.stem: f for f in TRANSCRIPTS_SRT.glob("*.srt")}
    vtt_files = {f.stem: f for f in TRANSCRIPTS_VTT.glob("*.vtt")}

    rows = []
    for audio in audio_files:
        info = get_file_info(audio)
        name = audio.stem

        # Status de transcrição
        has_txt = name in txt_files
        has_srt = name in srt_files
        has_vtt = name in vtt_files

        if has_txt or has_srt or has_vtt:
            status = "✅ Concluído"
            status_class = "success"
        else:
            status = "⏳ Pendente"
            status_class = "pending"

        rows.append({
            **info,
            "has_txt": has_txt,
            "has_srt": has_srt,
            "has_vtt": has_vtt,
            "status": status,
            "status_class": status_class,
            "txt_path": str(txt_files.get(name, "")),
            "srt_path": str(srt_files.get(name, "")),
            "vtt_path": str(vtt_files.get(name, "")),
        })

    return rows


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Dashboard principal."""
    rows = get_pipeline_status()
    stats = {
        "total": len(rows),
        "transcribed": sum(1 for r in rows if r["has_txt"]),
        "pending": sum(1 for r in rows if not r["has_txt"]),
        "total_size_mb": round(sum(r["size_mb"] for r in rows), 2),
    }
    return templates.TemplateResponse("index.html", {
        "request": request,
        "rows": rows,
        "stats": stats,
        "project_root": str(PROJECT_ROOT),
    })


@app.get("/api/status")
async def api_status():
    """API JSON para status do pipeline."""
    rows = get_pipeline_status()
    return {
        "files": rows,
        "stats": {
            "total": len(rows),
            "transcribed": sum(1 for r in rows if r["has_txt"]),
            "pending": sum(1 for r in rows if not r["has_txt"]),
        }
    }


@app.get("/api/transcript/{filename}")
async def get_transcript(filename: str):
    """Retorna conteúdo de uma transcrição."""
    txt_path = TRANSCRIPTS_TXT / f"{filename}.txt"
    if txt_path.exists():
        return {"content": txt_path.read_text(), "format": "txt"}
    return {"error": "Transcrição não encontrada"}


@app.get("/audio/{filename}")
async def serve_audio(filename: str):
    """Serve arquivo de áudio para player HTML5."""
    audio_path = AUDIO_RAW / filename
    if audio_path.exists():
        # Detectar tipo de mídia
        ext = audio_path.suffix.lower()
        media_types = {
            '.mp3': 'audio/mpeg',
            '.m4a': 'audio/mp4',
            '.wav': 'audio/wav',
            '.mp4': 'video/mp4',
            '.mov': 'video/quicktime',
        }
        media_type = media_types.get(ext, 'application/octet-stream')
        return FileResponse(audio_path, media_type=media_type)
    raise HTTPException(status_code=404, detail="Arquivo não encontrado")


# ============================================================================
# NOVOS ENDPOINTS PARA DASHBOARD REACT
# ============================================================================

@app.get("/api/files")
async def get_files():
    """Retorna lista de todos os arquivos de áudio/vídeo."""
    files = []

    # Buscar todos os formatos de áudio/vídeo
    extensions = ['*.mp3', '*.m4a', '*.wav', '*.mp4', '*.mov']
    audio_files = []
    for ext in extensions:
        audio_files.extend(AUDIO_RAW.glob(ext))

    audio_files = sorted(audio_files, key=lambda x: x.stat().st_mtime, reverse=True)

    txt_files = {f.stem: f for f in TRANSCRIPTS_TXT.glob("*.txt")}
    srt_files = {f.stem: f for f in TRANSCRIPTS_SRT.glob("*.srt")}
    vtt_files = {f.stem: f for f in TRANSCRIPTS_VTT.glob("*.vtt")}

    for audio_file in audio_files:
        info = get_file_info(audio_file)
        name = audio_file.stem
        ext = audio_file.suffix.lower()

        # Determinar tipo
        file_type = 'video' if ext in ['.mp4', '.mov'] else 'audio'

        files.append({
            "id": name,
            "name": audio_file.name,
            "type": file_type,
            "path": f"audio/raw/{audio_file.name}",
            "timestamp": info["created"].isoformat(),
            "size_mb": info["size_mb"],
            "has_transcript": name in txt_files or name in srt_files or name in vtt_files,
            "transcript_id": name if (name in txt_files or name in srt_files) else None,
        })

    return {"files": files}


@app.get("/api/files/{file_id}")
async def get_file_details(file_id: str):
    """Retorna detalhes de um arquivo específico."""
    # Buscar arquivo
    audio_file = None
    for ext in ['*.mp3', '*.m4a', '*.wav', '*.mp4', '*.mov']:
        matches = list(AUDIO_RAW.glob(f"{file_id}{ext.replace('*', '')}"))
        if matches:
            audio_file = matches[0]
            break

    if not audio_file:
        raise HTTPException(status_code=404, detail="Arquivo não encontrado")

    info = get_file_info(audio_file)
    ext = audio_file.suffix.lower()
    file_type = 'video' if ext in ['.mp4', '.mov'] else 'audio'

    txt_path = TRANSCRIPTS_TXT / f"{file_id}.txt"
    srt_path = TRANSCRIPTS_SRT / f"{file_id}.srt"
    vtt_path = TRANSCRIPTS_VTT / f"{file_id}.vtt"

    return {
        "id": file_id,
        "name": audio_file.name,
        "type": file_type,
        "path": f"audio/raw/{audio_file.name}",
        "timestamp": info["created"].isoformat(),
        "size_mb": info["size_mb"],
        "has_txt": txt_path.exists(),
        "has_srt": srt_path.exists(),
        "has_vtt": vtt_path.exists(),
        "transcript_id": file_id if txt_path.exists() else None,
    }


@app.get("/api/transcripts/{file_id}")
async def get_transcript(file_id: str):
    """Retorna transcrição completa de um arquivo."""
    txt_path = TRANSCRIPTS_TXT / f"{file_id}.txt"
    srt_path = TRANSCRIPTS_SRT / f"{file_id}.srt"
    vtt_path = TRANSCRIPTS_VTT / f"{file_id}.vtt"
    clean_path = TRANSCRIPTS_CLEAN / f"{file_id}.txt"

    if not txt_path.exists() and not srt_path.exists():
        raise HTTPException(status_code=404, detail="Transcrição não encontrada")

    # Preferir texto limpo, depois txt, depois srt
    content = ""
    if clean_path.exists():
        content = clean_path.read_text(encoding='utf-8')
    elif txt_path.exists():
        content = txt_path.read_text(encoding='utf-8')
    elif srt_path.exists():
        # Extrair apenas texto do SRT
        lines = srt_path.read_text(encoding='utf-8').split('\n')
        content = '\n'.join([l for l in lines if l.strip() and not l.strip().isdigit() and '-->' not in l])

    return {
        "id": file_id,
        "text": content,
        "format": "txt",
        "has_srt": srt_path.exists(),
        "has_vtt": vtt_path.exists(),
    }


@app.get("/api/transcripts/{file_id}/srt")
async def get_transcript_srt(file_id: str):
    """Retorna transcrição em formato SRT."""
    srt_path = TRANSCRIPTS_SRT / f"{file_id}.srt"
    if not srt_path.exists():
        raise HTTPException(status_code=404, detail="Transcrição SRT não encontrada")

    return FileResponse(srt_path, media_type="text/plain")


@app.get("/api/transcripts/{file_id}/vtt")
async def get_transcript_vtt(file_id: str):
    """Retorna transcrição em formato VTT."""
    vtt_path = TRANSCRIPTS_VTT / f"{file_id}.vtt"
    if not vtt_path.exists():
        raise HTTPException(status_code=404, detail="Transcrição VTT não encontrada")

    return FileResponse(vtt_path, media_type="text/vtt")


@app.post("/api/record/start")
async def start_recording():
    """Inicia gravação de áudio."""
    script_path = PROJECT_ROOT / "bin" / "start-record.sh"
    if not script_path.exists():
        raise HTTPException(status_code=500, detail="Script de gravação não encontrado")

    try:
        result = subprocess.run(
            [str(script_path)],
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode == 0:
            output = result.stdout.strip()
            if "RECORDING_STARTED" in output:
                file_path = output.split("RECORDING_STARTED")[-1].strip()
                return {"status": "started", "file": file_path}

        return {"status": "error", "message": result.stderr}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/record/stop")
async def stop_recording():
    """Para gravação e inicia transcrição."""
    script_path = PROJECT_ROOT / "bin" / "stop-record.sh"
    if not script_path.exists():
        raise HTTPException(status_code=500, detail="Script de parada não encontrado")

    try:
        result = subprocess.run(
            [str(script_path)],
            capture_output=True,
            text=True,
            timeout=300  # 5 minutos para transcrição
        )

        if result.returncode == 0:
            output = result.stdout.strip()
            if "RECORDING_STOPPED_AND_TRANSCRIBED" in output:
                file_path = output.split("RECORDING_STOPPED_AND_TRANSCRIBED")[-1].strip()
                return {"status": "stopped", "file": file_path, "transcribing": True}

        return {"status": "error", "message": result.stderr}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/record/status")
async def get_recording_status():
    """Verifica status da gravação."""
    pid_file = TMP_DIR / "record.pid"
    if pid_file.exists():
        try:
            pid = int(pid_file.read_text().strip())
            # Verificar se processo ainda está rodando
            os.kill(pid, 0)  # Não mata, apenas verifica
            return {"recording": True, "pid": pid}
        except (OSError, ValueError):
            # Processo não existe mais
            pid_file.unlink(missing_ok=True)
            return {"recording": False}
    return {"recording": False}


@app.post("/api/transcribe/{file_id}")
async def transcribe_file(file_id: str, model: Optional[str] = "medium", language: Optional[str] = "pt"):
    """Inicia transcrição de um arquivo."""
    # Buscar arquivo
    audio_file = None
    for ext in ['*.mp3', '*.m4a', '*.wav', '*.mp4', '*.mov']:
        matches = list(AUDIO_RAW.glob(f"{file_id}{ext.replace('*', '')}"))
        if matches:
            audio_file = matches[0]
            break

    if not audio_file:
        raise HTTPException(status_code=404, detail="Arquivo não encontrado")

    script_path = PROJECT_ROOT / "bin" / "transcribe.sh"
    if not script_path.exists():
        raise HTTPException(status_code=500, detail="Script de transcrição não encontrado")

    try:
        result = subprocess.Popen(
            [str(script_path), str(audio_file), model, language],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        return {"status": "started", "pid": result.pid, "file_id": file_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Rota catch-all para servir frontend React (deve ser a última)
if frontend_dist.exists() and (frontend_dist / "index.html").exists():
    @app.get("/{path:path}")
    async def serve_frontend(path: str, request: Request):
        """Serve frontend React."""
        # Não interceptar rotas de API ou áudio
        if path.startswith("api") or path.startswith("audio"):
            raise HTTPException(status_code=404)
        file_path = frontend_dist / path
        if file_path.exists() and file_path.is_file():
            return FileResponse(file_path)
        # Fallback para index.html (SPA routing)
        return FileResponse(frontend_dist / "index.html")


# Rota catch-all para servir frontend React (deve ser a última)
if frontend_dist.exists() and (frontend_dist / "index.html").exists():
    @app.get("/{path:path}")
    async def serve_frontend(path: str, request: Request):
        """Serve frontend React."""
        # Não interceptar rotas de API ou áudio
        if path.startswith("api") or path.startswith("audio"):
            raise HTTPException(status_code=404)
        file_path = frontend_dist / path
        if file_path.exists() and file_path.is_file():
            return FileResponse(file_path)
        # Fallback para index.html (SPA routing)
        return FileResponse(frontend_dist / "index.html")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
