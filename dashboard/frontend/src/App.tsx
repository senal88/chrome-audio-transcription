import React, { useState } from 'react'
import Sidebar from './components/Sidebar'
import FileLibrary from './components/FileLibrary'
import TranscriptView from './components/TranscriptView'
import Recorder from './components/Recorder'
import { TranscriptionFile } from './types'

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'library' | 'recorder' | 'settings'>('library')
  const [selectedFile, setSelectedFile] = useState<TranscriptionFile | null>(null)

  const renderContent = () => {
    if (selectedFile) {
      return <TranscriptView file={selectedFile} onBack={() => setSelectedFile(null)} />
    }

    switch (activeTab) {
      case 'library':
        return <FileLibrary onSelectFile={setSelectedFile} />
      case 'recorder':
        return <Recorder />
      case 'settings':
        return (
          <div className="max-w-4xl space-y-8">
            <h2 className="text-2xl font-bold">Settings</h2>
            <div className="space-y-6">
              <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-lg font-semibold mb-4">Transcription Engine</h3>
                <div className="space-y-4">
                  <div className="flex items-center justify-between p-4 bg-slate-900 rounded-xl">
                    <div>
                      <p className="font-medium">Model</p>
                      <p className="text-xs text-slate-500">Select Whisper model size</p>
                    </div>
                    <select className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm">
                      <option>base</option>
                      <option>small</option>
                      <option selected>medium</option>
                      <option>large-v3</option>
                    </select>
                  </div>
                  <div className="flex items-center justify-between p-4 bg-slate-900 rounded-xl">
                    <div>
                      <p className="font-medium">Language</p>
                      <p className="text-xs text-slate-500">Auto-detect or force specific</p>
                    </div>
                    <select className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm">
                      <option>Auto-detect</option>
                      <option>English</option>
                      <option>Portuguese</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-lg font-semibold mb-4">Storage Paths</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-widest mb-1.5 ml-1">
                      Output Directory
                    </label>
                    <input
                      type="text"
                      readOnly
                      value="/Users/luiz.sena88/Projects/chrome-audio-transcription/transcripts"
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-400"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-widest mb-1.5 ml-1">
                      Temp Cache
                    </label>
                    <input
                      type="text"
                      readOnly
                      value="/Users/luiz.sena88/Projects/chrome-audio-transcription/tmp/whisper_cache"
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-sm text-slate-400"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      default:
        return null
    }
  }

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-100">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      <main className="ml-64 flex-1 p-8 lg:p-12">
        <div className="max-w-[1400px] mx-auto">{renderContent()}</div>
      </main>

      {/* Floating API Key Indicator */}
      <div className="fixed bottom-6 right-6">
        <div
          className={`px-4 py-2 rounded-full border flex items-center gap-2 backdrop-blur-md text-xs font-bold ${
            import.meta.env.VITE_GEMINI_API_KEY
              ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400'
              : 'bg-red-500/10 border-red-500/20 text-red-400'
          }`}
        >
          <div
            className={`w-2 h-2 rounded-full ${
              import.meta.env.VITE_GEMINI_API_KEY ? 'bg-emerald-500' : 'bg-red-500'
            }`}
          ></div>
          GEMINI API: {import.meta.env.VITE_GEMINI_API_KEY ? 'ACTIVE' : 'DISCONNECTED'}
        </div>
      </div>
    </div>
  )
}

export default App
