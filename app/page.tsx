'use client'; 

import React, { useState, useMemo, useEffect } from 'react'; // <-- IMPORTANT: useEffect added
import WorkoutTable from './components/WorkoutTable'; 
import WorkoutForm from './components/WorkoutForm'; 
import { historicalWorkouts as initialData, WorkoutEntry } from '../workoutData'; 

// Define types for sorting state
type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

// Define the Local Storage Key
const LOCAL_STORAGE_KEY = 'workoutTrackerData';


// ----------------------------------------------------------------------
// PAGE COMPONENT
// ----------------------------------------------------------------------

export default function Home() {
  // 1. STATE INITIALIZATION: Check Local Storage first, fall back to initialData
  const [workouts, setWorkouts] = useState<WorkoutEntry[]>(() => {
    // This function runs only once during initial component render
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (saved) {
        return JSON.parse(saved);
      }
    }
    // Fallback to the data from workoutData.ts if nothing in local storage
    return initialData;
  });
  
  const [sortBy, setSortBy] = useState<SortKey>('date'); 
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc'); 

  // 2. EFFECT: Save to Local Storage whenever 'workouts' state changes
  useEffect(() => {
    // Only save if we are running in the browser environment
    if (typeof window !== 'undefined') {
        localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(workouts));
    }
  }, [workouts]); // Dependency array: runs every time 'workouts' changes


  // Handlers for managing workout data (These remain the same)
  const addWorkoutEntry = (newEntry: WorkoutEntry) => {
    const newId = Date.now(); 
    const entryWithId = { ...newEntry, id: newId };
    setWorkouts([entryWithId, ...workouts]);
  };
  
  const updateWorkoutEntry = (indexToUpdate: number, updatedEntry: WorkoutEntry) => {
    setWorkouts(currentWorkouts => 
        currentWorkouts.map((workout, index) => {
            if (index === indexToUpdate) {
                return updatedEntry; 
            }
            return workout;
        })
    );
  };
  
  const deleteWorkoutEntry = (indexToDelete: number) => {
      const updatedWorkouts = workouts.filter((_, index) => index !== indexToDelete);
      setWorkouts(updatedWorkouts);
  };

  const handleSort = (key: SortKey) => {
    if (key === sortBy) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(key);
      setSortDirection('desc'); 
    }
  };

// Sorting Logic (Includes Secondary Sort Fix)
  const sortedWorkouts = useMemo(() => {
    if (!sortBy) return workouts;

    const sorted = [...workouts];

    sorted.sort((a, b) => {
      const aValue = a[sortBy] as any;
      const bValue = b[sortBy] as any;

      // --- PRIMARY SORT: Date ---
      if (sortBy === 'date') {
        const aDate = new Date(aValue).getTime();
        const bDate = new Date(bValue).getTime();
        
        // 1. Primary Comparison (Date)
        let comparison = sortDirection === 'asc' ? aDate - bDate : bDate - aDate;
        
        // 2. Secondary Comparison (If Dates are equal, sort by Exercise Name)
        if (comparison === 0) {
          const aExercise = a.exercise.localeCompare(b.exercise);
          return aExercise; // Sort exercises alphabetically (Ascending)
        }
        
        return comparison; // Return result of date comparison
      }
      
      // --- ALL OTHER PRIMARY SORTS (Numeric/String) ---
      
      // Handle Numeric Sorting
      if (typeof aValue === 'number' && typeof bValue === 'number') {
        if (sortDirection === 'asc') return aValue - bValue;
        return bValue - aValue;
      }

      // Handle String Sorting (Default)
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
              data={sortedWorkouts}
              onUpdateSet={updateWorkoutEntry} 
              onDeleteSet={deleteWorkoutEntry}
              onSort={handleSort}
              currentSortBy={sortBy}
              currentDirection={sortDirection}
          /> 
      </section>

    </main>
  );
}