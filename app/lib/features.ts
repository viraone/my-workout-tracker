// app/lib/features.ts
// THIS IS THE ONE THE /api/recommend ROUTE IMPORTS

import { WorkoutEntry } from '../../workoutData';

const DAY = 24 * 60 * 60 * 1000;

// What this returns: one feature row per muscle group
// - group: the muscle group name (e.g., "Chest")
// - x: [daysSinceLast, vol7dNorm, avgRepsNorm]
// - y: label heuristic (1 = ready today, 0 = rest)
export function buildTodayFeatures(
  all: WorkoutEntry[],
  groups: string[] = [],
  today: Date = new Date()
): Array<{ group: string; x: [number, number, number]; y: 0 | 1 }> {
  const byGroup =
    groups.length > 0 ? groups : Array.from(new Set(all.map(s => s.muscleGroup)));

  // 7-day volume per group
  const vol7ByGroup: Record<string, number> = {};
  for (const g of byGroup) vol7ByGroup[g] = sumVolInWindow(all, g, today, 7);

  const volMedian = median(Object.values(vol7ByGroup)) || 1;

  return byGroup.map(g => {
    const last = lastSession(all, g);
    const daysSince = last
      ? Math.max(0, Math.floor((+today - +new Date(last.date)) / DAY))
      : 99;

    const v7 = vol7ByGroup[g] || 0;
    const v7Norm = normalize(v7, 0, volMedian * 2); // scale around median

    const avgReps = last ? last.reps : 10;
    const avgRepsNorm = normalize(avgReps, 5, 15);

    // Heuristic label:
    // ready if we’ve had enough rest for this group AND
    // recent volume isn’t excessively high.
    const rested = daysSince >= minRest(g);
    const ready = rested && v7 <= volMedian * 1.25 ? 1 : 0;

    return {
      group: g,
      x: [daysSince, v7Norm, avgRepsNorm],
      y: ready as 0 | 1,
    };
  });
}

/* ---------------- helpers ---------------- */

function lastSession(all: WorkoutEntry[], group: string) {
  return all
    .filter(s => s.muscleGroup === group)
    .sort((a, b) => +new Date(b.date) - +new Date(a.date))[0];
}

function sumVolInWindow(
  all: WorkoutEntry[],
  group: string,
  ref: Date,
  days: number
) {
  const start = new Date(+ref - days * DAY);
  return all
    .filter(
      s =>
        s.muscleGroup === group &&
        new Date(s.date) >= start &&
        new Date(s.date) <= ref
    )
    .reduce((a, s) => a + (s.weightLbs || 0) * (s.reps || 0), 0);
}

function normalize(v: number, min: number, max: number) {
  if (max <= min) return 0;
  const c = Math.max(min, Math.min(max, v));
  return (c - min) / (max - min);
}

function median(arr: number[]) {
  if (!arr.length) return 0;
  const s = [...arr].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

function minRest(group: string) {
  const map: Record<string, number> = {
    Chest: 2,
    Back: 2,
    Shoulders: 2,
    Legs: 3,
    Biceps: 1,
    Triceps: 1,
    Quads: 3,
    Hamstrings: 3,
    Glutes: 2,
    Abs: 1,
  };
  return map[group] ?? 2;
}
