// app/api/recommend/route.ts
import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

// 🔹 Match your real WorkoutEntry shape from app/workoutData.ts
type WorkoutEntry = {
  id: number;
  date: string;          // "2025-11-08"
  exercise: string;      // "Dumbbell Single Biceps Curl"
  set: number;
  weightLbs: number;
  reps: number;
  muscleGroup: string;   // "Biceps", "Back", etc.
  notes: string;
  done?: boolean;
  doneAt?: string;
};

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Minimal shape your frontend expects from /api/recommend:
type PlanItem = {
  exercise: string;
  sets: number;
  reps: string;
  targetWeightLbs?: number | null;
  notes?: string;
};

type GPTPlanResponse = {
  plan: {
    group: string;
    items: PlanItem[];
    cue: string;
  };
};

// Small helper: collapse your flat WorkoutEntry[] into per-day summaries
function summarizeHistoryForGPT(history: WorkoutEntry[]) {
  // Group by date
  const byDate = new Map<string, WorkoutEntry[]>();
  for (const w of history) {
    if (!byDate.has(w.date)) byDate.set(w.date, []);
    byDate.get(w.date)!.push(w);
  }

  // Turn into compact daily summaries
  const sessions = Array.from(byDate.entries())
    .sort(([d1], [d2]) => new Date(d2).getTime() - new Date(d1).getTime()) // most recent first
    .map(([date, entries]) => {
      const muscleGroups = Array.from(
        new Set(entries.map((e) => e.muscleGroup))
      );

      const exercises = Array.from(
        new Set(entries.map((e) => e.exercise))
      );

      const totalSets = entries.length;
      const totalReps = entries.reduce((sum, e) => sum + (e.reps || 0), 0);

      return {
        date,
        muscleGroups,
        exercises,
        totalSets,
        totalReps,
        entries, // keep raw entries in case GPT wants details
      };
    });

  return sessions;
}

// Simple GET so visiting /api/recommend in a browser shows something useful
export async function GET() {
  return NextResponse.json({
    ok: true,
    usage: 'POST { history: WorkoutEntry[] } to get recommendations',
  });
}

export async function POST(req: NextRequest) {
  if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY is missing');
    return NextResponse.json(
      { error: 'Server is missing OPENAI_API_KEY env var' },
      { status: 500 }
    );
  }

  const body = await req.json().catch(() => null);
  const history: WorkoutEntry[] = Array.isArray(body?.history)
    ? body.history
    : [];

  // Safety: cap history length so we don't send infinite logs
  const trimmedHistory = history.slice(0, 200);
  const sessionSummaries = summarizeHistoryForGPT(trimmedHistory);

  // 🧠 This is the "brain" prompt for your coach
  const userContent = `
You are an upbeat, evidence-based strength coach.
You are helping a lifter named Viradeth plan today's workout.

Their recent workout *sessions* (most-recent-first) are:

${JSON.stringify(sessionSummaries, null, 2)}

Each "entries" array contains individual sets from that day, with:
- date
- exercise
- set number
- weightLbs
- reps
- muscleGroup
- notes
- done / doneAt (may be present)

Coaching rules:

- Look at RECENCY and MUSCLE GROUP balance across days.
- Avoid hitting the exact same primary muscle group two days in a row,
  unless the previous session for that muscle group was clearly low volume.
- Choose ONE primary muscle group for today
  (e.g. "Chest", "Back", "Legs", "Shoulders", "Biceps").
- Design 3 simple exercises with practical rep ranges.
- Keep exercise names gym-realistic (things you’d actually see on a program).
- If there is no history, start with a beginner-friendly full-body or upper-body day.
- Keep wording short and clear — this will be read aloud by a text-to-speech coach.

Return ONLY valid JSON in this exact shape:

{
  "plan": {
    "group": "Chest",
    "items": [
      { "exercise": "Dumbbell Bench Press", "sets": 3, "reps": "8–12", "targetWeightLbs": null, "notes": "Controlled tempo, slight pause on chest." },
      { "exercise": "Incline DB Press",      "sets": 3, "reps": "10–12", "targetWeightLbs": null, "notes": "Don’t flare the elbows." },
      { "exercise": "Cable Fly",             "sets": 3, "reps": "12–15", "targetWeightLbs": null, "notes": "Slow stretch and squeeze." }
    ],
    "cue": "Aim for RPE 7–8 on your hardest set. If it feels easy, add a little weight next time."
  }
}

- "targetWeightLbs" may be null if you’re not sure.
- No extra keys, no explanations outside the JSON.
`.trim();

  try {
    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content:
            'You are a concise, positive lifting coach who writes short, practical instructions.',
        },
        {
          role: 'user',
          content: userContent,
        },
      ],
    });

    const content = completion.choices[0].message.content;
    if (!content) {
      throw new Error('Empty completion from GPT');
    }

    const parsed = JSON.parse(content) as GPTPlanResponse;
    const plan = parsed.plan;

    // Normalize items a bit to keep the front-end happy
    const normalizedItems: PlanItem[] = (plan.items || []).map((it) => ({
      exercise: it.exercise,
      sets: Number(it.sets) || 3,
      reps: String(it.reps ?? '8–12'),
      targetWeightLbs:
        it.targetWeightLbs === undefined ? null : it.targetWeightLbs,
      notes: it.notes ?? '',
    }));

    const finalPlan = {
      group: plan.group,
      items: normalizedItems,
      cue: plan.cue,
    };

    // Match your existing PlanResponse shape
    const recommendations = [
      {
        muscleGroup: finalPlan.group,
        readyScore: 0.95,
        ready: true,
      },
    ];
    const chosen = recommendations[0];

    return NextResponse.json({
      recommendations,
      chosen,
      plan: finalPlan,
    });
  } catch (err: any) {
    console.error('GPT coach error:', err);

    const message =
      err?.response?.data?.error?.message ||
      err?.error?.message ||
      err?.message ||
      'Recommendation failed';

    return NextResponse.json({ error: message }, { status: 500 });
  }
}
