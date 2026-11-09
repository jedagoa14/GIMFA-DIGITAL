-- GIMFA Digital - execute in Supabase SQL Editor, once on a NEW project.
create extension if not exists pgcrypto;
create table if not exists public.admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create table if not exists public.students (
 id uuid primary key default gen_random_uuid(), token uuid not null unique default gen_random_uuid(),
 full_name text not null, document_number text not null unique, blood_type text,
 guardian_phone text, grade text not null, school_year integer not null default extract(year from now())::integer,
 photo_path text, active boolean not null default true,
 consent_recorded boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists students_grade_idx on public.students(grade);
create index if not exists students_token_idx on public.students(token);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.admins where user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
alter table public.admins enable row level security;
alter table public.students enable row level security;
create policy "admin sees own membership" on public.admins for select to authenticated using (user_id = (select auth.uid()));
create policy "admin reads students" on public.students for select to authenticated using (public.is_admin());
create policy "admin inserts students" on public.students for insert to authenticated with check (public.is_admin());
create policy "admin updates students" on public.students for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin deletes students" on public.students for delete to authenticated using (public.is_admin());
-- Public access ONLY via exact random token. No direct public SELECT on students.
create or replace function public.get_digital_card(p_token uuid)
returns table (full_name text, document_number text, blood_type text, guardian_phone text,
 grade text, school_year integer, photo_path text, institution_name text)
language sql stable security definer set search_path = '' as $$
 select s.full_name, s.document_number, s.blood_type, s.guardian_phone,
 s.grade, s.school_year, s.photo_path,
 'GIMNASIO MILITAR FAC TC. FLAVIO ANGULO PIEDRAHITA'::text
 from public.students s
 where s.token = p_token and s.active = true and s.consent_recorded = true
 limit 1;
$$;
revoke all on function public.get_digital_card(uuid) from public;
grant execute on function public.get_digital_card(uuid) to anon, authenticated;
-- Photos: private bucket; signed URLs generated only for a valid active token or admin.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('student-photos','student-photos',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy "admin photo insert" on storage.objects for insert to authenticated
with check (bucket_id='student-photos' and public.is_admin());
create policy "admin photo update" on storage.objects for update to authenticated
using (bucket_id='student-photos' and public.is_admin()) with check (bucket_id='student-photos' and public.is_admin());
create policy "admin photo select" on storage.objects for select to authenticated
using (bucket_id='student-photos' and public.is_admin());
create policy "admin photo delete" on storage.objects for delete to authenticated
using (bucket_id='student-photos' and public.is_admin());
-- Public photo access is served by Edge Function /card-photo after validating the token.
