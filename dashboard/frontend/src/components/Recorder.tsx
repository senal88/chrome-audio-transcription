import React, { useState, useEffect, useRef } from 'react'
import { apiService } from '../services/api'

const Recorder: React.FC = () => {
  const [isRecording, setIsRecording] = useState(false)
  const [timer, setTimer] = useState(0)
  const [status, setStatus] = useState<string>('')
  const intervalRef = useRef<number | null>(null)
  const statusCheckRef = useRef<number | null>(null)

  useEffect(() => {
    checkRecordingStatus()
    const statusInterval = setInterval(checkRecordingStatus, 2000)
    statusCheckRef.current = statusInterval
    return () => {
      if (statusInterval) clearInterval(statusInterval)
    }
  }, [])

  useEffect(() => {
    if (isRecording) {
      intervalRef.current = window.setInterval(() => {
        setTimer(t => t + 1)
      }, 1000)
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current)
      setTimer(0)
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [isRecording])

  const checkRecordingStatus = async () => {
    try {
      const status = await apiService.getRecordingStatus()
      setIsRecording(status.recording)
      if (!status.recording && timer > 0) {
        setTimer(0)
        setStatus('Recording stopped. Transcription started.')
      }
    } catch (error) {
      console.error('Failed to check recording status:', error)
    }
  }

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const handleToggleRecording = async () => {
    try {
      if (isRecording) {
        const result = await apiService.stopRecording()
        setIsRecording(false)
        setStatus(result.transcribing ? 'Transcribing...' : 'Recording stopped.')
      } else {
        const result = await apiService.startRecording()
        setIsRecording(true)
        setTimer(0)
        setStatus(`Recording started: ${result.file || ''}`)
      }
    } catch (error: any) {
      setStatus(`Error: ${error.message}`)
      console.error('Recording error:', error)
    }
  }

  return (
    <div className="max-w-2xl mx-auto py-12">
      <div className="bg-slate-800 border border-slate-700 rounded-3xl p-12 text-center space-y-8 shadow-2xl relative overflow-hidden">
        {/* Background glow when recording */}
        {isRecording && <div className="absolute inset-0 bg-red-500/5 animate-pulse"></div>}

        <div className="relative z-10">
          <h2 className="text-3xl font-bold mb-2">New Recording</h2>
          <p className="text-slate-400">Record audio and auto-transcribe with Whisper</p>
        </div>

        <div className="relative z-10 flex flex-col items-center">
          <div
            className={`w-32 h-32 rounded-full flex items-center justify-center transition-all duration-500 mb-6 ${
              isRecording ? 'bg-red-500 scale-110 shadow-lg shadow-red-500/20' : 'bg-slate-700'
            }`}
          >
            <svg
              className={`w-12 h-12 text-white ${isRecording ? 'animate-pulse' : ''}`}
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 00-1 1v2a1 1 0 001 1h6a1 1 0 001-1V10a1 1 0 00-1-1H7z" />
            </svg>
          </div>

          <div className="text-5xl font-mono font-bold tracking-tighter tabular-nums mb-8">
            {formatTime(timer)}
          </div>

          {status && (
            <div
              className={`mb-4 px-4 py-2 rounded-lg text-sm ${
                status.includes('Error')
                  ? 'bg-red-500/10 text-red-400'
                  : 'bg-blue-500/10 text-blue-400'
              }`}
            >
              {status}
            </div>
          )}

          <button
            onClick={handleToggleRecording}
            disabled={status.includes('Transcribing')}
            className={`px-12 py-4 rounded-full font-bold text-lg transition-all disabled:opacity-50 ${
              isRecording
                ? 'bg-slate-700 text-white hover:bg-slate-600'
                : 'bg-red-600 text-white hover:bg-red-500 shadow-xl shadow-red-500/20'
            }`}
          >
            {isRecording ? 'Stop Recording' : 'Start Recording'}
          </button>
        </div>

        <div className="relative z-10 pt-8 border-t border-slate-700 grid grid-cols-2 gap-4">
          <div className="text-left p-4 bg-slate-900/50 rounded-2xl">
            <p className="text-xs text-slate-500 mb-1">Target Format</p>
            <p className="text-sm font-semibold">.mp3 (High Quality)</p>
          </div>
          <div className="text-left p-4 bg-slate-900/50 rounded-2xl">
            <p className="text-xs text-slate-500 mb-1">Source</p>
            <p className="text-sm font-semibold">BlackHole 2ch</p>
          </div>
        </div>
      </div>

      <div className="mt-8 bg-blue-600/10 border border-blue-500/20 p-6 rounded-2xl flex items-start gap-4">
        <div className="bg-blue-500/20 p-2 rounded-lg">
          <svg
            className="w-5 h-5 text-blue-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        </div>
        <p className="text-sm text-blue-200">
          This recording will be automatically processed by Whisper once stopped. You can find the
          results in your Library.
        </p>
      </div>
    </div>
  )
}

export default Recorder
