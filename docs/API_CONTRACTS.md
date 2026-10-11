# Backend contracts

The Flutter app talks to Supabase using the publishable key and the signed-in user's JWT. RLS is the access boundary; customer UI visibility is not authorization.

## Implemented customer reads and writes

| Feature | Tables/objects | Access |
|---|---|---|
| Catalogue | published `service_categories`, `services`, `service_questions`, `service_question_options` | Guest reads where policy permits |
| Addresses | `addresses` | Customer reads and writes own rows |
| Request submission | `service_requests`, `service_request_answers`, `request-attachments` bucket, `request_attachments` | Customer inserts own request and answers; storage path is `{auth.uid()}/{request_id}/{file}` |
| Request history | `service_requests` | Customer reads own rows |
| Surveys and appointments | `site_surveys`, `appointments` | Customer reads own records; no direct customer writes |
| Quotes | `quotes`, `quote_items`, `quote-documents` bucket | Customer reads own non-draft quote; decisions use RPC |
| Products | published `product_categories`, `products`, `product_images`, `product_specifications`, `product-images` bucket | Guest reads published products/media; no customer write |
| Projects | published `projects`, `project_images`, `project-images` bucket | Guest reads published projects/media; no customer write |
| Job tracking | `jobs` | Customer reads jobs through ownership of the linked service request; staff/vendor assignment and internal notes are excluded |

`RequestRepository` maps table rows into feature DTOs and is the only request feature layer that imports Supabase. Private projections exclude staff notes.

## Required customer command functions

Run `supabase/sql/request_quote_commands.sql` in the Supabase SQL Editor after the existing FixPK schema and RLS policies. It adds:

- `request_site_survey`: checks `auth.uid()` ownership, locks the request, prevents duplicate active survey requests, and records the requested time.
- `decide_quote`: checks ownership, locks and validates the current sent quote and expiry, then records an approval/rejection or a revision note.

The user reports that these functions have been run in Supabase. Do not put a service-role key in Flutter. Live database access was not available for validation in this workspace.

## Transaction and consistency notes

A submitted request row is created before its answer rows and uploaded files because Supabase Storage paths include its UUID. If later writes fail, the app routes to the durable request and warns the customer against submitting a duplicate. A future server command/outbox should make request, answers and upload metadata more atomic and support resumable attachment uploads.

Quote revision requests are recorded in `customer_decision_note`; the agreed quote status enum has no separate revision-request state. Quote totals must be computed and frozen by trusted staff/backend workflows, never by the Flutter client.


## Products, projects and job tracking

`CatalogueRepository` queries only published product categories/products and projects. Product specifications and image metadata are fetched by parent ID; image binaries remain in the public `product-images` and `project-images` buckets. Public object URLs are constructed from approved stored object paths. Database RLS also requires the parent product/project to remain published.

`JobsRepository` reads only customer-facing job fields for a service request. It never selects `staff_notes` or `job_assignments`. The display summarizes the job's current status and schedule/completion timestamps; the approved schema has no separate `job_events` table, so the UI does not invent historical status timestamps.

Product and similar-project enquiry context travels through service selection and is prefilled into the existing request's customer notes. This avoids introducing an unapproved inquiry table.

## Combined Delivery 5 — customer care and staff operations

The care feature uses only the approved schema columns: notifications are read/marked read; support tickets are created and listed for their owner; published FAQs are read by language; user preferences are upserted by their owner; and reviews are submitted for completed jobs and moderated by staff. The schema does not include device tokens/outbox, support messages, or notification entity keys. Therefore the client provides an in-app inbox, a ticket status/history view, and preference controls; it does not claim outbound push delivery or customer/staff replies.

The staff console reads bounded request, job, ticket, and pending-review queues. Available controls are intentionally limited to job status, ticket status, and review status. The staff UI checks `user_roles` for role-specific controls, but UI checks alone do not secure writes. The supplied core SQL's `staff_manage` policies are broad across staff roles; run `supabase/sql/staff_role_policies.sql` to replace those policies on jobs, support tickets, and reviews with role-scoped writes. Customer-owned/public policies are retained. Review that script against the project before applying it. Live Supabase behavior has not been tested from this workspace.
