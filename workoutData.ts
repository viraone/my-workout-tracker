// workoutData.ts

export interface WorkoutEntry {
  id: number; // <-- NEW: Unique ID is essential for stability
  date: string; // e.g., '15-11-08'
  exercise: string;
  set: number;
  weightLbs: number;
  reps: number;
  muscleGroup: 'Biceps' | 'Back' | 'Chest' | 'Legs' | 'Shoulders' | string;
  notes: string;
}

// Data from your initial Excel Sheet (Now with unique IDs)
export const historicalWorkouts: WorkoutEntry[] = [
  { id: 1, date: '15-11-08', exercise: 'Dumbbell Single Biceps Curl', set: 1, weightLbs: 15, reps: 10, muscleGroup: 'Biceps', notes: '' },
  { id: 2, date: '15-11-08', exercise: 'Dumbbell Single Biceps Curl', set: 2, weightLbs: 17.5, reps: 10, muscleGroup: 'Biceps', notes: '' },
  { id: 3, date: '15-11-08', exercise: 'Dumbbell Single Biceps Curl', set: 3, weightLbs: 17.5, reps: 10, muscleGroup: 'Biceps', notes: '' },
  { id: 4, date: '15-11-08', exercise: 'Lat Pulldown', set: 1, weightLbs: 85, reps: 8, muscleGroup: 'Back', notes: '' },
  { id: 5, date: '15-11-08', exercise: 'Lat Pulldown', set: 2, weightLbs: 85, reps: 10, muscleGroup: 'Back', notes: '' },
  { id: 6, date: '15-11-08', exercise: 'Lat Pulldown', set: 3, weightLbs: 85, reps: 10, muscleGroup: 'Back', notes: '' },
  { id: 7, date: '15-11-09', exercise: 'Dumbbell Bench Press', set: 1, weightLbs: 30, reps: 12, muscleGroup: 'Chest', notes: '' },
];