# Combined Delivery 6 — quality and release readiness

**Status:** Local release-readiness review in progress. A production release is not ready because account-specific, legal, store, and monitoring inputs remain unverified or unconfigured.

## Completed in this pass

- Confirmed the local development config uses connected mode and is ignored by Git; production/staging examples contain no credentials.
- Ran read-only checks against the connected Supabase project: Auth settings, public service categories, public services, and published FAQ returned HTTP 200.
- Added `tool/supabase_smoke_check.py` as a repeatable read-only health check that does not print the project URL or publishable key.
- Built the web release target in both credential-free preview mode and the connected development mode.
- Confirmed CI defines Flutter analysis/tests/web build, Android debug APK artifact, and iOS simulator build jobs.
- Confirmed Android `allowBackup` is disabled.

## Verified local gates

| Gate | Status |
|---|---|
| Static analysis | Pass, 0 issues |
| Flutter tests | Pass, 28 tests |
| Release web build using preview config | Pass |
| Supabase Auth settings | Pass, HTTP 200 |
| Public service category/service reads | Pass, HTTP 200 |
| Published FAQ read | Pass, HTTP 200 |
| Connected development web build | Pass |
| Connected authenticated customer journey | Not tested with a customer account |
| Customer-to-customer isolation | Not tested with separate authenticated users |
| Staff RLS writes and role separation | Not tested with an authenticated staff account |
| Android/iOS device acceptance | Requires native toolchains/devices or hosted CI run against current source |

## Release blockers / owner inputs

1. **Supabase authorization:** the user confirms a staff role is added. Verify the role-scoped policies are applied and test each staff role plus owner/other-customer access with separate authenticated accounts. The public smoke script does not test RLS.
2. **Legal:** replace draft privacy/terms wording with FixPK-approved policies and support contact details.
3. **Brand/store identity:** provide the approved logo/app icon and confirm unique Android application ID and iOS bundle ID ownership.
4. **Signing:** configure Android upload/release key and Apple signing/team/App Store Connect access through protected CI secrets; never add signing material to Git.
5. **Monitoring and notifications:** configure the chosen crash reporting and push delivery providers, privacy settings, platform credentials, and device-token backend. The app currently has in-app notification records only.
6. **Release environments:** populate protected staging/production public Supabase URL and publishable key values; review Supabase Auth redirect URLs and production RLS/storage policies.
7. **Native validation:** test sign-in, password recovery, uploads, keyboard/safe areas, large text, network failure/retry, and logout on representative Android and iOS devices.

## Repeatable checks

Run Flutter checks from the repository root with the pinned Flutter 3.47.7 SDK:

```sh
bash tool/check.sh
python3 tool/supabase_smoke_check.py --config config/development.json
```

The smoke check sends only GET requests to Auth settings and public catalogue/FAQ endpoints. It neither reads customer records nor verifies role policies. Do not use development keys to build a production release.

## Release decision

Do not label an artifact as production-ready until the authorization matrix, approved legal copy, production identifiers/signing, provider setup, native-device acceptance, and crash monitoring are complete. Keep the existing CI debug APK as an internal test artifact.
