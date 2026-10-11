-- Optional hardening for the staff controls in the FixPK Flutter client.
-- Run after the approved core schema. The original `staff_manage` policy
-- granted every staff role write access to these tables. This replaces it
-- with staff-wide reads and role-scoped writes.

-- Jobs: admin/operations manage jobs; staff roles may read.
drop policy if exists staff_manage on public.jobs;
drop policy if exists staff_read on public.jobs;
drop policy if exists job_managers_insert on public.jobs;
drop policy if exists job_managers_update on public.jobs;
drop policy if exists admins_delete_jobs on public.jobs;

create policy staff_read on public.jobs
  for select to authenticated
  using (public.has_staff_role(array[
    'admin', 'operations', 'estimator', 'support', 'content_manager'
  ]));

create policy job_managers_insert on public.jobs
  for insert to authenticated
  with check (public.has_staff_role(array['admin', 'operations']));

create policy job_managers_update on public.jobs
  for update to authenticated
  using (public.has_staff_role(array['admin', 'operations']))
  with check (public.has_staff_role(array['admin', 'operations']));

create policy admins_delete_jobs on public.jobs
  for delete to authenticated
  using (public.has_staff_role(array['admin']));

-- Support: admin/support may manage ticket status; other staff may read.
drop policy if exists staff_manage on public.support_tickets;
drop policy if exists staff_read on public.support_tickets;
drop policy if exists support_staff_insert on public.support_tickets;
drop policy if exists support_staff_update on public.support_tickets;
drop policy if exists admins_delete_support_tickets on public.support_tickets;

create policy staff_read on public.support_tickets
  for select to authenticated
  using (public.has_staff_role(array[
    'admin', 'operations', 'estimator', 'support', 'content_manager'
  ]));

create policy support_staff_insert on public.support_tickets
  for insert to authenticated
  with check (public.has_staff_role(array['admin', 'support']));

create policy support_staff_update on public.support_tickets
  for update to authenticated
  using (public.has_staff_role(array['admin', 'support']))
  with check (public.has_staff_role(array['admin', 'support']));

create policy admins_delete_support_tickets on public.support_tickets
  for delete to authenticated
  using (public.has_staff_role(array['admin']));

-- Reviews: admin/content_manager moderate; all staff can read the queue.
drop policy if exists staff_manage on public.reviews;
drop policy if exists staff_read on public.reviews;
drop policy if exists moderators_update_reviews on public.reviews;
drop policy if exists admins_delete_reviews on public.reviews;

create policy staff_read on public.reviews
  for select to authenticated
  using (public.has_staff_role(array[
    'admin', 'operations', 'estimator', 'support', 'content_manager'
  ]));

create policy moderators_update_reviews on public.reviews
  for update to authenticated
  using (public.has_staff_role(array['admin', 'content_manager']))
  with check (public.has_staff_role(array['admin', 'content_manager']));

create policy admins_delete_reviews on public.reviews
  for delete to authenticated
  using (public.has_staff_role(array['admin']));
