
export enum FileType {
  AUDIO = 'audio',
  VIDEO = 'video',
  TRANSCRIPT = 'transcript'
}

export interface TranscriptionFile {
  id: string;
  name: string;
  type: FileType;
  path: string;
  timestamp: string;
  duration?: string;
  transcriptId?: string;
  thumbnail?: string;
}

export interface TranscriptContent {
  id: string;
  text: string;
  segments: {
    start: number;
    end: number;
    text: string;
  }[];
}

export interface AIAnalysis {
  summary: string;
  keyPoints: string[];
  actionItems: string[];
  sentiment: 'positive' | 'neutral' | 'negative';
}
