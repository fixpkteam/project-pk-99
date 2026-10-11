# Combined Delivery 4 — Fulfilment and solution catalogue

## Scope completed

- Published product category and product catalogue screens with local search and category filters.
- Product detail screens with published images, descriptions, pricing when present, availability, SKU and specifications.
- Published FixPK project portfolio and project detail screens with approved public images, category, location and completion date.
- Product quote and similar-project actions preserve the selected item/project context through service selection and prefill the service request notes.
- Customer-safe job progress cards on request details, showing the job's current status and available schedule/completion dates.
- Repositories select only published catalogue rows and customer-visible job columns. Staff notes and technician/vendor assignments are not fetched.
- Product/project and job model mapping tests.

## Backend assumptions used

- Products, projects and their images are publicly readable only when published; media uses public `product-images` and `project-images` buckets.
- Customer job reads are protected by RLS through the linked service request's owner. The client filters by the request ID and never selects internal staff notes.
- The approved schema has no product-enquiry table and no `job_events` history table. Enquiry context is saved into an existing service request; progress is based on current job status and stored timestamps.
- The user reports that the Delivery 3 survey/quote command functions have been run in Supabase. This workspace has no connected project config, so policies, catalog rows and RPC availability were not live-tested here.

## Verification

| Check | Result |
|---|---|
| Dart formatter | Passed |
| Flutter static analysis | Passed with no issues |
| Unit/widget tests | Passed: 22 tests |
| Release web build | Passed |
| Live Supabase product/project/job reads | Not exercised; no local connected config available |
| Android APK build | Not locally verified; Android SDK is not installed in this environment |
| Android GitHub Actions build | Workflow already includes a debug APK build and artifact upload |
| iOS device build | Not exercised; native Apple toolchain is unavailable here |

The release web build emits existing Cupertino font-family and Wasm dry-run notices; it completed successfully.

## Next combined delivery

Delivery 5 combines customer care, notifications, reviews, support, account completion and admin operations.
