// app/lib/exercises.ts
import { WorkoutEntry } from '../../workoutData';

/** Simple exercise templates per muscle group */
export type ExerciseBlock = {
  name: string;
  sets: number;
  reps: [number, number];   // [min, max]
  emphasis?: string;        // coaching cue
};

export const PLAN_LIBRARY: Record<string, ExerciseBlock[]> = {
  Chest: [
    { name: 'Dumbbell Bench Press', sets: 3, reps: [8, 12], emphasis: '3s down, drive up' },
    { name: 'Incline DB Press',     sets: 3, reps: [8, 12] },
    { name: 'DB/Cable Fly',         sets: 3, reps: [12, 15], emphasis: 'slow stretch, squeeze' },
  ],
  Back: [
    { name: 'Lat Pulldown',       sets: 3, reps: [8, 12] },
    { name: 'Seated Cable Row',   sets: 3, reps: [8, 12] },
    { name: 'Face Pull',          sets: 3, reps: [12, 15] },
  ],
  Shoulders: [
    { name: 'DB Overhead Press',  sets: 3, reps: [6, 10] },
    { name: 'Lateral Raise',      sets: 4, reps: [12, 15] },
    { name: 'Rear Delt Fly',      sets: 3, reps: [12, 15] },
  ],
  Biceps: [
    { name: 'DB Curl',            sets: 3, reps: [8, 12] },
    { name: 'Incline DB Curl',    sets: 3, reps: [10, 12] },
    { name: 'Cable Curl',         sets: 3, reps: [12, 15] },
  ],
  Triceps: [
    { name: 'Cable Pressdown',    sets: 3, reps: [10, 12] },
    { name: 'Overhead Rope Ext',  sets: 3, reps: [10, 12] },
    { name: 'Bench Dips',         sets: 3, reps: [12, 15] },
  ],
  Legs: [
    { name: 'Goblet Squat',       sets: 4, reps: [8, 12] },
    { name: 'Romanian Deadlift',  sets: 3, reps: [6, 10] },
    { name: 'Walking Lunge',      sets: 3, reps: [10, 12] },
  ],
};

/** Helper: find the most recent weight you used for an exercise (fuzzy by name contains). */
function lastWeightFor(exName: string, history: WorkoutEntry[]): number | null {
  const hit = history
    .filter(s => s.exercise.toLowerCase().includes(exName.toLowerCase()))
    .sort((a, b) => +new Date(b.date) - +new Date(a.date))[0];
  return hit ? hit.weightLbs : null;
}

/** Very light progression:
 * - if we have a prior weight, suggest repeating it the first time,
 *   then +2.5–5% next session if all sets reached the top of the rep range (user can adjust).
 * For now we just return the prior weight as a target to keep it simple.
 */
function suggestedWeight(exName: string, history: WorkoutEntry[]): number | null {
  return lastWeightFor(exName, history); // keep it simple to start
}

/** Build a concrete plan (exercises + sets×reps + optional target weight) for a group */
export function buildPlanForGroup(group: string, history: WorkoutEntry[] = []) {
  const blocks = PLAN_LIBRARY[group] ?? [];
  const items = blocks.map(b => ({
    exercise: b.name,
    sets: b.sets,
    reps: `${b.reps[0]}–${b.reps[1]}`,
    targetWeightLbs: suggestedWeight(b.name, history),
    notes: b.emphasis ?? '',
  }));

  const cue =
    'Aim RPE ~7 on your top set. If you hit the high rep target with solid form, go +2.5–5% next time.';

  return { group, items, cue };
}
