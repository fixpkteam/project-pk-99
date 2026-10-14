-- Transactional regression test: all synthetic accounts and rows roll back.
begin;
do $$
declare
  a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
  staff_id uuid := gen_random_uuid();
  c uuid := gen_random_uuid(); s uuid := gen_random_uuid();
  addr uuid := gen_random_uuid(); q uuid := gen_random_uuid();
begin
  perform set_config('test.staff',staff_id::text,true);
  perform set_config('test.owner',a::text,true);
  perform set_config('test.other',b::text,true);
  perform set_config('test.service',s::text,true);
  perform set_config('test.address',addr::text,true);
  perform set_config('test.question',q::text,true);
  perform set_config('test.request',gen_random_uuid()::text,true);
  insert into auth.users(id, email, raw_user_meta_data, raw_app_meta_data)
  values(a,'fixpk-test-'||a||'@example.invalid','{}','{}'),
        (b,'fixpk-test-'||b||'@example.invalid','{}','{}'),
        (staff_id,'fixpk-test-'||staff_id||'@example.invalid','{}','{}');
  insert into public.user_roles(user_id,role) values(staff_id,'admin');
  insert into public.service_categories(id,name,slug,is_published)
  values(c,'Transaction test','test-'||c,true);
  insert into public.services(id,category_id,name,slug,is_published)
  values(s,c,'Transaction test','test-'||s,true);
  insert into public.addresses(id,profile_id,address_line,city)
  values(addr,a,'Synthetic test address','Test');
  insert into public.addresses(profile_id,address_line,city)
  values(a,'Unlinked private address','Test');
  insert into public.service_questions(id,service_id,question_key,label,input_type,is_required)
  values(q,s,'capacity','Capacity','number',true);
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.owner'),true);
do $$
declare
  r uuid := current_setting('test.request')::uuid;
  s uuid := current_setting('test.service')::uuid;
  a uuid := current_setting('test.address')::uuid;
  q uuid := current_setting('test.question')::uuid;
  result uuid;
begin
  -- Reject an incomplete form without creating a partial request.
  begin
    perform public.submit_service_request(r,s,a,'',null,null,'{}');
    raise exception 'TEST FAILED: missing answer accepted';
  exception when sqlstate '22023' then null;
  end;
  if exists(select 1 from public.service_requests where id=r) then
    raise exception 'TEST FAILED: partial row saved';
  end if;
  result := public.submit_service_request(r,s,a,'test',null,null,jsonb_build_object(q::text,'5'));
  if result<>r then raise exception 'TEST FAILED: changed request UUID'; end if;
  -- Replaying after a lost response must return the same request, without edits.
  result := public.submit_service_request(r,s,a,'different',null,null,jsonb_build_object(q::text,'10'));
  if (select count(*) from public.service_requests where id=r)<>1 or
     (select customer_notes from public.service_requests where id=r)<>'test' or
     (select count(*) from public.service_request_answers where request_id=r)<>1 or
     (select answer_value from public.service_request_answers where request_id=r)<>'"5"'::jsonb then
    raise exception 'TEST FAILED: retry duplicated or altered the request';
  end if;
end $$;
-- Synthetic attachment metadata checks Storage RLS without storing a real file.
reset role;
insert into public.request_attachments(request_id,uploaded_by,bucket_id,object_path,file_name,content_type,byte_size)
values(current_setting('test.request')::uuid,current_setting('test.owner')::uuid,
 'request-attachments',current_setting('test.owner')||'/'||current_setting('test.request')||'/test.png','test.png','image/png',1);
insert into storage.objects(bucket_id,name)
values('request-attachments',current_setting('test.owner')||'/'||current_setting('test.request')||'/test.png');
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.staff'),true);
do $$
begin
  if not exists(select 1 from public.service_requests where id=current_setting('test.request')::uuid) or
     not exists(select 1 from public.service_request_answers where request_id=current_setting('test.request')::uuid) or
     not exists(select 1 from public.profiles where id=current_setting('test.owner')::uuid) or
     not exists(select 1 from public.addresses where id=current_setting('test.address')::uuid) or
     not exists(select 1 from public.request_attachments where request_id=current_setting('test.request')::uuid) or
     not exists(select 1 from storage.objects where name=current_setting('test.owner')||'/'||current_setting('test.request')||'/test.png') then
    raise exception 'TEST FAILED: admin cannot review the complete request';
  end if;
  if exists(select 1 from public.addresses where profile_id=current_setting('test.owner')::uuid and id<>current_setting('test.address')::uuid) then
    raise exception 'TEST FAILED: staff can read an unlinked customer address';
  end if;
end $$;
select set_config('request.jwt.claim.sub',current_setting('test.other'),true);
do $$
begin
  if exists(select 1 from public.service_requests where id=current_setting('test.request')::uuid) then
    raise exception 'TEST FAILED: another customer can read the request';
  end if;
  begin
    perform public.submit_service_request(gen_random_uuid(),current_setting('test.service')::uuid,
      current_setting('test.address')::uuid,'',null,null,'{}');
    raise exception 'TEST FAILED: another customer can use the address';
  exception when sqlstate '22023' then null;
  end;
  if exists(select 1 from public.service_request_answers where request_id=current_setting('test.request')::uuid) then
    raise exception 'TEST FAILED: answers leaked';
  end if;
  if exists(select 1 from public.addresses where id=current_setting('test.address')::uuid) or
     exists(select 1 from public.request_attachments where request_id=current_setting('test.request')::uuid) or
     exists(select 1 from storage.objects where name=current_setting('test.owner')||'/'||current_setting('test.request')||'/test.png') then
    raise exception 'TEST FAILED: private customer data leaked';
  end if;
end $$;
reset role;
do $$
begin
  if has_function_privilege('anon','public.submit_service_request(uuid,uuid,uuid,text,date,text,jsonb)','EXECUTE') then
    raise exception 'TEST FAILED: anonymous submission allowed';
  end if;
  if not has_function_privilege('authenticated','public.submit_service_request(uuid,uuid,uuid,text,date,text,jsonb)','EXECUTE') then
    raise exception 'TEST FAILED: customers cannot submit';
  end if;
end $$;
select 'PASS: atomic save, validation, retry idempotency, ownership, answer isolation, admin review, private attachment access and anonymous denial' as result;
rollback;
