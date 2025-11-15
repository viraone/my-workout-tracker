'use client';

import React, { useState, useMemo, useEffect } from 'react';
import WorkoutTable from './components/WorkoutTable';
import WorkoutForm from './components/WorkoutForm';
import MorningGreeter from './components/MorningGreeter'; // 🔊 NEW
import {
  historicalWorkouts as initialData,
  WorkoutEntry,
} from '../workoutData';

// sorting state types
type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

// localStorage key
const LOCAL_STORAGE_KEY = 'workoutTrackerData';

export default function Home() {
  // 1) state init with localStorage fallback
  const [workouts, setWorkouts] = useState<WorkoutEntry[]>(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (saved) return JSON.parse(saved);
    }
    return initialData;
  });

  const [sortBy, setSortBy] = useState<SortKey>('date');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');

  // 2) persist to localStorage
  useEffect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(workouts));
    }
  }, [workouts]);

  // 3) add / update / delete
  const addWorkoutEntry = (newEntryData: Omit<WorkoutEntry, 'id'>) => {
    const maxId = workouts.length ? Math.max(...workouts.map(w => w.id)) : 0;
    const entryWithId: WorkoutEntry = { ...newEntryData, id: maxId + 1 };
    setWorkouts(prev => [entryWithId, ...prev]);
  };

  const updateWorkoutEntry = (indexToUpdate: number, updatedEntry: WorkoutEntry) => {
    setWorkouts(prev => prev.map((w, i) => (i === indexToUpdate ? updatedEntry : w)));
  };

  const deleteWorkoutEntry = (indexToDelete: number) => {
    setWorkouts(prev => prev.filter((_, i) => i !== indexToDelete));
  };

  // 4) mark a row as done (appends ✓ Done in notes)
  const markDone = (indexToMark: number) => {
    setWorkouts(prev =>
      prev.map((w, i) =>
        i === indexToMark
          ? {
              ...w,
              notes: w.notes?.includes('✓ Done')
                ? w.notes
                : (w.notes ? `${w.notes} | ` : '') + '✓ Done',
            }
          : w
      )
    );
  };

  // 5) sorting
  const handleSort = (key: SortKey) => {
    if (key === sortBy) {
      setSortDirection(d => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(key);
      setSortDirection('desc');
    }
  };

  const sortedWorkouts = useMemo(() => {
    if (!sortBy) return workouts;
    const sorted = [...workouts];

    sorted.sort((a, b) => {
      const aValue = a[sortBy] as any;
      const bValue = b[sortBy] as any;

      if (sortBy === 'date') {
        const aDate = new Date(aValue).getTime();
        const bDate = new Date(bValue).getTime();
        let cmp = sortDirection === 'asc' ? aDate - bDate : bDate - aDate;
        if (cmp === 0) return a.exercise.localeCompare(b.exercise);
        return cmp;
      }

      if (typeof aValue === 'number' && typeof bValue === 'number') {
        return sortDirection === 'asc' ? aValue - bValue : bValue - aValue;
      }
      const aStr = String(aValue);
      const bStr = String(bValue);
      return sortDirection === 'asc' ? aStr.localeCompare(bStr) : bStr.localeCompare(aStr);
    });

    return sorted;
  }, [workouts, sortBy, sortDirection]);

  return (
    <main className="min-h-screen bg-gray-50 p-4 sm:p-8">
      {/* Header */}
      <header className="max-w-6xl mx-auto mb-6">
        <h1 className="text-4xl font-extrabold text-gray-900">Dashboard</h1>
        <p className="text-lg text-indigo-600 mt-1">
          Welcome back, let&apos;s check your progress.
        </p>
      </header>

      {/* 🔊 AI Coach (voice + explanation) */}
      <MorningGreeter workouts={workouts} userName="Viradeth" />

      {/* Form */}
      <section className="max-w-6xl mx-auto mb-10">
        <WorkoutForm onAddSet={addWorkoutEntry} />
      </section>

      {/* Table */}
      <section className="max-w-6xl mx-auto mt-4">
        <WorkoutTable
          data={sortedWorkouts}
          onUpdateSet={updateWorkoutEntry}
          onDeleteSet={deleteWorkoutEntry}
          onSort={handleSort}
          currentSortBy={sortBy}
          currentDirection={sortDirection}
          onMarkDone={markDone}
        />
      </section>
    </main>
  );
}
