-- Run this after the FixPK core schema and RLS script.
-- These SECURITY DEFINER commands provide the writes deliberately denied to
-- customer roles by the table policies. Never expose a service-role key in app.

create or replace function public.request_site_survey(
  p_request_id uuid,
  p_requested_at timestamptz,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_owner_id uuid;
  v_survey_id uuid;
  v_request_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select profile_id, status
    into v_owner_id, v_request_status
    from public.service_requests
   where id = p_request_id
   for update;

  if not found or v_owner_id <> v_user_id then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;

  if v_request_status in ('completed', 'cancelled', 'rejected') then
    raise exception 'This request cannot be surveyed in its current state' using errcode = '22023';
  end if;

  select id into v_survey_id
    from public.site_surveys
   where request_id = p_request_id
     and status in ('requested', 'scheduled')
   order by created_at desc
   limit 1;

  if v_survey_id is not null then
    return v_survey_id;
  end if;

  insert into public.site_surveys (request_id, status, requested_at, notes)
  values (p_request_id, 'requested', coalesce(p_requested_at, now()), nullif(trim(p_notes), ''))
  returning id into v_survey_id;

  update public.service_requests
     set status = 'survey_requested', updated_at = now()
   where id = p_request_id
     and status in ('submitted', 'under_review');

  return v_survey_id;
end;
$$;

create or replace function public.decide_quote(
  p_quote_id uuid,
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_owner_id uuid;
  v_status text;
  v_valid_until timestamptz;
  v_next_status text;
  v_note text := nullif(trim(p_note), '');
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select r.profile_id, q.status, q.valid_until
    into v_owner_id, v_status, v_valid_until
    from public.quotes q
    join public.service_requests r on r.id = q.request_id
   where q.id = p_quote_id
   for update of q;

  if not found or v_owner_id <> v_user_id then
    raise exception 'Quote not found' using errcode = 'P0002';
  end if;

  if v_status <> 'sent' then
    raise exception 'This quote is no longer actionable' using errcode = '22023';
  end if;

  if v_valid_until is not null and v_valid_until <= now() then
    raise exception 'This quote has expired' using errcode = '22023';
  end if;

  if p_decision = 'revision_requested' then
    if v_note is null then
      raise exception 'Add a note describing the requested revision' using errcode = '22023';
    end if;
    update public.quotes
       set customer_decision_note = 'Revision requested: ' || v_note,
           updated_at = now()
     where id = p_quote_id;
    v_next_status := 'sent';
  elsif p_decision in ('accepted', 'rejected') then
    update public.quotes
       set status = p_decision,
           customer_decision_note = v_note,
           decided_at = now(),
           updated_at = now()
     where id = p_quote_id;
    v_next_status := p_decision;
  else
    raise exception 'Unsupported quote decision' using errcode = '22023';
  end if;

  return jsonb_build_object('quote_id', p_quote_id, 'status', v_next_status);
end;
$$;

revoke all on function public.request_site_survey(uuid, timestamptz, text) from public;
revoke all on function public.decide_quote(uuid, text, text) from public;
grant execute on function public.request_site_survey(uuid, timestamptz, text) to authenticated;
grant execute on function public.decide_quote(uuid, text, text) to authenticated;
