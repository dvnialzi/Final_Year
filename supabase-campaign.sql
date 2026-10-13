-- ═══════════════════════════════════════════════════════════════════════════
--  Amitabha Foundation Children Home: campaign admin dashboard
--
--  HOW TO USE: Supabase → SQL Editor → New query → paste this whole file → Run.
--  It is safe to run again, and safe if you already ran the earlier setup.
--
--  What it creates:
--    1. admins          who is allowed to use the admin dashboard
--    2. campaign        the one current campaign (goal, amount raised, end date, words)
--    3. campaign_log    an automatic history of every change to the goal / amount raised
--    4. campaign_add()  adds a donation to the total
--  Security: everyone can READ the campaign (the website needs to). Only admins
--  can change it. The log is written by the database itself and cannot be edited.
-- ═══════════════════════════════════════════════════════════════════════════


-- ── 1. ADMINS ──────────────────────────────────────────────────────────────
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

drop policy if exists "admins can see their own row" on public.admins;
create policy "admins can see their own row" on public.admins
  for select to authenticated using (user_id = auth.uid());

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
grant execute on function public.is_admin() to anon, authenticated;


-- ── 2. THE CAMPAIGN ────────────────────────────────────────────────────────
create table if not exists public.campaign (
  id         integer primary key default 1 check (id = 1),     -- only ever one row
  goal       numeric(14,2) not null default 100000 check (goal > 0 and goal <= 100000000),
  raised     numeric(14,2) not null default 0      check (raised >= 0 and raised <= 100000000),
  end_date   date,
  name_en    text check (char_length(name_en) <= 120),
  name_zh    text check (char_length(name_zh) <= 120),
  summary_en text check (char_length(summary_en) <= 500),
  summary_zh text check (char_length(summary_zh) <= 500),
  last_note  text check (char_length(last_note) <= 120),        -- note typed with the latest change (goes into the log)
  updated_at timestamptz not null default now()
);
alter table public.campaign enable row level security;

drop policy if exists "anyone can read the campaign" on public.campaign;
create policy "anyone can read the campaign" on public.campaign
  for select to anon, authenticated using (true);

drop policy if exists "admins can update the campaign" on public.campaign;
create policy "admins can update the campaign" on public.campaign
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
-- (no insert / delete rules on purpose: the single row is created below)

insert into public.campaign (id, goal, raised, end_date, name_en, name_zh, summary_en, summary_zh)
values (1, 100000, 0, null,
  'Help us renovate our Children Home',
  '一起翻新我们的儿童小屋',
  'Since 2010 our home in Taman Abad, Johor Bahru has been a safe place for children who need one. Help us raise RM100,000 to renovate it, so every child has a safe, comfortable home to grow up in.',
  '自2010年以来，位于新山 Taman Abad 的儿童小屋一直是孩子们安全的家。请帮助我们筹集 RM100,000 翻新小屋，让每个孩子都能在安全、舒适的家中成长。')
on conflict (id) do nothing;


-- ── 3. ACTIVITY LOG (written by the database, not by the website) ──────────
create table if not exists public.campaign_log (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  email      text,
  old_raised numeric(14,2),
  new_raised numeric(14,2),
  old_goal   numeric(14,2),
  new_goal   numeric(14,2),
  note       text
);
alter table public.campaign_log enable row level security;

drop policy if exists "admins can read the log" on public.campaign_log;
create policy "admins can read the log" on public.campaign_log
  for select to authenticated using (public.is_admin());
-- (no insert / update / delete rules: only the trigger below can write to it)

create or replace function public.campaign_before_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.raised is distinct from old.raised or new.goal is distinct from old.goal then
    insert into public.campaign_log (email, old_raised, new_raised, old_goal, new_goal, note)
    values ((select email from auth.users where id = auth.uid()), old.raised, new.raised, old.goal, new.goal, new.last_note);
  end if;
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists campaign_before_update on public.campaign;
create trigger campaign_before_update before update on public.campaign
  for each row execute function public.campaign_before_update();


-- ── 4. ADD A DONATION TO THE TOTAL ─────────────────────────────────────────
-- (done inside the database so two people adding at the same moment never overwrite each other)
create or replace function public.campaign_add(p_amount numeric, p_note text default null)
returns public.campaign
language plpgsql security definer set search_path = public as $$
declare r public.campaign;
begin
  if not public.is_admin() then
    raise exception 'Only admins can update the campaign' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 10000000 then
    raise exception 'Please enter an amount between RM0.01 and RM10,000,000';
  end if;
  update public.campaign
     set raised = raised + p_amount, last_note = nullif(trim(p_note), '')
   where id = 1
   returning * into r;
  return r;
end $$;
revoke execute on function public.campaign_add(numeric, text) from public, anon;
grant execute on function public.campaign_add(numeric, text) to authenticated;


-- ═══════════════════════════════════════════════════════════════════════════
--  LAST STEP: make yourself an admin (skip if you already did this earlier)
--  1) Supabase → Authentication → Users → "Add user" → your email + a strong password
--     (tick "Auto Confirm User")
--  2) Run ONLY these lines, with your own email:
--
--  insert into public.admins (user_id, email)
--  select id, email from auth.users where email = 'your-email@example.com'
--  on conflict do nothing;
-- ═══════════════════════════════════════════════════════════════════════════
