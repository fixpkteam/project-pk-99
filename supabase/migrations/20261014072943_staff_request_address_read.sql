-- Staff see only addresses already attached to customer requests.
create policy addresses_staff_request_read on public.addresses
for select to authenticated using (
  (select public.has_staff_role(array['admin','operations','estimator','support']))
  and exists (select 1 from public.service_requests r where r.address_id=addresses.id)
);

-- Private attachments remain private; staff access requires a matching record.
create policy request_files_staff_read on storage.objects
for select to authenticated using (
  bucket_id='request-attachments'
  and (select public.has_staff_role(array['admin','operations','estimator','support']))
  and exists (select 1 from public.request_attachments a
    join public.service_requests r on r.id=a.request_id
    where a.bucket_id=objects.bucket_id and a.object_path=objects.name)
);
