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
  done?: boolean;                    // ✅ Marked done by user
  doneAt?: string;                   // ISO timestamp when marked done
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
