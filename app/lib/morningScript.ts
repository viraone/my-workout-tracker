// app/lib/morningScript.ts
import type { WorkoutEntry } from '../../workoutData';

export type DaySummary = {
  date: string | null;
  muscleGroups: string[];
  exercises: string[];
};

export type TodayPlanItem = {
  exercise: string;
  sets: number;
  reps: string;
  targetWeightLbs?: number | null;
  notes?: string;
};

export type TodayPlan = {
  group: string;
  items: TodayPlanItem[];
  cue: string;
};

export function summarizeLastDay(history: WorkoutEntry[]): DaySummary {
  if (!history.length) return { date: null, muscleGroups: [], exercises: [] };

  // Find latest date (string compare is fine for YYYY-MM-DD)
  const latest = history.reduce(
    (max, w) => (w.date > max ? w.date : max),
    history[0].date
  );

  const sameDay = history.filter((w) => w.date === latest);
  const groups = Array.from(new Set(sameDay.map((w) => w.muscleGroup)));
  const exercises = Array.from(new Set(sameDay.map((w) => w.exercise)));

  return {
    date: latest,
    muscleGroups: groups,
    exercises,
  };
}

export function buildMorningScript(
  name: string,
  lastDay: DaySummary,
  todayPlan?: TodayPlan
): string {
  const pieces: string[] = [];

  // Greeting only
  pieces.push(`Good morning, ${name}.`);

  // Optional: VERY short mention of focus (no “because you trained…” logic)
  if (todayPlan) {
    pieces.push(`Today’s focus is ${todayPlan.group}.`);
  }

  pieces.push(`Let’s have a great workout.`);

  return pieces.join(' ');
}

