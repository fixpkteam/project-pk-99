-- The affected tables are empty or small at deployment. These indexes cover
-- foreign-key joins/deletes and the staff queue's bounded newest-first reads.
create index if not exists appointments_survey_idx on public.appointments(survey_id);
create index if not exists assignments_technician_idx on public.job_assignments(technician_id);
create index if not exists assignments_vendor_idx on public.job_assignments(vendor_id);
create index if not exists attachments_uploader_idx on public.request_attachments(uploaded_by);
create index if not exists area_services_service_idx on public.service_area_services(service_id);
create index if not exists categories_parent_idx on public.service_categories(parent_id);
create index if not exists answers_question_idx on public.service_request_answers(question_id);
create index if not exists requests_address_idx on public.service_requests(address_id);
create index if not exists requests_service_area_idx on public.service_requests(service_area_id);
create index if not exists requests_service_idx on public.service_requests(service_id);
create index if not exists requests_created_id_idx on public.service_requests(created_at desc, id);
