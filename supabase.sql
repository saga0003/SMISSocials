create extension if not exists pgcrypto;

create type public.user_role as enum ('admin','editor','viewer');
create type public.content_status as enum ('draft','pending','changes','approved','scheduled','published','failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.user_role not null default 'viewer',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.social_accounts (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('facebook','instagram','linkedin','google_business','youtube')),
  name text not null,
  handle text,
  brand_id text not null,
  status text not null default 'needs_connection' check (status in ('connected','needs_connection','disabled')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  brand_id text not null,
  campaign text,
  content_type text not null,
  status public.content_status not null default 'draft',
  master_caption text,
  hashtags text,
  cta text,
  target_url text,
  platforms jsonb not null default '[]'::jsonb,
  scheduled_at timestamptz,
  media jsonb not null default '[]'::jsonb,
  notes text,
  reviewer_comment text,
  creator_name text,
  created_by uuid references public.profiles(id),
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.post_destinations (
  post_id uuid references public.posts(id) on delete cascade,
  account_id uuid references public.social_accounts(id) on delete cascade,
  publish_status text not null default 'pending',
  published_url text,
  error_message text,
  primary key(post_id,account_id)
);

create or replace function public.current_role() returns public.user_role language sql stable security definer set search_path=public as $$
  select role from public.profiles where id=auth.uid() and active=true
$$;

alter table public.profiles enable row level security;
alter table public.social_accounts enable row level security;
alter table public.posts enable row level security;
alter table public.post_destinations enable row level security;

create policy "users read profiles" on public.profiles for select to authenticated using (true);
create policy "admins manage profiles" on public.profiles for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

create policy "team reads accounts" on public.social_accounts for select to authenticated using (true);
create policy "admins manage accounts" on public.social_accounts for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');

create policy "team reads posts" on public.posts for select to authenticated using (true);
create policy "editors create posts" on public.posts for insert to authenticated with check (public.current_role() in ('admin','editor'));
create policy "editors update working posts" on public.posts for update to authenticated using (public.current_role()='admin' or (public.current_role()='editor' and status in ('draft','pending','changes'))) with check (public.current_role()='admin' or public.current_role()='editor');
create policy "admins delete posts" on public.posts for delete to authenticated using (public.current_role()='admin');

create policy "team reads destinations" on public.post_destinations for select to authenticated using (true);
create policy "editors manage destinations" on public.post_destinations for all to authenticated using (public.current_role() in ('admin','editor')) with check (public.current_role() in ('admin','editor'));

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'viewer');
  return new;
end; $$;

create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
