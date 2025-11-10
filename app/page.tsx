'use client'; 

import React, { useState, useMemo } from 'react'; 
import WorkoutTable from './components/WorkoutTable'; 
import WorkoutForm from './components/WorkoutForm'; 
import { historicalWorkouts as initialData, WorkoutEntry } from '../workoutData'; 

// Define types for sorting state
type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

// ----------------------------------------------------------------------
// PAGE COMPONENT
// ----------------------------------------------------------------------

export default function Home() {
  const [workouts, setWorkouts] = useState<WorkoutEntry[]>(initialData);
  // NEW State: Tracking sort settings
  const [sortBy, setSortBy] = useState<SortKey>('date'); 
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc'); 

  // Handlers for managing workout data
  const addWorkoutEntry = (newEntry: WorkoutEntry) => {
    setWorkouts([newEntry, ...workouts]);
  };
  
  const updateWorkoutEntry = (indexToUpdate: number, updatedEntry: WorkoutEntry) => {
    const updatedWorkouts = [...workouts];
    updatedWorkouts[indexToUpdate] = updatedEntry;
    setWorkouts(updatedWorkouts);
  };
  
  const deleteWorkoutEntry = (indexToDelete: number) => {
      const updatedWorkouts = workouts.filter((_, index) => index !== indexToDelete);
      setWorkouts(updatedWorkouts);
  };

  // NEW: Handler for sorting the table
  const handleSort = (key: SortKey) => {
    if (key === sortBy) {
      // If same key is clicked, reverse direction
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      // If new key is clicked, set new key and default to descending
      setSortBy(key);
      setSortDirection('desc'); 
    }
  };

  // Sorting Logic using useMemo (to prevent unnecessary recalculations)
  const sortedWorkouts = useMemo(() => {
    if (!sortBy) return workouts;

    const sorted = [...workouts];

    sorted.sort((a, b) => {
      const aValue = a[sortBy] as any;
      const bValue = b[sortBy] as any;
      
      // Handle numeric sorting (Weight, Reps, Set)
      if (typeof aValue === 'number' && typeof bValue === 'number') {
        if (sortDirection === 'asc') return aValue - bValue;
        return bValue - aValue;
      }

      // Handle string/date sorting (Date, Exercise, Muscle Group). Crucially sorts by date correctly.
      const aString = String(aValue);
      const bString = String(bValue);
      
      if (sortDirection === 'asc') return aString.localeCompare(bString);
      return bString.localeCompare(aString);
    });

    return sorted;
  }, [workouts, sortBy, sortDirection]);


  return (
    <main className="min-h-screen bg-gray-50 p-4 sm:p-8">
      
      {/* Header Section */}
      <header className="max-w-6xl mx-auto mb-8">
        <h1 className="4xl font-extrabold text-gray-900">Dashboard</h1>
        <p className="lg text-indigo-600 mt-1">Welcome back, let's check your progress.</p>
      </header>

      {/* FORM SECTION (Log New Set) */}
      <section className="max-w-6xl mx-auto mb-10">
        <WorkoutForm onAddSet={addWorkoutEntry} /> 
      </section>
      
      {/* DETAILED LOG TABLE */}
      <section className="max-w-6xl mx-auto mt-4"> 
          <WorkoutTable 
              data={sortedWorkouts} // Pass the sorted data
              onUpdateSet={updateWorkoutEntry} 
              onDeleteSet={deleteWorkoutEntry}
              // Pass the sorting state and handler
              onSort={handleSort}
              sortBy={sortBy}
              sortDirection={sortDirection}
          /> 
      </section>

    </main>
  );
}