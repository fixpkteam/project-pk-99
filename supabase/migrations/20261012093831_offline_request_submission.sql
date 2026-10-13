-- A stable client UUID makes retries safe after a lost HTTP response.
-- SECURITY INVOKER retains the caller's RLS and table grants.
create or replace function public.submit_service_request(
  p_request_id uuid,
  p_service_id uuid,
  p_address_id uuid,
  p_customer_notes text default '',
  p_preferred_date date default null,
  p_preferred_time text default null,
  p_answers jsonb default '{}'::jsonb
) returns uuid
language plpgsql security invoker set search_path = ''
as $$
declare
  v_owner uuid := auth.uid();
  v_existing public.service_requests%rowtype;
  v_question record;
  v_answer jsonb;
  v_option jsonb;
begin
  if v_owner is null then
    raise exception 'Sign in required' using errcode = '28000';
  end if;
  if p_request_id is null or p_service_id is null or p_address_id is null then
    raise exception 'Request, service and address are required' using errcode = '22023';
  end if;
  -- Serialize retries for the same owner and request, not all customers.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_owner::text || p_request_id::text, 0));
  select * into v_existing from public.service_requests where id = p_request_id;
  if found then
    if v_existing.profile_id <> v_owner or v_existing.service_id <> p_service_id then
      raise exception 'Request reference is not available' using errcode = '42501';
    end if;
    return v_existing.id;
  end if;
  if not exists (select 1 from public.addresses where id = p_address_id and profile_id = v_owner) then
    raise exception 'Select an address belonging to your account' using errcode = '22023';
  end if;
  if not exists (select 1 from public.services s join public.service_categories c on c.id=s.category_id
                 where s.id=p_service_id and s.is_published and c.is_published) then
    raise exception 'This service is no longer available' using errcode = '22023';
  end if;
  if length(coalesce(p_customer_notes, '')) > 5000 or
      p_answers is null or jsonb_typeof(p_answers) <> 'object' or octet_length(p_answers::text) > 100000 then
    raise exception 'Request details are too large or invalid' using errcode = '22023';
  end if;
  if p_preferred_time is not null and p_preferred_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$' then
    raise exception 'Invalid preferred time' using errcode = '22023';
  end if;
  if exists (select 1 from jsonb_object_keys(p_answers) k
             where not exists (select 1 from public.service_questions q where q.id::text=k and q.service_id=p_service_id)) then
    raise exception 'The service form has changed. Contact support.' using errcode = '22023';
  end if;
  for v_question in select * from public.service_questions where service_id=p_service_id loop
    v_answer := p_answers -> v_question.id::text;
    if v_answer is null or v_answer='null'::jsonb or v_answer='""'::jsonb or v_answer='[]'::jsonb then
      if v_question.is_required then
        raise exception 'A required answer is missing' using errcode = '22023';
      end if;
      continue;
    end if;
    if v_question.input_type='boolean' and jsonb_typeof(v_answer)<>'boolean' then
      raise exception 'Invalid yes/no answer' using errcode = '22023';
    elsif v_question.input_type='number' then
      if (v_answer #>> '{}') !~ '^-?[0-9]+(\.[0-9]+)?$' then
        raise exception 'Invalid numeric answer' using errcode = '22023';
      end if;
    elsif v_question.input_type='single_select' then
      if not exists (select 1 from public.service_question_options where question_id=v_question.id and option_value=(v_answer #>> '{}')) then
        raise exception 'Invalid selected option' using errcode = '22023';
      end if;
    elsif v_question.input_type='multi_select' then
      if jsonb_typeof(v_answer)<>'array' then
        raise exception 'Invalid selected options' using errcode = '22023';
      end if;
      for v_option in select value from jsonb_array_elements(v_answer) loop
        if not exists (select 1 from public.service_question_options where question_id=v_question.id and option_value=(v_option #>> '{}')) then
          raise exception 'Invalid selected option' using errcode = '22023';
        end if;
      end loop;
    elsif v_question.input_type in ('text','textarea','date') then
      if jsonb_typeof(v_answer)<>'string' or length(v_answer #>> '{}')>5000 or
          (v_question.is_required and btrim(v_answer #>> '{}')='') then
        raise exception 'Invalid text answer' using errcode = '22023';
      end if;
      if v_question.input_type='date' then
        perform (v_answer #>> '{}')::date;
      end if;
    end if;
  end loop;
  insert into public.service_requests(id,profile_id,service_id,address_id,status,customer_notes,preferred_date,preferred_time)
  values (p_request_id,v_owner,p_service_id,p_address_id,'submitted',nullif(btrim(p_customer_notes),''),p_preferred_date,p_preferred_time);
  insert into public.service_request_answers(request_id,question_id,answer_value)
  select p_request_id,q.id,a.value from jsonb_each(p_answers) a
    join public.service_questions q on q.id::text=a.key and q.service_id=p_service_id;
  return p_request_id;
end;
$$;
revoke all on function public.submit_service_request(uuid,uuid,uuid,text,date,text,jsonb) from public, anon;
grant execute on function public.submit_service_request(uuid,uuid,uuid,text,date,text,jsonb) to authenticated;

-- Avoid full scans when loading media for a catalogue page.
create index if not exists product_images_parent_order_idx on public.product_images(product_id,sort_order);
create index if not exists project_images_parent_order_idx on public.project_images(project_id,sort_order);
create index if not exists product_specs_parent_order_idx on public.product_specifications(product_id,sort_order);

-- Supabase grants EXECUTE directly to anon in addition to PUBLIC by default.
revoke execute on function public.request_site_survey(uuid,timestamptz,text) from public,anon;
revoke execute on function public.decide_quote(uuid,text,text) from public,anon;
revoke execute on function public.create_profile_for_auth_user() from public,anon,authenticated;

create index if not exists quote_items_parent_order_idx on public.quote_items(quote_id,sort_order);
create index if not exists job_assignments_job_idx on public.job_assignments(job_id);
create index if not exists reviews_owner_created_idx on public.reviews(profile_id,created_at desc);

-- Fix a previously unqualified correlation that compared each column to itself.
alter policy requests_create_own on public.service_requests with check (
  profile_id=(select auth.uid()) and status='submitted' and public_reference is null
  and exists(select 1 from public.services s where s.id=service_requests.service_id and s.is_published)
  and (address_id is null or exists(select 1 from public.addresses a where a.id=service_requests.address_id and a.profile_id=(select auth.uid())))
  and (service_area_id is null or exists(select 1 from public.service_area_services sas
    where sas.service_area_id=service_requests.service_area_id and sas.service_id=service_requests.service_id and sas.is_enabled))
);
