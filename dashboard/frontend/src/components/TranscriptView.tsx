import React, { useState, useEffect } from 'react'
import { TranscriptionFile, AIAnalysis } from '../types'
import { apiService } from '../services/api'
import { geminiService } from '../services/gemini'

interface TranscriptViewProps {
  file: TranscriptionFile
  onBack: () => void
}

const TranscriptView: React.FC<TranscriptViewProps> = ({ file, onBack }) => {
  const [transcript, setTranscript] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [analysis, setAnalysis] = useState<AIAnalysis | null>(null)
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [question, setQuestion] = useState('')
  const [aiResponse, setAiResponse] = useState<string | null>(null)
  const [isAnswering, setIsAnswering] = useState(false)

  useEffect(() => {
    loadTranscript()
  }, [file])

  const loadTranscript = async () => {
    if (!file.transcript_id) {
      setTranscript('Transcription not available for this file.')
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      const data = await apiService.getTranscript(file.transcript_id)
      setTranscript(data.text)
      setAnalysis(null)
      setAiResponse(null)
    } catch (error) {
      setTranscript('Failed to load transcription.')
      console.error('Failed to load transcript:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAnalyze = async () => {
    if (!transcript) return
    setIsAnalyzing(true)
    try {
      const result = await geminiService.analyzeTranscript(transcript)
      setAnalysis(result)
    } catch (err: any) {
      alert(`Failed to analyze with Gemini: ${err.message || 'Check your API key.'}`)
    } finally {
      setIsAnalyzing(false)
    }
  }

  const handleAskQuestion = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!question.trim() || !transcript) return
    setIsAnswering(true)
    try {
      const answer = await geminiService.chatWithTranscript(transcript, question)
      setAiResponse(answer)
    } catch (err: any) {
      alert(`Failed to get answer: ${err.message || 'Unknown error'}`)
    } finally {
      setIsAnswering(false)
    }
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(transcript)
  }

  const handleExport = () => {
    const blob = new Blob([transcript], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${file.name}.txt`
    a.click()
    URL.revokeObjectURL(url)
  }

  const formatDate = (timestamp: string) => {
    return new Date(timestamp).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center gap-4 mb-8">
        <button
          onClick={onBack}
          className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-all"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
        </button>
        <div>
          <h2 className="text-2xl font-bold">{file.name}</h2>
          <p className="text-slate-500 text-sm">Recorded on {formatDate(file.timestamp)}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Transcript Content */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-slate-800 border border-slate-700 rounded-3xl p-8 shadow-xl min-h-[500px]">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold flex items-center gap-2">
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
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                Transcript
              </h3>
              <div className="flex gap-2">
                <button
                  onClick={handleCopy}
                  className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-slate-200 rounded-lg text-xs font-medium transition-all"
                >
                  Copy
                </button>
                <button
                  onClick={handleExport}
                  className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-slate-200 rounded-lg text-xs font-medium transition-all"
                >
                  Export
                </button>
              </div>
            </div>
            {loading ? (
              <div className="flex items-center justify-center py-20">
                <div className="w-10 h-10 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
              </div>
            ) : (
              <div className="prose prose-invert max-w-none">
                <pre className="whitespace-pre-wrap font-sans text-slate-300 leading-relaxed text-sm bg-transparent border-none p-0">
                  {transcript || 'No transcript available'}
                </pre>
              </div>
            )}
          </div>

          {/* Chat with Gemini */}
          <div className="bg-slate-800 border border-slate-700 rounded-3xl p-8 shadow-xl">
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <svg
                className="w-5 h-5 text-emerald-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
                />
              </svg>
              Chat with context
            </h3>
            <form onSubmit={handleAskQuestion} className="space-y-4">
              <div className="flex gap-2">
                <input
                  type="text"
                  className="flex-1 bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Ask a question about this transcript..."
                  value={question}
                  onChange={e => setQuestion(e.target.value)}
                  disabled={!transcript || isAnswering}
                />
                <button
                  type="submit"
                  disabled={isAnswering || !transcript}
                  className="px-6 py-3 bg-emerald-600 hover:bg-emerald-500 disabled:bg-emerald-800 disabled:opacity-50 rounded-xl font-medium text-sm transition-all"
                >
                  {isAnswering ? '...' : 'Ask'}
                </button>
              </div>
              {aiResponse && (
                <div className="p-4 bg-emerald-900/20 border border-emerald-500/20 rounded-xl">
                  <p className="text-xs font-bold text-emerald-400 mb-2 uppercase tracking-tighter">
                    Gemini Response
                  </p>
                  <p className="text-sm text-slate-200">{aiResponse}</p>
                </div>
              )}
            </form>
          </div>
        </div>

        {/* AI Sidebar */}
        <div className="space-y-6">
          <div className="bg-slate-800 border border-slate-700 rounded-3xl p-6 shadow-xl sticky top-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold">AI Insights</h3>
              {!analysis && transcript && (
                <button
                  onClick={handleAnalyze}
                  disabled={isAnalyzing}
                  className="px-4 py-1.5 bg-blue-600 hover:bg-blue-500 rounded-lg text-xs font-bold transition-all disabled:opacity-50"
                >
                  {isAnalyzing ? 'Analyzing...' : 'Analyze'}
                </button>
              )}
            </div>

            {isAnalyzing && (
              <div className="flex flex-col items-center justify-center py-12 space-y-4">
                <div className="w-10 h-10 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                <p className="text-sm text-slate-400">Gemini is thinking...</p>
              </div>
            )}

            {!analysis && !isAnalyzing && (
              <div className="text-center py-12 px-4 border-2 border-dashed border-slate-700 rounded-2xl">
                <svg
                  className="w-10 h-10 text-slate-600 mx-auto mb-3"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1}
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
                <p className="text-sm text-slate-400">
                  Unlock AI insights including summary, key points, and action items.
                </p>
              </div>
            )}

            {analysis && (
              <div className="space-y-6 animate-in fade-in duration-700">
                <section>
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className={`w-2 h-2 rounded-full ${
                        analysis.sentiment === 'positive'
                          ? 'bg-emerald-500'
                          : analysis.sentiment === 'negative'
                          ? 'bg-red-500'
                          : 'bg-blue-500'
                      }`}
                    ></span>
                    <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest">
                      Summary
                    </h4>
                  </div>
                  <p className="text-sm leading-relaxed text-slate-300">{analysis.summary}</p>
                </section>

                <section>
                  <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3">
                    Key Highlights
                  </h4>
                  <ul className="space-y-2">
                    {analysis.keyPoints.map((point, idx) => (
                      <li key={idx} className="flex items-start gap-2 text-sm text-slate-300">
                        <span className="mt-1 text-blue-400 text-lg leading-none">•</span>
                        {point}
                      </li>
                    ))}
                  </ul>
                </section>

                <section>
                  <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3">
                    Action Items
                  </h4>
                  <div className="space-y-2">
                    {analysis.actionItems.map((item, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-3 p-3 bg-slate-900/50 rounded-xl border border-slate-700/30"
                      >
                        <div className="w-5 h-5 rounded border border-slate-600 flex items-center justify-center shrink-0">
                          <svg
                            className="w-3.5 h-3.5 text-emerald-400 opacity-0 group-hover:opacity-100"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path
                              fillRule="evenodd"
                              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                              clipRule="evenodd"
                            />
                          </svg>
                        </div>
                        <span className="text-sm text-slate-300">{item}</span>
                      </div>
                    ))}
                  </div>
                </section>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default TranscriptView
