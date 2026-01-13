/**
 * API Service - Integração com backend FastAPI
 */

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export interface TranscriptionFile {
  id: string;
  name: string;
  type: 'audio' | 'video';
  path: string;
  timestamp: string;
  size_mb: number;
  has_transcript: boolean;
  transcript_id?: string;
}

export interface TranscriptContent {
  id: string;
  text: string;
  format: string;
  has_srt: boolean;
  has_vtt: boolean;
}

export interface RecordingStatus {
  recording: boolean;
  pid?: number;
}

class ApiService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = API_BASE;
  }

  async getFiles(): Promise<TranscriptionFile[]> {
    const response = await fetch(`${this.baseUrl}/api/files`);
    if (!response.ok) throw new Error('Failed to fetch files');
    const data = await response.json();
    return data.files || [];
  }

  async getFile(fileId: string): Promise<TranscriptionFile> {
    const response = await fetch(`${this.baseUrl}/api/files/${fileId}`);
    if (!response.ok) throw new Error('Failed to fetch file');
    return await response.json();
  }

  async getTranscript(fileId: string): Promise<TranscriptContent> {
    const response = await fetch(`${this.baseUrl}/api/transcripts/${fileId}`);
    if (!response.ok) throw new Error('Failed to fetch transcript');
    return await response.json();
  }

  async startRecording(): Promise<{ status: string; file?: string }> {
    const response = await fetch(`${this.baseUrl}/api/record/start`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to start recording');
    return await response.json();
  }

  async stopRecording(): Promise<{ status: string; file?: string; transcribing?: boolean }> {
    const response = await fetch(`${this.baseUrl}/api/record/stop`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to stop recording');
    return await response.json();
  }

  async getRecordingStatus(): Promise<RecordingStatus> {
    const response = await fetch(`${this.baseUrl}/api/record/status`);
    if (!response.ok) throw new Error('Failed to get recording status');
    return await response.json();
  }

  async transcribeFile(fileId: string, model: string = 'medium', language: string = 'pt'): Promise<{ status: string; pid: number }> {
    const response = await fetch(`${this.baseUrl}/api/transcribe/${fileId}?model=${model}&language=${language}`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to start transcription');
    return await response.json();
  }
}

export const apiService = new ApiService();
