# FixPK admin console and prelaunch verification

Current verification and open launch gates: [13 October audit](PRELAUNCH_AUDIT.md).

## Admin console

The signed-in `admin` role can open `/admin` from the account screen. The console provides:

- Customer-facing services, categories and dynamic request-form questions/options.
- Product categories, products, product images and specifications.
- Projects and project images.
- FAQs, home banners and localized app-content records.
- User account lookup, staff-role changes, sign-in suspension/restoration, and the existing operations queues.
- Add, edit, publish/hide, and delete controls for allowlisted content tables. Foreign-key constraints remain active; the app cannot force-delete records that are in use.

The client uses the Supabase publishable key and the signed-in user session. Admin screen visibility is a convenience only. `supabase/sql/admin_console_policies.sql` must be applied to authorize catalogue/content writes in PostgreSQL. It uses the existing `has_staff_role(text[])` function and grants the editor only to the `admin` role. Public catalogue read policies are preserved. Product/project storage writes are admin-only. Customer request files and quote documents are not opened to the admin editor.

User account email addresses and Auth suspension controls require the Edge Function. It validates the caller's JWT, rechecks the `admin` role server-side, and uses the Supabase service key only in the Edge Function environment. It supports a 50-user page size, role assignment/removal, and temporary sign-in suspension/restoration. It blocks self-suspension, self-removal of the admin role in the UI, concurrent removal of the last administrator through a database lock, and suspension of any account that still has the admin role. Remove an admin role before suspending that account. Account deletion is intentionally not offered because customer records and retention rules need a reviewed deletion process.

### Supabase setup required

1. Review and run `supabase/sql/admin_console_policies.sql` in the Supabase SQL Editor. It also creates or updates the public catalogue image buckets and a service-role-only, transaction-locked RPC that protects the last admin role.
2. Deploy with `supabase functions deploy admin-user-management`.
3. Confirm the function environment contains `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`. Supabase supplies these for hosted functions; for other runtimes, configure them as protected function secrets. Never add the service-role key to Flutter, GitHub variables, or this repository.
4. Confirm the intended account is registered in Supabase Auth and has the `admin` row in `public.user_roles`. The password is managed by Supabase Auth; it is not included in source, build settings, or test fixtures.
5. Configure the GitHub repository variables `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` to enable the connected-backend smoke check and connected Android artifact. These are public client configuration values; RLS and JWT validation remain the security boundary.

## Verification phases

| Phase | Automated or manual checks | Exit condition |
|---|---|---|
| 1. Source quality | Pinned Flutter SDK, lockfile resolution, formatting, analyzer with fatal infos, all unit/widget tests, web compilation, Deno lint/type check | Workflow checks pass without analyzer infos or test failures |
| 2. Guest journeys | Startup, home shortcuts, service search/filter, product and project previews/details, support FAQ/legal navigation, back and deep-link fallbacks | Every guest action reaches a valid screen and each loading/empty/error path has a recovery route |
| 3. Customer journeys | Sign-up/sign-in/password reset, profile and address CRUD, dynamic request answers, attachment upload, preferred schedule, submission, request history, survey, quote decision, job progress, notifications, support and review submission | Exercise with dedicated staging customer accounts and owned/unowned records; verify successful and denied operations |
| 4. Admin and authorization | Admin role gate, guest/ordinary-user denial, content CRUD, publication controls, FK-protected deletion, role changes, last-admin guard, suspension/restoration, staff queues, storage upload/delete | Admin writes succeed; non-admin writes fail at RLS/function boundary; no service key appears in a client build |
| 5. Connections | Auth settings, public services/categories/FAQ reads, Storage uploads, RPCs, Edge Function actions, retry on timeout/offline, session refresh | Connected smoke checks pass and each private operation is verified with an authenticated staging session |
| 6. Device/release checks | Android install and navigation on small/standard/large devices; iOS simulator build; keyboard, safe areas, text scaling, upload permissions, app resume/session persistence | No release-blocking crash, layout failure, blocked primary action, or sensitive-data leak |

The existing CI already covers Flutter formatting, static analysis, the repository's unit/widget tests, a web build, Android build/APK artifact, and iOS simulator compilation. This change adds Edge Function lint/type checks and an optional read-only Supabase smoke job. The connected Android artifact and smoke job run only after the two public Supabase repository variables are configured.

## Test boundaries

A successful APK build does not prove authenticated RLS, storage policies, Edge Function secrets, email delivery, or real-device behavior. Until the deployment steps and staging account matrix above are exercised, these remain unverified. Do not use customer production data for destructive test cases; use dedicated test users and disposable content in a staging project.
