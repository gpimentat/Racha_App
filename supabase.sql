-- Racha Casa: banco de dados no Supabase
-- Cole tudo isto em SQL Editor > New query > Run. Pode rodar mais de uma vez sem problema.

create extension if not exists pgcrypto;

create table if not exists public.houses (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.house_users (
  house_id uuid not null references public.houses(id) on delete cascade,
  user_id uuid not null,
  primary key (house_id, user_id)
);

create table if not exists public.bills (
  id text primary key,
  house_id uuid not null references public.houses(id) on delete cascade,
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.settlements (
  id text primary key,
  house_id uuid not null references public.houses(id) on delete cascade,
  data jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists bills_house_idx on public.bills(house_id);
create index if not exists settlements_house_idx on public.settlements(house_id);

alter table public.houses enable row level security;
alter table public.house_users enable row level security;
alter table public.bills enable row level security;
alter table public.settlements enable row level security;

-- Quem é morador de uma casa (usado pelas regras de acesso)
create or replace function public.is_member(h uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.house_users
    where house_id = h and user_id = auth.uid()
  );
$$;

drop policy if exists houses_select on public.houses;
drop policy if exists houses_update on public.houses;
drop policy if exists houses_delete on public.houses;
create policy houses_select on public.houses for select to authenticated using (public.is_member(id));
create policy houses_update on public.houses for update to authenticated using (public.is_member(id)) with check (public.is_member(id));
create policy houses_delete on public.houses for delete to authenticated using (public.is_member(id));

drop policy if exists house_users_select on public.house_users;
create policy house_users_select on public.house_users for select to authenticated using (user_id = auth.uid());

drop policy if exists bills_all on public.bills;
create policy bills_all on public.bills for all to authenticated
  using (public.is_member(house_id)) with check (public.is_member(house_id));

drop policy if exists settlements_all on public.settlements;
create policy settlements_all on public.settlements for all to authenticated
  using (public.is_member(house_id)) with check (public.is_member(house_id));

-- Criar uma casa: devolve o id e já torna quem criou um morador
create or replace function public.create_house(p_code text, p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  hid uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if length(trim(p_code)) < 4 then
    raise exception 'code too short';
  end if;
  insert into public.houses(code, data) values (upper(trim(p_code)), p_data) returning id into hid;
  insert into public.house_users(house_id, user_id) values (hid, auth.uid());
  return hid;
end;
$$;

-- Entrar numa casa pelo código de acesso
create or replace function public.join_house(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  hid uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  select id into hid from public.houses where code = upper(trim(p_code));
  if hid is null then
    raise exception 'house not found';
  end if;
  insert into public.house_users(house_id, user_id) values (hid, auth.uid()) on conflict do nothing;
  return hid;
end;
$$;

revoke all on function public.create_house(text, jsonb) from public, anon;
revoke all on function public.join_house(text) from public, anon;
grant execute on function public.create_house(text, jsonb) to authenticated;
grant execute on function public.join_house(text) to authenticated;

-- Atualização em tempo real para todos os moradores
do $$
begin
  begin alter publication supabase_realtime add table public.bills; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.settlements; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.houses; exception when duplicate_object then null; end;
end $$;
