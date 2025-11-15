// app/components/MorningGreeter.tsx
'use client';

import React, { useEffect, useMemo, useState } from 'react';
import type { WorkoutEntry } from '../../workoutData';
import { summarizeLastDay, buildMorningScript } from '../lib/morningScript';

// ------------------------------------------------------------------
// Voice hook with browser (system) voices
// ------------------------------------------------------------------
const useVoiceCoach = () => {
  const [supported, setSupported] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);
  const [selectedVoice, setSelectedVoice] = useState<string>('');
  const utteranceRef = React.useRef<SpeechSynthesisUtterance | null>(null);

  useEffect(() => {
    const isSupported =
      typeof window !== 'undefined' && 'speechSynthesis' in window;

    setSupported(isSupported);
    if (!isSupported) return;

    const loadVoices = () => {
      const v = window.speechSynthesis.getVoices();
      setVoices(v);

      // Pick a nicer default if none chosen yet
      if (!selectedVoice && v.length > 0) {
        const nicer = v.find(voice =>
          /Samantha|Ava|Daniel|Moira|Karen|Tessa|Serena|Victoria/i.test(
            voice.name
          )
        );
        setSelectedVoice((nicer || v[0]).name);
      }
    };

    loadVoices();
    window.speechSynthesis.onvoiceschanged = loadVoices;

    return () => {
      window.speechSynthesis.onvoiceschanged = null;
      window.speechSynthesis.cancel();
    };
  }, [selectedVoice]);

  const stop = () => {
    if (!supported) return;
    window.speechSynthesis.cancel();
    setSpeaking(false);
    utteranceRef.current = null;
  };

  const speak = (text: string) => {
    if (!supported || !text) return;
    stop();

    const u = new SpeechSynthesisUtterance(text);

    // Attach chosen voice
    if (selectedVoice && voices.length) {
      const voiceObj = voices.find(v => v.name === selectedVoice);
      if (voiceObj) u.voice = voiceObj;
    }

    // Slightly smoother delivery
    u.rate = 0.98;
    u.pitch = 1.02;

    utteranceRef.current = u;
    setSpeaking(true);

    u.onend = () => {
      setSpeaking(false);
      utteranceRef.current = null;
    };
    u.onerror = () => {
      setSpeaking(false);
      utteranceRef.current = null;
    };

    window.speechSynthesis.speak(u);
  };

  return {
    supported,
    speaking,
    speak,
    stop,
    voices,
    selectedVoice,
    setSelectedVoice,
  };
};

// ------------------------------------------------------------------
// Types
// ------------------------------------------------------------------
type RecommendationResponse = {
  plan: {
    group: string;
    items: { exercise: string; sets: number; reps: string }[];
    cue: string;
  };
};

interface MorningGreeterProps {
  workouts: WorkoutEntry[];
  userName?: string;
}

// OpenAI voice ids
const OPENAI_VOICES = [
  { id: 'alloy', label: 'Alloy (balanced)' },
  { id: 'nova', label: 'Nova (energetic)' },
  { id: 'echo', label: 'Echo (calm)' },
  { id: 'fable', label: 'Fable (storyteller)' },
  { id: 'onyx', label: 'Onyx (deep)' },
  { id: 'shimmer', label: 'Shimmer (light)' },
] as const;
type OpenAIVoiceId = (typeof OPENAI_VOICES)[number]['id'];

// ------------------------------------------------------------------
// Component
// ------------------------------------------------------------------
const MorningGreeter: React.FC<MorningGreeterProps> = ({
  workouts,
  userName = 'Viradeth',
}) => {
  const {
    supported,
    speaking,
    speak,
    stop,
    voices,
    selectedVoice,
    setSelectedVoice,
  } = useVoiceCoach();

  // voice mode: browser vs AI
  const [voiceMode, setVoiceMode] = useState<'browser' | 'openai'>('browser');
  const [cloudVoice, setCloudVoice] = useState<OpenAIVoiceId>('alloy');
  const [voiceLoading, setVoiceLoading] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [todayGroup, setTodayGroup] = useState<string | null>(null);

  const lastDay = useMemo(() => summarizeLastDay(workouts), [workouts]);

  // 🔁 Call /api/recommend whenever workouts change
  useEffect(() => {
    const fetchRecommendation = async () => {
      if (!workouts.length) return;

      try {
        setLoading(true);
        setError(null);
        const res = await fetch('/api/recommend', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ history: workouts }),
        });

        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          console.error('recommend error', body);
          throw new Error(body.error || 'Failed to get recommendation');
        }

        const data: RecommendationResponse = await res.json();
        setTodayGroup(data.plan.group);
      } catch (e: any) {
        console.error(e);
        setError(e.message || 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    fetchRecommendation();
  }, [workouts]);

  const script = useMemo(
    () => buildMorningScript(userName, lastDay, todayGroup ?? undefined),
    [userName, lastDay, todayGroup]
  );

  const whyLine = useMemo(() => {
    if (!lastDay.date)
      return 'No workout history yet — let’s start building it today.';
    const groups = lastDay.muscleGroups.join(' and ');
    if (todayGroup) {
      return `Because you trained ${groups} on ${lastDay.date}, I’m steering you toward ${todayGroup} today to keep your recovery and volume balanced.`;
    }
    return `Your last session on ${lastDay.date} focused on ${groups}.`;
  }, [lastDay, todayGroup]);

  // --- OpenAI cloud TTS ---
  const speakCloud = async (text: string) => {
    if (!text) return;
    try {
      setVoiceLoading(true);
      const res = await fetch('/api/voice', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, voice: cloudVoice }),
      });
      if (!res.ok) {
        console.error('TTS HTTP error', res.status);
        setVoiceLoading(false);
        return;
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audio.onended = () => setVoiceLoading(false);
      audio.onerror = () => setVoiceLoading(false);
      audio.play();
    } catch (err) {
      console.error('TTS error', err);
      setVoiceLoading(false);
    }
  };

  const handleSpeak = () => {
    if (voiceMode === 'openai') {
      // use OpenAI cloud voices
      speakCloud(script);
      return;
    }

    // use browser/system voices
    if (!supported) return;
    if (speaking) {
      stop();
    } else {
      speak(script);
    }
  };

  const buttonLabel =
    voiceMode === 'openai'
      ? voiceLoading
        ? '⏳ AI Coach…'
        : '🎧 Play AI Coach'
      : !supported
      ? 'Voice not supported'
      : speaking
      ? '🔇 Stop Coach'
      : '🔊 Play Coach';

  const buttonDisabled =
    voiceMode === 'openai' ? voiceLoading : !supported;

  return (
    <section className="max-w-6xl mx-auto mb-6">
      <div className="rounded-xl border border-gray-200 bg-white px-4 py-3 shadow-sm flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase text-indigo-600">
            AI Coach
          </div>
          <div className="text-lg font-bold text-gray-900">
            Good morning, {userName}! ☀️
          </div>
          <p className="text-sm text-gray-700 mt-1">{whyLine}</p>
          {loading && (
            <p className="text-xs text-gray-400 mt-1">
              Updating today&apos;s plan…
            </p>
          )}
          {error && (
            <p className="text-xs text-red-500 mt-1">
              Recommendation error: {error}
            </p>
          )}
        </div>

        <div className="flex flex-col items-end gap-2">
          {/* Voice mode toggle */}
          <div className="flex items-center gap-2 text-[11px] text-gray-500">
            <span>Voice mode:</span>
            <button
              type="button"
              className={`px-2 py-0.5 rounded-full border text-[11px] ${
                voiceMode === 'browser'
                  ? 'border-indigo-500 text-indigo-600 bg-indigo-50'
                  : 'border-gray-300 text-gray-500'
              }`}
              onClick={() => setVoiceMode('browser')}
            >
              Browser
            </button>
            <button
              type="button"
              className={`px-2 py-0.5 rounded-full border text-[11px] ${
                voiceMode === 'openai'
                  ? 'border-purple-500 text-purple-600 bg-purple-50'
                  : 'border-gray-300 text-gray-500'
              }`}
              onClick={() => setVoiceMode('openai')}
            >
              AI Studio
            </button>
          </div>

          {/* Voice selector (changes depending on mode) */}
          {voiceMode === 'browser' && supported && voices.length > 0 && (
            <select
              value={selectedVoice}
              onChange={e => setSelectedVoice(e.target.value)}
              className="border border-gray-300 rounded-lg px-2 py-1 text-xs sm:text-sm max-w-[200px] truncate"
            >
              {voices.map(v => (
                <option key={v.name} value={v.name}>
                  {v.name}
                  {v.lang && !v.lang.startsWith('en')
                    ? ` (${v.lang})`
                    : ''}
                </option>
              ))}
            </select>
          )}

          {voiceMode === 'openai' && (
            <select
              value={cloudVoice}
              onChange={e => setCloudVoice(e.target.value as OpenAIVoiceId)}
              className="border border-gray-300 rounded-lg px-2 py-1 text-xs sm:text-sm max-w-[200px]"
            >
              {OPENAI_VOICES.map(v => (
                <option key={v.id} value={v.id}>
                  {v.label}
                </option>
              ))}
            </select>
          )}

          {/* Play / Stop button */}
          <button
            type="button"
            onClick={handleSpeak}
            disabled={buttonDisabled}
            className={`rounded-lg px-3 py-1.5 text-sm font-medium border ${
              buttonDisabled
                ? 'border-gray-300 text-gray-400 cursor-not-allowed'
                : 'border-indigo-500 text-indigo-600 hover:bg-indigo-50'
            }`}
          >
            {buttonLabel}
          </button>
        </div>
      </div>
    </section>
  );
};

export default MorningGreeter;
