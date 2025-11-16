// app/workoutData.ts

// ---------------------------------------------------------------------
// Data model for all workout entries
// ---------------------------------------------------------------------
export interface WorkoutEntry {
  id: number;                        // Unique row identifier
  date: string;                      // e.g., "2025-11-08"
  exercise: string;                  // Exercise name
  set: number;                       // Set number
  weightLbs: number;                 // Weight used
  reps: number;                      // Repetitions
  muscleGroup:
    | 'Biceps'
    | 'Back'
    | 'Chest'
    | 'Legs'
    | 'Shoulders'
    | string;                        // Flexible for new groups
  notes: string;                     // Optional note per set
  done?: boolean;                    // Marked done by user
  doneAt?: string;                   // ISO timestamp when marked done
}

// ---------------------------------------------------------------------
// AI Plan model (what the coach suggests for the day)
// ---------------------------------------------------------------------
export interface AiPlanExercise {
  name: string;
  sets: number;
  targetReps: string; // e.g. "8–12"
  muscleGroup: WorkoutEntry['muscleGroup'];
  notes: string;
}

// Example: today's AI Plan (Chest day)
export const todaysAiPlan: AiPlanExercise[] = [
  {
    name: 'Dumbbell Bench Press',
    sets: 3,
    targetReps: '8–12',
    muscleGroup: 'Chest',
    notes: 'Controlled tempo, slight pause on chest.',
  },
  {
    name: 'Incline DB Press',
    sets: 3,
    targetReps: '10–12',
    muscleGroup: 'Chest',
    notes: "Don’t flare the elbows.",
  },
  {
    name: 'Cable Fly',
    sets: 3,
    targetReps: '12–15',
    muscleGroup: 'Chest',
    notes: 'Slow stretch and squeeze.',
  },
];

// ---------------------------------------------------------------------
// Helper: turn AI Plan into WorkoutEntry rows for the Exercise Table
// ---------------------------------------------------------------------
export function createEntriesFromAiPlan(
  plan: AiPlanExercise[],
  date: string,
  startingId: number
): WorkoutEntry[] {
  const rows: WorkoutEntry[] = [];
  let id = startingId;

  for (const ex of plan) {
    for (let set = 1; set <= ex.sets; set++) {
      rows.push({
        id: id++,
        date,
        exercise: ex.name,
        set,
        weightLbs: 0,        // user will fill this in
        reps: 0,             // user will fill this in
        muscleGroup: ex.muscleGroup,
        notes: ex.notes,
        done: false,
      });
    }
  }

  return rows;
}

// ---------------------------------------------------------------------
// Example seed data (from your original workout log)
// ---------------------------------------------------------------------
export const historicalWorkouts: WorkoutEntry[] = [
  {
    id: 1,
    date: '2025-11-08',
    exercise: 'Dumbbell Single Biceps Curl',
    set: 1,
    weightLbs: 15,
    reps: 10,
    muscleGroup: 'Biceps',
    notes: '',
    done: true,
    doneAt: '2025-11-08T14:30:00Z',
  },
  {
    id: 2,
    date: '2025-11-08',
    exercise: 'Dumbbell Single Biceps Curl',
    set: 2,
    weightLbs: 17.5,
    reps: 10,
    muscleGroup: 'Biceps',
    notes: '',
    done: true,
    doneAt: '2025-11-08T14:34:00Z',
  },
  {
    id: 3,
    date: '2025-11-08',
    exercise: 'Dumbbell Single Biceps Curl',
    set: 3,
    weightLbs: 17.5,
    reps: 10,
    muscleGroup: 'Biceps',
    notes: '',
    done: true,
    doneAt: '2025-11-08T14:37:00Z',
  },
];
