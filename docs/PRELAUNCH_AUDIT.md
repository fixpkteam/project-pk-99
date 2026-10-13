# FixPK performance, offline delivery and launch audit

Audit date: 13 October 2026. This document supersedes the older delivery status notes for the changes below. Passing a build is not approval for a public store release.

## Implemented and verified in this audit

| Area | Change and evidence |
|---|---|
| Offline quote requests | Durable, account-scoped outbox and attachment files; save acknowledged only after the local write succeeds. Unit and widget tests cover the complete form-to-queue-to-send journey. |
| Delivery correctness | Stable request UUID, transactional request/answer RPC, single-flight synchronization, retry backoff and deterministic attachment paths. Live rolled-back SQL tests passed atomic save, validation, retry idempotency, ownership, answer isolation and anonymous denial. |
| Failure behavior | Disk-full/corrupt queues are surfaced; permanent validation/permission failures need attention; expired sessions require sign-in. Failed submissions are not silently discarded. |
| Slow connections | Cached catalogue and previously fetched customer details appear before refresh completes; independent catalogue queries run concurrently. API headers/body reads have 20-second inactivity budgets; storage transfers have a five-minute budget. Timeouts signal cancellation to the HTTP transport. |
| Rendering | Product/project lists build lazily; decoded catalogue images have bounded widths; gallery thumbnails have explicit widths. Home passes layout checks at 320/390 logical pixels and normal/double text size. |
| Account boundaries | Private caches use account keys; private repository providers refresh on account changes; queue tests cover sign-out, account switching and account changes during delivery. Server RLS remains authoritative. |
| Admin forms | Service/category publication and slug fields, banner fields and app-content fields now match the live database. Admin changes invalidate customer content and reference pickers. |
| Editable public content | Home campaigns load published, scheduled banner records. Legal screens load published `privacy_policy` and `service_terms` records whose JSON body has a `text` field. Missing policies are not represented as completed policies. |
| Password recovery | Added the new-password screen, confirmation validation, recovery-event navigation and Android/iOS callback registration. Real email/callback delivery still needs the configuration and device check below. |
| Backend connectivity | 30 read-only API probes passed: Auth, 14 public content tables, 13 anonymous private-table denials, anonymous request-RPC denial and anonymous admin-function denial. These do not prove every authenticated mutation. |
| Source quality | 69 unit/widget tests passed; static analysis and local/hosted web compilation passed. The local coverage report records 1,660 of 5,020 instrumented lines (33.1%); this is not exhaustive behavioral coverage. |
| Native verification | Both integration tests passed on Android API 24 and API 36. Connected Android APKs, ARM profile APKs, an unsigned release app bundle and the iOS simulator build compiled successfully in CI. |

## Offline contract

Customer message:

> Your quote request is saved on this device. We’ll send it to the FixPK team when you’re back online with the app open.

- Initial authentication, address creation and first loading of each service form require a connection. Previously loaded catalogue, addresses, questions, request details, quotes, surveys, appointments, notifications, support tickets, FAQs and reviews remain available from their cache.
- The outbox retries while the signed-in app is foregrounded and immediately on resume. A closed or force-stopped mobile app cannot promise background delivery. There is also a manual **Send now** action.
- The cache may show old prices, availability or status while disconnected. Financial decisions, survey booking, profile/address changes, support/review writes and staff actions still require an online server response. Only quote/service-request submission is queued.
- Each request allows at most five attachments, 5 MB each and 20 MB total. The device outbox allows 20 pending requests and 100 MB of attachments. File bytes live in app-private storage, not PostgreSQL. Clearing app data/uninstalling loses unsent requests. Browser storage has browser-specific quotas and clearing behavior.
- A request and its answers commit atomically. Attachment transfers follow that commit. A partially transferred request may already be visible to staff; retries resume attachment delivery with the same request/file identifiers. Removing a local queued copy is not server cancellation.
- Network catalogue images are not guaranteed offline after process restart. Bundled brand imagery remains available. A new store instance is tested for native file durability; a physical force-stop/restart test is still required.

## CI and device checks

All eight jobs passed in [GitHub Actions run 13](https://github.com/fixpkteam/project-pk-99/actions/runs/38352777489), for source commit [`5ab50cd`](https://github.com/fixpkteam/project-pk-99/commit/5ab50cd96634cfe16139deef3d0d036cffcf9d34). This documentation update does not change that tested source.

| CI job | Observed result |
|---|---|
| `checks` | Passed formatting, static analysis, 69 unit/widget tests and web release compilation. |
| `supabase-functions` | Passed Edge Function lint and type checks. |
| `supabase-smoke` | All 30 live read-only/anonymous-denial probes passed. |
| `android` | Preview and Supabase-connected debug APKs built and uploaded. |
| `ios` | iOS simulator debug compilation passed; this was not an iOS UI test run. |
| `android-device-tests (24)` | Two installed-app integration tests passed. |
| `android-device-tests (36)` | The same two installed-app integration tests passed. |
| `android-optimized` | Connected ARM32/ARM64 profile APKs and the production-mode unsigned app bundle built and uploaded. |

The emulator tests verify:

1. Installed startup and navigation through the five main tabs.
2. Native durable outbox/attachment storage across fresh store instances, followed by exactly one delivery through a simulated disconnected/reconnected sender.

They use preview configuration, do not disable the OS network and do not create production customer records. They therefore do not prove authenticated customer/staff journeys, real network restoration or physical-device speed.

The run's **Artifacts** section contains the following downloads, available until 27 October 2026:

| Artifact | Intended use |
|---|---|
| `fixpk-profile-apks-13` | Connected optimized profile APKs for physical Android testing. Flutter reports 32.7 MB for ARM32 and 35.0 MB for ARM64. |
| `fixpk-connected-apk-13` | Supabase-connected debug APK for functional debugging; do not use debug timings as release performance measurements. |
| `fixpk-debug-apk-13` | Preview-only debug build. |
| `fixpk-unsigned-release-bundle-13` | Production-mode compilation proof; Flutter reports a 58.3 MB AAB. It still requires approved release signing before Play submission. |

These are compiled file sizes, not measured installed sizes or Play download estimates. No physical phone measurements were available in this environment.

Run locally with the pinned Flutter/Dart toolchain:

```sh
bash tool/check.sh
flutter test integration_test/app_smoke_test.dart -d <device-id> --dart-define-from-file=config/development.example.json
python3 tool/supabase_smoke_check.py --config config/development.json
```

`supabase/tests/offline_request_submission.sql` uses synthetic data in a transaction and ends with `ROLLBACK`. It was executed successfully against the connected project. The deployed migration is recorded as `20261012093831_offline_request_submission.sql`; do not run a second copy under another version.

## Launch blockers and remaining coverage

| Gate | Current evidence / required action |
|---|---|
| Real service content | Live counts on 13 October: services, products, projects, FAQ and app-content records are all zero. Publish approved services/questions/service areas and useful business content; do not ship screenshot samples as real products or projects. No real customer request can be composed until services exist. |
| Legal and account deletion | Publish approved privacy/service terms, provide the public privacy/deletion URLs and implement the reviewed customer account/data deletion flow. The current admin suspension control is not account deletion. |
| Auth delivery | Add `com.fixpk.fixpk://login-callback/` to Supabase Auth redirect URLs. A hosted web build also needs its exact HTTPS origin and SPA fallback hosting for path URLs. Verify confirmation/recovery email delivery and cold/warm mobile callbacks with controlled accounts. SMTP delivery was not exercised and no emails were sent during this audit. |
| Upload signing | Configure the approved Android upload key and signing pipeline; verify package ID ownership, increasing version code, signed app bundle and Play Console checks. No signing key is embedded or generated by this audit. |
| Physical performance | Measure profile builds on a low-memory Android phone and a current phone, with cold/warm launches, 400 ms RTT / 256 kbit/s throttling, packet loss, airplane mode and network switching. Record p50/p95 startup, frame times, memory and queue delivery. Emulator/debug timings cannot prove the fastest performance on every device. |
| Authenticated business journeys | Exercise customer/admin/staff accounts in staging with real-shaped fixtures: address CRUD, uploads and signed documents, survey booking, quote approve/reject/revision, jobs, reviews, support, admin CRUD and role/suspension changes. Only the stated request RPC transaction and anonymous API matrix have live integration evidence so far. |
| Staff operations scope | Existing staff queues cover request summaries, job status, support status and review moderation. They do not provide a complete survey/quotation/technician scheduling authoring console. This remains a product gap if all operations must be performed inside the app. |
| Notifications/integrations | In-app notification records and saved communication preferences exist. FCM delivery, analytics/crash reporting, Maps and outbound email/SMS/WhatsApp integrations are not configured and are not certified by these tests. |
| History/large datasets | Several screens intentionally load recent bounded batches (requests/support 50, notifications/admin content 100). Full-history pagination/search and representative large-dataset profiling remain outstanding; cached reads must not be described as complete history. |
| Upload resilience | Attachments use bounded standard uploads, not resumable TUS uploads or automatic image compression. Very weak connections may need smaller files or a later retry. Verify server-side MIME/size limits for private buckets; client limits alone are not a server security control. |
| Auth hardening | Supabase reported leaked-password protection disabled. Review and enable it where available. The role-check helper remains intentionally callable for public RLS evaluation; authenticated quote/survey SECURITY DEFINER functions require their existing ownership guards. |

Supabase advisor references: [password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), [anonymous function advisory](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable), [authenticated function advisory](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

The source audit and automated checks improve reliability substantially, but the open gates above mean this app is not yet certified ready for public launch. No universal device-speed guarantee is made.
