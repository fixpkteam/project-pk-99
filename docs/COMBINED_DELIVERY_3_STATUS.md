# Combined Delivery 3 — Request-to-quote workflow

## Scope completed

- Saved address list, add/edit/delete forms and default-address selection.
- Service-specific question loading and dynamic text, number, date, select, multi-select and boolean controls.
- Five-step request wizard for requirements, attachments, address, schedule and review.
- Private request attachment uploads with file-type and 10 MB per-file validation, plus metadata rows.
- Customer request history and request details with status and public reference.
- Site-survey requests, customer-visible appointment summaries, quote revisions/items/totals, and approve/reject/revision-note actions.
- Ownership-checked `request_site_survey` and `decide_quote` functions in `supabase/sql/request_quote_commands.sql`.
- Partial write handling routes customers to the already-created request rather than inviting a duplicate submission.

## Supabase activation

The core schema and table policies were applied manually by the project owner in the Supabase dashboard. The two additional command functions have not been applied remotely. Run `supabase/sql/request_quote_commands.sql` in the SQL Editor after reviewing it against the active schema. The connected app's survey and quote decision actions depend on those functions. Do not use a service-role key in the app.

The current repository performs request insert, answer insert, and file uploads as separate requests. If answer/file work fails after the request insert, the customer sees a recovery message and the request remains available. A future transactional server submission command and resumable upload work would provide stronger recovery.

## Verification

| Check | Result |
|---|---|
| Flutter formatter | Passed |
| Flutter static analysis | Passed with no issues |
| Unit/widget tests | Passed (19 tests) |
| Release web build | Passed |
| Live Supabase Auth, RLS, storage and RPC run | Not exercised; no local connected config was available |
| Android/iOS device validation | Not exercised in this environment |

The web build emits existing Cupertino font-family and Wasm dry-run notices. It completes successfully and includes only Material icons.

## Next combined delivery

Delivery 4 combines job tracking, products and projects. It depends on the customer request, service and catalogue foundations completed in Deliveries 2–3.
