-- FixPK admin console policies.
-- Apply in the Supabase SQL Editor after the core FixPK schema and the
-- has_staff_role(text[]) helper have been installed. This file never grants
-- service_role privileges to the Flutter client.

begin;

-- The customer catalogue constructs public URLs for these image assets.
-- Keep the files in Storage, never in PostgreSQL rows.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', true, 8388608, array['image/jpeg', 'image/png', 'image/webp']),
  ('project-images', 'project-images', true, 8388608, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- The admin editor is allowlisted to customer-facing catalogue/content tables.
-- Published/guest SELECT policies remain intact; PostgreSQL combines policies
-- with OR, so this adds a separate authenticated admin-only write path.
do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'service_categories', 'services', 'service_questions',
    'service_question_options', 'product_categories', 'products',
    'product_images', 'product_specifications', 'projects',
    'project_images', 'faq', 'banners', 'app_content'
  ] loop
    execute format('alter table public.%I enable row level security', target_table);
    -- Remove a legacy catch-all staff policy if one was installed on a
    -- customer-facing catalogue table. Admin access below is role-specific.
    execute format('drop policy if exists staff_manage on public.%I', target_table);
    execute format('drop policy if exists fixpk_admin_manage on public.%I', target_table);
    execute format(
      'create policy fixpk_admin_manage on public.%I for all to authenticated using (public.has_staff_role(array[''admin''])) with check (public.has_staff_role(array[''admin'']))',
      target_table
    );
  end loop;
end;
$$;

-- Admins can inspect customer profiles from the account manager. Auth emails,
-- bans and role changes are handled by the signed, server-side Edge Function.
alter table public.profiles enable row level security;
drop policy if exists fixpk_admin_read_profiles on public.profiles;
create policy fixpk_admin_read_profiles on public.profiles
  for select to authenticated
  using (public.has_staff_role(array['admin']));

-- Serialize administrator-role removals so two concurrent requests cannot
-- both pass a last-admin count check and remove the final administrators.
create or replace function public.fixpk_admin_remove_user_role(
  p_user_id uuid,
  p_role text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_has_role boolean;
  v_admin_count bigint;
begin
  if p_role not in ('admin', 'operations', 'estimator', 'support', 'content_manager') then
    raise exception 'Unsupported staff role' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtext('fixpk_admin_role_management'));

  select exists (
    select 1 from public.user_roles
    where user_id = p_user_id and role = p_role
  ) into v_has_role;

  if p_role = 'admin' and v_has_role then
    select count(*) into v_admin_count
    from public.user_roles where role = 'admin';
    if v_admin_count <= 1 then
      return false;
    end if;
  end if;

  delete from public.user_roles
  where user_id = p_user_id and role = p_role;
  return true;
end;
$$;

revoke all on function public.fixpk_admin_remove_user_role(uuid, text)
  from public, anon, authenticated;
grant execute on function public.fixpk_admin_remove_user_role(uuid, text)
  to service_role;

-- Catalogue images are public-read assets. Only admins can upload, replace,
-- or remove files; customer attachment buckets are deliberately excluded.
drop policy if exists fixpk_admin_manage_catalogue_media on storage.objects;
create policy fixpk_admin_manage_catalogue_media on storage.objects
  for all to authenticated
  using (
    bucket_id in ('product-images', 'project-images')
    and public.has_staff_role(array['admin'])
  )
  with check (
    bucket_id in ('product-images', 'project-images')
    and public.has_staff_role(array['admin'])
  );

commit;
