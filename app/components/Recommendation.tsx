// app/components/Recommendation.tsx
'use client';

import React, { useEffect, useState } from 'react';
import { WorkoutEntry } from '../../workoutData';

type PlanItem = {
  exercise: string;
  sets: number;
  reps: string;            // e.g., "8–12"
  targetWeightLbs: number | null;
  notes: string;
};
type PlanResponse = {
  group: string;
  items: PlanItem[];
  cue: string;
};

interface Props {
  history: WorkoutEntry[];
  onAddFromPlan: (entries: WorkoutEntry[], markDone?: boolean) => void;
}

export default function Recommendation({ history, onAddFromPlan }: Props) {
  const [loading, setLoading] = useState(false);
  const [plan, setPlan] = useState<PlanResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    const run = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch('/api/recommend', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ history }),
        });
        if (!res.ok) {
          const j = await res.json().catch(() => ({}));
          throw new Error(j.error || `HTTP ${res.status}`);
        }
        const j = await res.json();
        if (mounted) setPlan(j.plan as PlanResponse);
      } catch (e: any) {
        if (mounted) setError(e.message || 'Failed to get recommendation');
      } finally {
        if (mounted) setLoading(false);
      }
    };
    run();
    return () => { mounted = false; };
  }, [history]);

  const buildEntriesFromPlan = (p: PlanResponse, markDone: boolean): WorkoutEntry[] => {
    const today = new Date().toISOString().slice(0,10); // YYYY-MM-DD
    const out: WorkoutEntry[] = [];
    let nextId = Math.floor(Math.random()*1e9); // temp ids; your app already allocates id’s

    p.items.forEach(item => {
      for (let s = 1; s <= item.sets; s++) {
        out.push({
          id: nextId++,
          date: today,
          exercise: item.exercise,
          set: s,
          weightLbs: item.targetWeightLbs ?? 0,
          reps: Number(item.reps.split('–')[0]) || 8,  // use low end as target
          muscleGroup: p.group,
          notes: markDone ? '✓ Done' : '(planned)',
          // OPTIONAL: if you later add a `status` field, set it here
          // status: markDone ? 'done' : 'planned'
        });
      }
    });
    return out;
  };

  if (loading) {
    return (
      <div className="rounded-xl border p-4 bg-white shadow-sm">
        <p className="text-sm text-gray-600">Thinking… building today’s plan…</p>
      </div>
    );
  }
  if (error) {
    return (
      <div className="rounded-xl border p-4 bg-white shadow-sm">
        <p className="text-sm text-red-600">Recommendation error: {error}</p>
      </div>
    );
  }
  if (!plan) return null;

  return (
    <div className="rounded-xl border p-5 bg-white shadow-sm mb-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Suggested Today: {plan.group}</h3>
        <div className="space-x-2">
          <button
            onClick={() => onAddFromPlan(buildEntriesFromPlan(plan, false), false)}
            className="px-3 py-1 rounded bg-indigo-600 text-white text-sm hover:bg-indigo-700"
          >
            Add Plan
          </button>
          <button
            onClick={() => onAddFromPlan(buildEntriesFromPlan(plan, true), true)}
            className="px-3 py-1 rounded bg-green-600 text-white text-sm hover:bg-green-700"
          >
            Add & Mark Done
          </button>
        </div>
      </div>

      <p className="text-sm text-gray-500 mt-1">{plan.cue}</p>

      <ul className="mt-4 grid md:grid-cols-3 gap-3">
        {plan.items.map((it, idx) => (
          <li key={idx} className="rounded-lg border p-3">
            <div className="font-medium">{it.exercise}</div>
            <div className="text-sm text-gray-600">
              Sets: {it.sets} · Reps: {it.reps}
            </div>
            <div className="text-sm text-gray-600">
              Target: {it.targetWeightLbs ?? '—'} lbs
            </div>
            {it.notes && <div className="text-xs text-gray-500 mt-1">{it.notes}</div>}
          </li>
        ))}
      </ul>
    </div>
  );
}
