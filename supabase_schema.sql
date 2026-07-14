-- ═══════════════════════════════════════════════════════════════════════
--  Garipov — таблица библиотеки проектов + RLS
--  Выполнить целиком в Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════════════════

-- Миграция: если таблица уже была создана раньше (без колонки history),
-- этот блок безопасно добавит её, ничего не потеряв. Если таблицы ещё
-- нет — просто ничего не делает, create table ниже создаст её сразу верно.
alter table if exists public.projects
  add column if not exists history jsonb not null default '[]'::jsonb;

create table if not exists public.projects (
  uuid text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text,
  category text,
  format text,
  payload jsonb not null,
  history jsonb not null default '[]'::jsonb,
  created_at bigint not null,
  updated_at bigint not null,
  deleted boolean not null default false
);

-- Быстрая выборка "мои, новые сверху"
create index if not exists projects_user_updated_idx
  on public.projects (user_id, updated_at desc);

-- ── Row Level Security: включаем и разрешаем видеть/менять ТОЛЬКО свои строки ──
alter table public.projects enable row level security;

drop policy if exists "select own projects" on public.projects;
create policy "select own projects"
  on public.projects for select
  using (auth.uid() = user_id);

drop policy if exists "insert own projects" on public.projects;
create policy "insert own projects"
  on public.projects for insert
  with check (auth.uid() = user_id);

drop policy if exists "update own projects" on public.projects;
create policy "update own projects"
  on public.projects for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Удаление не даём вообще — используем soft-delete (deleted=true через update).
-- Так синк между устройствами не теряет записи молча.

-- ── Проверка после выполнения ──
-- 1. Table Editor → projects → должна быть пустая таблица с колонками выше.
-- 2. Authentication → Providers → Email → включить "Enable Email provider"
--    и "Enable Magic Link" (или Email OTP) — это и есть вход без пароля.
-- 3. Authentication → URL Configuration → Site URL: указать твой GitHub Pages
--    адрес (https://username.github.io/repo-name/) — иначе ссылка из письма
--    поведёт не туда.
