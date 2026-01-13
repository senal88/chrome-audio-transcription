
import { GoogleGenAI, Type } from "@google/genai";
import { AIAnalysis } from "../types";

export class GeminiService {
  private ai: GoogleGenAI;

  constructor() {
    this.ai = new GoogleGenAI({ apiKey: process.env.API_KEY || '' });
  }

  async analyzeTranscript(text: string): Promise<AIAnalysis> {
    const response = await this.ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: `Analyze the following transcript and provide a summary, key points, action items, and sentiment. Output in JSON format.\n\nTranscript:\n${text}`,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            summary: { type: Type.STRING },
            keyPoints: {
              type: Type.ARRAY,
              items: { type: Type.STRING }
            },
            actionItems: {
              type: Type.ARRAY,
              items: { type: Type.STRING }
            },
            sentiment: {
              type: Type.STRING,
              description: "Must be 'positive', 'neutral', or 'negative'"
            }
          },
          required: ["summary", "keyPoints", "actionItems", "sentiment"]
        }
      }
    });

    try {
      return JSON.parse(response.text || '{}') as AIAnalysis;
    } catch (e) {
      console.error("Failed to parse Gemini response", e);
      throw new Error("Invalid AI response");
    }
  }

  async chatWithTranscript(text: string, question: string): Promise<string> {
    const chat = this.ai.chats.create({
      model: 'gemini-3-flash-preview',
      config: {
        systemInstruction: `You are an AI assistant helping a user understand a transcription. Use the provided context to answer questions accurately. Transcript context: ${text}`,
      }
    });

    const result = await chat.sendMessage({ message: question });
    return result.text || "I couldn't generate an answer.";
  }
}

export const geminiService = new GeminiService();
