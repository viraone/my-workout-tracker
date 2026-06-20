create table if not exists public.workouts (
    id uuid primary key,
    workout_date timestamptz not null,
    notes text not null default '',
    created_at timestamptz not null default now()
);

alter table public.workouts
    add column if not exists title text not null default 'Workout',
    add column if not exists category text not null default 'Strength',
    add column if not exists duration_minutes integer not null default 30;

create table if not exists public.exercises (
    id uuid primary key,
    workout_id uuid not null references public.workouts(id) on delete cascade,
    name text not null,
    order_index integer not null default 0
);

alter table public.exercises
    add column if not exists notes text not null default '';

create table if not exists public.sets (
    id uuid primary key,
    exercise_id uuid not null references public.exercises(id) on delete cascade,
    weight double precision not null default 0,
    reps integer not null default 0,
    set_number integer not null
);

alter table public.sets
    add column if not exists is_completed boolean not null default false;

create index if not exists exercises_workout_id_idx
    on public.exercises(workout_id);

create index if not exists sets_exercise_id_idx
    on public.sets(exercise_id);

alter table public.workouts enable row level security;
alter table public.exercises enable row level security;
alter table public.sets enable row level security;

grant select, insert, update, delete on public.workouts to anon, authenticated;
grant select, insert, update, delete on public.exercises to anon, authenticated;
grant select, insert, update, delete on public.sets to anon, authenticated;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'workouts'
          and policyname = 'Workout app cloud access'
    ) then
        create policy "Workout app cloud access"
            on public.workouts
            for all
            to anon, authenticated
            using (true)
            with check (true);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'exercises'
          and policyname = 'Workout app cloud access'
    ) then
        create policy "Workout app cloud access"
            on public.exercises
            for all
            to anon, authenticated
            using (true)
            with check (true);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'sets'
          and policyname = 'Workout app cloud access'
    ) then
        create policy "Workout app cloud access"
            on public.sets
            for all
            to anon, authenticated
            using (true)
            with check (true);
    end if;
end
$$;
