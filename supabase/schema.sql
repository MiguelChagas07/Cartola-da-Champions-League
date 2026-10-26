-- Execute no SQL Editor de seu projeto Supabase.
create extension if not exists pgcrypto;
create table if not exists public.fantasy_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Jogador', created_at timestamptz not null default now()
);
create table if not exists public.fantasy_teams (
 user_id uuid primary key references auth.users(id) on delete cascade,
 name text not null default 'Meu Esquadrão', formation text not null default '4-3-3',
 player_ids integer[] not null default '{}', captain_id integer,
 updated_at timestamptz not null default now()
);
create table if not exists public.fantasy_leagues (
 id uuid primary key default gen_random_uuid(), name text not null,
 invite_code text not null unique, owner_id uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.fantasy_league_members (
 league_id uuid not null references public.fantasy_leagues(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 joined_at timestamptz not null default now(), primary key(league_id,user_id)
);
create table if not exists public.fantasy_rounds (
 id integer primary key, title text not null, deadline timestamptz, status text not null default 'upcoming'
);
create table if not exists public.fantasy_fixtures (
 id bigint primary key, round_id integer references public.fantasy_rounds(id),
 home_team text not null, away_team text not null, kickoff timestamptz,
 home_score integer, away_score integer, status text not null default 'scheduled'
);
create table if not exists public.fantasy_player_scores (
 round_id integer not null references public.fantasy_rounds(id), player_id integer not null,
 points numeric(8,2) not null default 0, primary key(round_id,player_id)
);
create table if not exists public.fantasy_round_lineups (
 round_id integer not null references public.fantasy_rounds(id), user_id uuid not null references auth.users(id),
 player_ids integer[] not null, captain_id integer, formation text not null,
 locked_at timestamptz not null default now(), primary key(round_id,user_id)
);
create or replace function public.join_fantasy_league(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Não autenticado'; end if;
 select id into v_id from public.fantasy_leagues where invite_code = upper(trim(p_code));
 if v_id is null then raise exception 'Código de liga inválido'; end if;
 insert into public.fantasy_league_members(league_id,user_id) values(v_id,auth.uid()) on conflict do nothing;
 return v_id;
end $$;
revoke all on function public.join_fantasy_league(text) from public;
grant execute on function public.join_fantasy_league(text) to authenticated;
create or replace function public.add_owner_to_fantasy_league()
returns trigger language plpgsql security definer set search_path = public as $$
begin
 insert into public.fantasy_league_members(league_id,user_id) values(new.id,new.owner_id);
 return new;
end $$;
drop trigger if exists fantasy_league_owner_member on public.fantasy_leagues;
create trigger fantasy_league_owner_member after insert on public.fantasy_leagues for each row execute function public.add_owner_to_fantasy_league();

alter table public.fantasy_profiles enable row level security;
alter table public.fantasy_teams enable row level security;
alter table public.fantasy_leagues enable row level security;
alter table public.fantasy_league_members enable row level security;
alter table public.fantasy_rounds enable row level security;
alter table public.fantasy_fixtures enable row level security;
alter table public.fantasy_player_scores enable row level security;
alter table public.fantasy_round_lineups enable row level security;
drop policy if exists "profiles read" on public.fantasy_profiles;
create policy "profiles read" on public.fantasy_profiles for select to authenticated using (true);
drop policy if exists "profiles own insert" on public.fantasy_profiles;
create policy "profiles own insert" on public.fantasy_profiles for insert to authenticated with check (user_id=auth.uid());
drop policy if exists "profiles own update" on public.fantasy_profiles;
create policy "profiles own update" on public.fantasy_profiles for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "teams read" on public.fantasy_teams;
create policy "teams read" on public.fantasy_teams for select to authenticated using(true);
drop policy if exists "teams own insert" on public.fantasy_teams;
create policy "teams own insert" on public.fantasy_teams for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "teams own update" on public.fantasy_teams;
create policy "teams own update" on public.fantasy_teams for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists "leagues read" on public.fantasy_leagues;
create policy "leagues read" on public.fantasy_leagues for select to authenticated using(true);
drop policy if exists "leagues create" on public.fantasy_leagues;
create policy "leagues create" on public.fantasy_leagues for insert to authenticated with check(owner_id=auth.uid());
drop policy if exists "members read" on public.fantasy_league_members;
create policy "members read" on public.fantasy_league_members for select to authenticated using(true);
drop policy if exists "rounds read" on public.fantasy_rounds;
create policy "rounds read" on public.fantasy_rounds for select to authenticated using(true);
drop policy if exists "fixtures read" on public.fantasy_fixtures;
create policy "fixtures read" on public.fantasy_fixtures for select to authenticated using(true);
drop policy if exists "scores read" on public.fantasy_player_scores;
create policy "scores read" on public.fantasy_player_scores for select to authenticated using(true);
drop policy if exists "lineups read" on public.fantasy_round_lineups;
create policy "lineups read" on public.fantasy_round_lineups for select to authenticated using(true);
drop policy if exists "lineups own insert" on public.fantasy_round_lineups;
create policy "lineups own insert" on public.fantasy_round_lineups for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.fantasy_rounds r where r.id=round_id and r.status='upcoming' and (r.deadline is null or r.deadline>now())));
drop policy if exists "lineups own update" on public.fantasy_round_lineups;
create policy "lineups own update" on public.fantasy_round_lineups for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid() and exists(select 1 from public.fantasy_rounds r where r.id=round_id and r.status='upcoming' and (r.deadline is null or r.deadline>now())));
-- Rodadas, resultados e pontuações são atualizados APENAS pelo backend com service_role.
