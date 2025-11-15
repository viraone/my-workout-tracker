// app/lib/tts/webSpeech.ts

let isSpeaking = false;

export function canUseWebSpeech(): boolean {
  return typeof window !== 'undefined' && 'speechSynthesis' in window;
}

export function cancelWebSpeech() {
  if (!canUseWebSpeech()) return;
  window.speechSynthesis.cancel();
  isSpeaking = false;
}

export function speakWithWebSpeech(
  text: string,
  opts: {
    rate?: number;
    pitch?: number;
    volume?: number;
    voiceName?: string;
  } = {}
) {
  if (!canUseWebSpeech()) {
    console.warn('[AI Coach] Web Speech API not available in this browser.');
    return;
  }

  const synth = window.speechSynthesis;
  cancelWebSpeech(); // clear any previous utterances

  const utter = new SpeechSynthesisUtterance(text);
  utter.rate = opts.rate ?? 1.0;
  utter.pitch = opts.pitch ?? 1.0;
  utter.volume = opts.volume ?? 1.0;

  if (opts.voiceName) {
    const voices = synth.getVoices();
    const match = voices.find((v) => v.name.includes(opts.voiceName!));
    if (match) utter.voice = match;
  }

  utter.onstart = () => {
    isSpeaking = true;
  };
  utter.onend = () => {
    isSpeaking = false;
  };
  utter.onerror = (e) => {
    console.error('[AI Coach] speech error', e);
    isSpeaking = false;
  };

  synth.speak(utter);
}

export function getIsSpeaking() {
  return isSpeaking;
}
