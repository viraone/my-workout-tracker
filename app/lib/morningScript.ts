// app/lib/morningScript.ts
import type { WorkoutEntry } from '../../workoutData';

export type DaySummary = {
  date: string | null;
  muscleGroups: string[];
  exercises: string[];
};

export function summarizeLastDay(history: WorkoutEntry[]): DaySummary {
  if (!history.length) {
    return { date: null, muscleGroups: [], exercises: [] };
  }

  // 1️⃣ Prefer only completed workouts (done === true or notes include "✓ Done")
  const completed = history.filter(
    (w) =>
      w.done === true ||
      (typeof w.notes === 'string' && w.notes.includes('✓ Done'))
  );

  // If we have any completed entries, use those; otherwise fall back to all
  const source = completed.length > 0 ? completed : history;

  // 2️⃣ Find latest date in the chosen source
  let latest = source[0].date;
  for (const w of source) {
    if (w.date > latest) {
      latest = w.date;
    }
  }

  // 3️⃣ Collect muscle groups & exercises from that latest day
  const sameDay = source.filter((w) => w.date === latest);
  const muscleGroups = Array.from(new Set(sameDay.map((w) => w.muscleGroup)));
  const exercises = Array.from(new Set(sameDay.map((w) => w.exercise)));

  return {
    date: latest,
    muscleGroups,
    exercises,
  };
}


export function buildMorningScript(
  name: string,
  lastDay: DaySummary,
  todaysGroup?: string
): string {
  const pieces: string[] = [];

  pieces.push(`Good morning, ${name}.`);
  if (lastDay.date) {
    const groups = lastDay.muscleGroups.join(' and ');
    const exercises = lastDay.exercises.join(', ');
    pieces.push(
      `Yesterday, on ${lastDay.date}, you trained ${groups} with exercises like ${exercises}.`
    );
  } else {
    pieces.push(`We don't have any logged workouts yet.`);
  }

  if (todaysGroup) {
    pieces.push(`Based on your recent training, I recommend focusing on ${todaysGroup} today.`);
  }

  pieces.push(`Let's have a great workout.`);

  return pieces.join(' ');
}
