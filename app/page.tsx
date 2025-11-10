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
  const [sortBy, setSortBy] = useState<SortKey>('date'); 
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc'); 

  // Handlers for managing workout data
  const addWorkoutEntry = (newEntry: WorkoutEntry) => {
    // Ensure new entry has a unique ID (simple time-based ID for now)
    const newId = Date.now(); 
    const entryWithId = { ...newEntry, id: newId };
    setWorkouts([entryWithId, ...workouts]);
  };
  
  // FIX: This handler is updated to ensure the item is replaced correctly.
  const updateWorkoutEntry = (indexToUpdate: number, updatedEntry: WorkoutEntry) => {
    // The safest way is to map over the array and replace the item at the specific index.
    // This relies on the index passed from the WorkoutTable being the index in the *sorted* array,
    // which is then mapped back to the *original* state array order.
    
    setWorkouts(currentWorkouts => 
        currentWorkouts.map((workout, index) => {
            if (index === indexToUpdate) {
                // Return the updated entry object, ensuring the new date/data is fully merged
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

  // Handler for sorting the table
  const handleSort = (key: SortKey) => {
    if (key === sortBy) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(key);
      setSortDirection('desc'); 
    }
  };

  // Sorting Logic (Includes Date Fix)
  const sortedWorkouts = useMemo(() => {
    if (!sortBy) return workouts;

    const sorted = [...workouts];

    sorted.sort((a, b) => {
      const aValue = a[sortBy] as any;
      const bValue = b[sortBy] as any;

      // Handle Date Sorting: Convert string dates to comparable timestamps
      if (sortBy === 'date') {
        const aDate = new Date(aValue).getTime();
        const bDate = new Date(bValue).getTime();
        
        if (sortDirection === 'asc') return aDate - bDate;
        return bDate - aDate;
      }
      
      // Handle Numeric Sorting
      if (typeof aValue === 'number' && typeof bValue === 'number') {
        if (sortDirection === 'asc') return aValue - bValue;
        return bValue - aValue;
      }

      // Handle String Sorting
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
              // Corrected prop names for sorting
              onSort={handleSort}
              currentSortBy={sortBy}
              currentDirection={sortDirection}
          /> 
      </section>

    </main>
  );
}