// app/api/voice/route.ts
import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';
import { Buffer } from 'node:buffer';

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function POST(req: NextRequest) {
  const { text, voice = 'alloy' } = await req.json();

  // 🔐 Extra safety: make sure the key is actually there
  if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY is missing');
    return NextResponse.json(
      { error: 'Server is missing OPENAI_API_KEY env var' },
      { status: 500 }
    );
  }

  if (!text) {
    return NextResponse.json(
      { error: 'Missing text' },
      { status: 400 }
    );
  }

  try {
    const response = await client.audio.speech.create({
      model: 'gpt-4o-mini-tts',
      voice,
      input: text,
      // format: 'mp3', // optional – mp3 is default
    });

    const audioArrayBuffer = await response.arrayBuffer();
    const audioBuffer = Buffer.from(audioArrayBuffer);

    return new NextResponse(audioBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'audio/mpeg',
      },
    });
  } catch (err: any) {
    console.error('TTS error:', err);

    const message =
      err?.response?.data?.error?.message ||
      err?.error?.message ||
      err?.message ||
      'TTS failed';

    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
