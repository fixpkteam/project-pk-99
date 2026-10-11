# Combined Delivery 2 — Customer access and service discovery

## Scope completed

- Sign-in, account creation with name/phone metadata, password-reset email request, and sign-out through Supabase Auth.
- Profile metadata sync to `public.profiles` after sign-up/sign-in and profile editing.
- Guest-accessible catalogue page with search, category filters, and live data from `service_categories` and `services`.
- Service detail routes, loading/empty/error/retry states, account entry points, and preview-mode guidance.
- Combined roadmap in `ROADMAP.md` groups the original 14 phases into six deliveries.

## Verification

| Check | Result |
|---|---|
| Flutter static analysis | Passed with no issues |
| Unit/widget tests | Passed: 16 tests |
| Release web build | Passed |
| Live Supabase Auth/catalogue against production data | Not exercised in this environment; local connection config is ignored and not available here |

The web build emits the existing Cupertino font-family warning; the app uses Material icons. This build is a preview build, not a production release.

## Boundaries for the next delivery

Request submission, dynamic questions, attachment uploads, address CRUD, survey scheduling, and quotes are not included yet. Password recovery currently sends the email; app-link handling and the new-password callback require a follow-up integration. Live verification requires a configured public Supabase URL/key, the SQL schema and RLS policies already applied, and Auth email settings configured in Supabase.
