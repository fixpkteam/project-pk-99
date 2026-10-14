-- Resolve the address/request policy cycle without granting broad address access.
create schema if not exists fixpk_private;
create function fixpk_private.staff_can_read_request_address(p_address_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null
    and public.has_staff_role(array['admin','operations','estimator','support'])
    and exists(select 1 from public.service_requests r where r.address_id=p_address_id);
$$;
revoke all on function fixpk_private.staff_can_read_request_address(uuid) from public, anon;
grant usage on schema fixpk_private to authenticated;
grant execute on function fixpk_private.staff_can_read_request_address(uuid) to authenticated;
alter policy addresses_staff_request_read on public.addresses
using (fixpk_private.staff_can_read_request_address(id));
