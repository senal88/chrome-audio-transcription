"""
Chrome Audio Transcription - Local Dashboard
FastAPI backend para visualização do pipeline de transcrição.
"""

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pathlib import Path
from datetime import datetime
import json

# Paths absolutos (padrão macOS Silicon)
PROJECT_ROOT = Path("/Users/luiz.sena88/Projects/chrome-audio-transcription")
AUDIO_RAW = PROJECT_ROOT / "audio/raw"
AUDIO_PROCESSED = PROJECT_ROOT / "audio/processed"
TRANSCRIPTS_TXT = PROJECT_ROOT / "transcripts/txt"
TRANSCRIPTS_SRT = PROJECT_ROOT / "transcripts/srt"
TRANSCRIPTS_VTT = PROJECT_ROOT / "transcripts/vtt"
LOGS = PROJECT_ROOT / "logs"

app = FastAPI(title="Chrome Audio Dashboard", version="1.0.0")

# Static files e templates
app.mount("/static", StaticFiles(directory=Path(__file__).parent / "static"), name="static")
templates = Jinja2Templates(directory=Path(__file__).parent / "templates")


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
        return FileResponse(audio_path, media_type="audio/mpeg")
    return {"error": "Arquivo não encontrado"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
