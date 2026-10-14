# FixPK polish and launch review — 14 October 2026

## Requested work

- [x] Replace blurred-looking artwork with a high-resolution FixPK wordmark, launcher exports and lossless runtime logo; centre/enlarge the authentication logo.
- [x] Replace the black Android launch theme, including night mode and Android 12+, and use a branded startup placeholder without an artificial delay.
- [x] Fix confirmed-account sign-in: successful authentication no longer depends on an unauthorized profile upsert. Profile editing updates only allowed fields on the owned row.
- [x] Rebuild Home and Services around the supplied white/navy/blue references, bundled house imagery and 3D service icons.
- [x] Publish 12 real service categories and 16 services, including websites, apps, social media management, ads/promotion and influencer marketing.
- [x] Add customer-audience filters and editable category audiences in the admin console.
- [x] Add a paginated admin/staff quote-request queue and details: customer, address, schedule, answers, notes and private attachment download links.
- [x] Verify atomic request submission, repeat-submit idempotency, admin visibility and customer isolation against the live database using rolled-back synthetic records.
- [x] Verify the 30 public API/anonymous-access probes. No synthetic customer data remains.
- [x] Check Home, Services, sign-in and signup at 320 logical pixels and 200% text scale; render the redesigned screens for visual review.
- [ ] Complete final native CI builds and publish the optimized packages.
- [ ] Measure startup and scrolling on physical low-end/current phones under slow-network conditions.

## Findings and fixes

The confirmed customer had already authenticated successfully. A subsequent client profile upsert was rejected because profile creation is handled by an Auth trigger and clients can only update selected columns. This secondary write made a successful login appear to fail. Login now only performs authentication; a regression test rejects all profile endpoints while requiring sign-in success.

The live catalogue was empty. The seeded catalogue is published and queryable by customers. Seed statements preserve existing records by slug; future edits use the admin console. Required requirements questions are available for all 16 services. No sample price or free-survey promise was introduced.

Staff could read request rows but lacked access to linked addresses and private uploaded files. Narrow read policies now allow authorized operations staff to inspect only addresses associated with requests and files linked through attachment records. The initial address policy cycle was caught by the live transaction test and corrected using a private, role-checked helper. Customer isolation and replay safety tests pass after the correction. Foreign-key indexes and a newest-first request queue index address the concrete lookup gaps found in the database audit.

## Performance evidence and limits

The native theme is white in light and dark device modes. There is no fixed splash timer. Normal startup uses local preferences/session restoration and does not intentionally wait for catalogue requests. Network session refresh runs asynchronously through the Supabase SDK.

Home imagery and icons are bundled. The hero is about 200 KB and twelve service icons total about 80 KB. The shared wordmark uses lossless WebP; image decoding is limited to the physical display size. Home and Services use lazy slivers, local search/filtering, retained tab state and bounded widths. Cached data is emitted before the best-effort fresh-cache write completes.

The previous connected APK was a debug build, which is unsuitable for judging release startup/frame performance. Use the new ARM profile APKs for physical measurements. A two-to-three-second cold-start target and smooth scrolling on slow phones remain targets, not measured guarantees. No claim of fastest performance on every device is made.

## Offline behavior

> Your quote request is saved on this device. We’ll send it to the FixPK team when you’re back online with the app open.

The account-scoped durable outbox, attachment persistence, single-flight delivery, retry backoff and manual Send now action remain intact. Previously loaded catalogue/forms/addresses are cached. First sign-in, new addresses and first loading of a form still require connectivity. Delivery retries while foregrounded or on resume; a force-stopped app cannot promise background delivery.

## Admin access

The confirmed administrator is `fixpkteam@gmail.com`, with the `admin` database role. A password sign-in using the previously supplied password returned **Invalid login credentials**. The password cannot be read from Supabase and has not been reset. Use **Sign in → Forgot password**, then **Account → Admin panel → Quote requests** after recovery. Verify the allowed mobile callback URL `com.fixpk.fixpk://login-callback/` and actual email delivery. No recovery email was sent by this audit and no credentials are stored in the repository.

## Play Store readiness: not ready for public release yet

| Remaining gate | Required evidence or work |
|---|---|
| Privacy and deletion | The live privacy/terms content is empty. Publish approved policies and public URLs; provide the in-app and web account/data deletion request paths and an operational deletion/retention process. |
| Release signing | Configure the approved Android upload key and sign the production app bundle. The CI release AAB is intentionally unsigned. Confirm package ID ownership and Play Console app access. |
| Physical performance | Profile cold/warm startup, scrolling, memory, low storage, airplane mode, reconnect and actual attachment upload on low-end/current devices. Test at 400 ms RTT and 256 kbit/s, with packet loss. |
| Auth recovery | Recover the administrator account and verify confirmation/recovery links on cold and warm app starts, including the configured SMTP provider. |
| Business journey coverage | Perform staging customer/staff acceptance for surveys, quote decisions, job updates, support, reviews, role changes and uploads. This audit does not certify every authenticated operation. |
| Operations scope | The new request review UI works; full quotation creation, survey scheduling and technician assignment authoring remain incomplete if these must all occur in-app. |
| Store setup | Complete Data safety, privacy URL, content rating, listing assets, reviewer access, pre-launch report and any account-specific testing gate. |

The pinned Flutter 3.47.7 toolchain targets Android API 36, satisfying the currently stated new-app target level. This alone does not establish store eligibility. For personal developer accounts created after 13 November 2023, check the closed-test requirement in Play Console.

Official references checked 14 October 2026: [target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-GB), [account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-GB), [new personal account testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB).

Supabase advisories still include intentional role-separated policies and guarded SECURITY DEFINER functions; they are not disabled to silence lints. [Leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) is disabled and should be enabled where supported. Review [function advisories](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) and [policy advisories](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies) before broader operational rollout.

## Automated verification

Results and CI artifact links will be recorded here after the final pipeline completes. The local analyzer snapshot crashes in this workspace; the clean GitHub runner is the authoritative static-analysis/build gate.
