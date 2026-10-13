-- ============================================================
-- 설비보전 점검 앱 서버 설정 (Supabase SQL Editor에 통째로 붙여넣고 Run)
-- 1) 이 SQL을 먼저 실행한 뒤  2) 앱에서 가입하세요.
-- ============================================================

-- 1. 사용자 프로필 (가입 승인 관리)
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text not null default '',
  approved   boolean not null default false,
  is_admin   boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select approved from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select approved and is_admin from public.profiles where id = auth.uid()), false);
$$;

-- 가입하면 프로필을 자동 생성 (승인 전 상태)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)));
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

revoke all on public.profiles from anon;
grant select, update on public.profiles to authenticated;

-- 2. 점검 기록
create table if not exists public.check_records (
  k          text primary key,
  rec_date   date not null,
  order_idx  int  not null,
  order_id   text,
  equip      text,
  who        text,
  result     text,
  items      jsonb not null default '[]'::jsonb,
  note       text default '',
  act        text default '',
  ts         bigint not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists check_records_date_idx on public.check_records (rec_date desc);
alter table public.check_records enable row level security;

-- 승인된 사용자만 읽기/쓰기, 삭제는 관리자만
drop policy if exists rec_select on public.check_records;
create policy rec_select on public.check_records
  for select to authenticated using (public.is_approved());

drop policy if exists rec_insert on public.check_records;
create policy rec_insert on public.check_records
  for insert to authenticated with check (public.is_approved() and created_by = auth.uid());

drop policy if exists rec_update on public.check_records;
create policy rec_update on public.check_records
  for update to authenticated
  using (public.is_approved() and (created_by = auth.uid() or public.is_admin()))
  with check (public.is_approved() and (created_by = auth.uid() or public.is_admin()));

drop policy if exists rec_delete on public.check_records;
create policy rec_delete on public.check_records
  for delete to authenticated using (public.is_admin());

revoke all on public.check_records from anon;
grant select, insert, update, delete on public.check_records to authenticated;

notify pgrst, 'reload schema';

-- ============================================================
-- 3. 첫 관리자 지정 (앱에서 관리자 본인이 먼저 가입한 뒤, 아래 한 줄을 따로 실행)
--    '내아이디' 부분만 가입 때 쓴 아이디로 바꾸세요. (앞뒤 따옴표는 그대로)
-- ============================================================
-- update public.profiles set approved = true, is_admin = true
--  where id = (select id from auth.users where email = '내아이디@hdc-pce.netlify.app');
