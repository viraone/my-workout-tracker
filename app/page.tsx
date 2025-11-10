'use client'; 

import React, { useState, useMemo } from 'react'; 
import WorkoutTable from './components/WorkoutTable'; 
import WorkoutForm from './components/WorkoutForm'; 
// import FilterBar from './components/FilterBar'; // <-- COMMENTED OUT: We have not built this yet
// import VolumeChart from './components/VolumeChart'; // <-- COMMENTED OUT: We have not built this yet
import { historicalWorkouts as initialData, WorkoutEntry } from '../workoutData'; // FIX: Remove the .ts extension

// ----------------------------------------------------------------------
// PAGE COMPONENT
// ----------------------------------------------------------------------

export default function Home() {
  const [workouts, setWorkouts] = useState<WorkoutEntry[]>(initialData);
  
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

  // ------------------------------------------------------
  // Filtering Logic (Simplified for now)
  // ------------------------------------------------------
  const filteredWorkouts = workouts; // Simply display all workouts for now
  
  // Note: We can remove the "filter" state and the useMemo hook for now to keep it simpler.

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
      
      {/* CHART SECTION: REMOVED to fix the VolumeChart error 
      <section className="max-w-6xl mx-auto mb-10">
          <VolumeChart data={workouts} /> 
      </section>
      */}
      
      {/* FILTER BAR SECTION: REMOVED to fix the FilterBar error 
      <section className="max-w-6xl mx-auto mb-4">
        <FilterBar 
            muscleGroups={['All']} // Placeholder
            currentFilter={'All'}
            onFilterChange={() => {}}
        />
      </section>
      */}

      {/* DETAILED LOG TABLE */}
      <section className="max-w-6xl mx-auto mt-4"> 
          <WorkoutTable 
              data={filteredWorkouts} 
              onUpdateSet={updateWorkoutEntry} 
              onDeleteSet={deleteWorkoutEntry} 
          /> 
      </section>

    </main>
  );
}