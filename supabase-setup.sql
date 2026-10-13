-- ═══════════════════════════════════════════════════════════════════════════
--  Amitabha Foundation Children Home: admin website database setup
--
--  HOW TO USE: Supabase → SQL Editor → New query → paste this whole file → Run.
--  It is safe to run again later: it only adds what is missing.
--
--  What it creates:
--    1. admins       who is allowed into the admin website
--    2. posts        blog posts (English + 中文), drafts and published
--    3. page_views   anonymous visitor statistics (no names, no personal data)
--       events       clicks on Donate / WhatsApp / phone / directions buttons
--    4. analytics_summary()  the numbers shown on the admin dashboard
--    5. blog-images  photo storage for blog cover pictures
--  Every table is protected: visitors can only read published posts and record
--  visits; only admins can write posts, upload photos or see the statistics.
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

-- true when the person logged in is an admin
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
grant execute on function public.is_admin() to anon, authenticated;


-- ── 2. BLOG POSTS ──────────────────────────────────────────────────────────
create table if not exists public.posts (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
  tag          text not null default 'News',
  title_en     text not null check (char_length(title_en) between 1 and 160),
  title_zh     text check (char_length(title_zh) <= 160),
  excerpt_en   text check (char_length(excerpt_en) <= 400),
  excerpt_zh   text check (char_length(excerpt_zh) <= 400),
  body_en      text,
  body_zh      text,
  cover_url    text,
  status       text not null default 'draft' check (status in ('draft', 'published')),
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  author_id    uuid default auth.uid() references auth.users(id) on delete set null
);
create index if not exists posts_published_idx on public.posts (status, published_at desc);
alter table public.posts enable row level security;

drop policy if exists "anyone can read published posts" on public.posts;
create policy "anyone can read published posts" on public.posts
  for select to anon, authenticated using (status = 'published' or public.is_admin());

drop policy if exists "admins can add posts" on public.posts;
create policy "admins can add posts" on public.posts
  for insert to authenticated with check (public.is_admin());

drop policy if exists "admins can edit posts" on public.posts;
create policy "admins can edit posts" on public.posts
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins can delete posts" on public.posts;
create policy "admins can delete posts" on public.posts
  for delete to authenticated using (public.is_admin());

-- keep "last updated" and "published on" dates correct automatically
create or replace function public.posts_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end $$;
drop trigger if exists posts_touch on public.posts;
create trigger posts_touch before insert or update on public.posts
  for each row execute function public.posts_touch();


-- ── 3. VISITOR STATISTICS (anonymous) ──────────────────────────────────────
create table if not exists public.page_views (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  page       text not null check (char_length(page) <= 60),
  visitor    text check (char_length(visitor) <= 40),
  referrer   text check (char_length(referrer) <= 120),
  device     text check (device in ('mobile', 'tablet', 'desktop')),
  lang       text check (char_length(lang) <= 8)
);
create index if not exists page_views_time_idx on public.page_views (created_at);
alter table public.page_views enable row level security;

drop policy if exists "website can record visits" on public.page_views;
create policy "website can record visits" on public.page_views
  for insert to anon, authenticated with check (true);
-- (no "select" rule on purpose: only the dashboard function below can read visits)

create table if not exists public.events (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  page       text check (char_length(page) <= 60),
  name       text not null check (char_length(name) <= 40),
  label      text check (char_length(label) <= 60),
  visitor    text check (char_length(visitor) <= 40)
);
create index if not exists events_time_idx on public.events (created_at);
alter table public.events enable row level security;

drop policy if exists "website can record clicks" on public.events;
create policy "website can record clicks" on public.events
  for insert to anon, authenticated with check (true);


-- ── 4. DASHBOARD NUMBERS (admins only) ─────────────────────────────────────
create or replace function public.analytics_summary(range_days integer default 30) returns json
language plpgsql stable security definer set search_path = public as $$
declare
  since timestamptz := now() - make_interval(days => greatest(1, least(coalesce(range_days, 30), 365)));
  tz    text := 'Asia/Kuala_Lumpur';
begin
  if not public.is_admin() then
    raise exception 'Only admins can see the statistics' using errcode = '42501';
  end if;
  return json_build_object(
    'since',    since,
    'views',    (select count(*) from page_views where created_at >= since),
    'visitors', (select count(distinct visitor) from page_views where created_at >= since),
    'daily', coalesce((
      select json_agg(json_build_object('day', d.day, 'views', d.views, 'visitors', d.visitors) order by d.day)
      from (select (created_at at time zone tz)::date as day, count(*) as views, count(distinct visitor) as visitors
            from page_views where created_at >= since group by 1) d), '[]'::json),
    'pages', coalesce((
      select json_agg(json_build_object('page', p.page, 'views', p.views) order by p.views desc)
      from (select page, count(*) as views from page_views where created_at >= since
            group by page order by count(*) desc limit 10) p), '[]'::json),
    'devices', coalesce((
      select json_agg(json_build_object('device', x.device, 'views', x.views) order by x.views desc)
      from (select coalesce(device, 'unknown') as device, count(*) as views from page_views
            where created_at >= since group by 1) x), '[]'::json),
    'langs', coalesce((
      select json_agg(json_build_object('lang', x.lang, 'views', x.views) order by x.views desc)
      from (select coalesce(lang, 'en') as lang, count(*) as views from page_views
            where created_at >= since group by 1) x), '[]'::json),
    'referrers', coalesce((
      select json_agg(json_build_object('site', r.referrer, 'views', r.views) order by r.views desc)
      from (select referrer, count(*) as views from page_views
            where created_at >= since and coalesce(referrer, '') <> ''
            group by referrer order by count(*) desc limit 8) r), '[]'::json),
    'clicks', coalesce((
      select json_agg(json_build_object('name', c.name, 'label', c.label, 'count', c.n) order by c.n desc)
      from (select name, coalesce(label, '') as label, count(*) as n from events
            where created_at >= since group by 1, 2) c), '[]'::json)
  );
end $$;
revoke execute on function public.analytics_summary(integer) from public, anon;
grant execute on function public.analytics_summary(integer) to authenticated;


-- ── 5. PHOTO STORAGE FOR BLOG COVERS ───────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('blog-images', 'blog-images', true)
on conflict (id) do nothing;

drop policy if exists "anyone can view blog images" on storage.objects;
create policy "anyone can view blog images" on storage.objects
  for select using (bucket_id = 'blog-images');

drop policy if exists "admins can upload blog images" on storage.objects;
create policy "admins can upload blog images" on storage.objects
  for insert to authenticated with check (bucket_id = 'blog-images' and public.is_admin());

drop policy if exists "admins can replace blog images" on storage.objects;
create policy "admins can replace blog images" on storage.objects
  for update to authenticated using (bucket_id = 'blog-images' and public.is_admin());

drop policy if exists "admins can delete blog images" on storage.objects;
create policy "admins can delete blog images" on storage.objects
  for delete to authenticated using (bucket_id = 'blog-images' and public.is_admin());


-- ═══════════════════════════════════════════════════════════════════════════
--  LAST STEP: make yourself an admin
--  1) Supabase → Authentication → Users → "Add user" → enter your email + a password
--  2) Change the email below to that same email, then run ONLY these two lines:
--
--  insert into public.admins (user_id, email)
--  select id, email from auth.users where email = 'your-email@example.com' on conflict do nothing;
--
--  Repeat for each staff member who should have access.
-- ═══════════════════════════════════════════════════════════════════════════
