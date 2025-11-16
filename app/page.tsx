// app/page.tsx
'use client';

import React, { useState, useMemo, useEffect } from 'react';
import WorkoutTable from './components/WorkoutTable';
import WorkoutForm from './components/WorkoutForm';
import MorningGreeter from './components/MorningGreeter';
import {
  historicalWorkouts as initialData,
  WorkoutEntry,
} from '../workoutData';

// sorting state types
type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

// localStorage key
const LOCAL_STORAGE_KEY = 'workoutTrackerData';

// ---------- Types for AI plan ----------
type PlanItem = {
  exercise: string;
  sets: number;
  reps: string;
  targetWeightLbs: number | null;
  notes?: string;
};

type PlanResponse = {
  recommendations: { muscleGroup: string; readyScore: number; ready: boolean }[];
  chosen: { muscleGroup: string; readyScore: number; ready: boolean };
  plan: { group: string; items: PlanItem[]; cue: string };
};

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
    const maxId = workouts.length ? Math.max(...workouts.map((w) => w.id)) : 0;
    const entryWithId: WorkoutEntry = { ...newEntryData, id: maxId + 1 };
    setWorkouts((prev) => [entryWithId, ...prev]);
  };

  const updateWorkoutEntry = (indexToUpdate: number, updatedEntry: WorkoutEntry) => {
    setWorkouts((prev) => prev.map((w, i) => (i === indexToUpdate ? updatedEntry : w)));
  };

  const deleteWorkoutEntry = (indexToDelete: number) => {
    setWorkouts((prev) => prev.filter((_, i) => i !== indexToDelete));
  };

  // 4) mark a row as done (appends ✓ Done in notes)
  const markDone = (indexToMark: number) => {
    setWorkouts((prev) =>
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
      setSortDirection((d) => (d === 'asc' ? 'desc' : 'asc'));
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

  // 6) NEW: fetch AI recommendation (GPT Coach) when workouts change
  const [planRec, setPlanRec] = useState<PlanResponse | null>(null);
  const [planLoading, setPlanLoading] = useState(false);
  const [planError, setPlanError] = useState<string | null>(null);

  useEffect(() => {
    const fetchPlan = async () => {
      if (!workouts.length) return;

      try {
        setPlanLoading(true);
        setPlanError(null);
        const res = await fetch('/api/recommend', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ history: workouts }),
        });

        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `HTTP ${res.status}`);
        }

        const data: PlanResponse = await res.json();
        setPlanRec(data);
      } catch (e: any) {
        console.error('AI plan error', e);
        setPlanError(e?.message || 'Failed to load AI plan');
      } finally {
        setPlanLoading(false);
      }
    };

    fetchPlan();
  }, [workouts]);

  const todayPlan = planRec?.plan ?? null;

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
      <MorningGreeter workouts={workouts} userName="Viradeth" todayPlan={todayPlan} />

      {/* ✅ NEW: Today’s AI Plan checklist */}
      <section className="max-w-6xl mx-auto mb-6">
        <div className="rounded-xl border bg-white px-4 py-3 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-sm font-semibold text-gray-800">
              Today&apos;s AI Plan
            </h2>
            {todayPlan && (
              <span className="inline-flex items-center rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-medium text-indigo-700">
                Focus: {todayPlan.group}
              </span>
            )}
          </div>

          {planLoading && (
            <p className="text-xs text-gray-400">Loading today&apos;s plan…</p>
          )}

          {planError && (
            <p className="text-xs text-red-500">AI plan error: {planError}</p>
          )}

          {!planLoading && !planError && todayPlan && (
            <>
              <div className="overflow-x-auto">
                <table className="min-w-full text-left text-xs sm:text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="py-2 pr-4 font-semibold text-gray-600">
                        Exercise
                      </th>
                      <th className="py-2 pr-4 font-semibold text-gray-600">
                        Sets
                      </th>
                      <th className="py-2 pr-4 font-semibold text-gray-600">
                        Reps
                      </th>
                      <th className="py-2 pr-4 font-semibold text-gray-600">
                        Notes
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {todayPlan.items.map((it, idx) => (
                      <tr key={idx} className="border-b last:border-0">
                        <td className="py-2 pr-4 text-gray-900">
                          {it.exercise}
                        </td>
                        <td className="py-2 pr-4 text-gray-700">
                          {it.sets}
                        </td>
                        <td className="py-2 pr-4 text-gray-700">
                          {it.reps}
                        </td>
                        <td className="py-2 pr-4 text-gray-500">
                          {it.notes || ''}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {todayPlan.cue && (
                <p className="mt-2 text-xs text-gray-500">
                  Coach cue: {todayPlan.cue}
                </p>
              )}
            </>
          )}

          {!planLoading && !planError && !todayPlan && (
            <p className="text-xs text-gray-400">
              No AI plan yet — log a workout to get your first recommendation.
            </p>
          )}
        </div>
      </section>

      {/* Form */}
      <section className="max-w-6xl mx-auto mb-10">
        <WorkoutForm onAddSet={addWorkoutEntry} />
      </section>

      {/* Historical workout table */}
      <section className="max-w-6xl mx-auto mt-4">
<WorkoutTable
  data={sortedWorkouts}
  onUpdateSet={updateWorkoutEntry}
  onDeleteSet={deleteWorkoutEntry}
  onSort={handleSort}
  currentSortBy={sortBy}
  currentDirection={sortDirection}
  onMarkDone={markDone}
  todayPlan={todayPlan}   // 👈 NEW: AI coach plan for today
/>

      </section>
    </main>
  );
}
