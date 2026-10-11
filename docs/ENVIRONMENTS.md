# Environment and platform configuration

| Environment | Preview | Backend | Purpose |
|---|---|---|---|
| Development | true in the example | Connected when configured | Local UI preview or Supabase development project |
| Staging | false | Separate Supabase project | Integration and UAT |
| Production | false | Separate Supabase project | Approved live service |

Copy the appropriate example to an ignored local JSON file. For development, set `FOUNDATION_PREVIEW` to `false` and provide `SUPABASE_URL` plus `SUPABASE_PUBLISHABLE_KEY`. Use `--dart-define-from-file` consistently for run/build. Empty staging and production files fail validation. Connected startup initializes the official Flutter client and restores its local auth session. It does not create database resources or query application tables.

Keys: `APP_ENV`, `FOUNDATION_PREVIEW`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`. Never put backend secrets in these files. The publishable key is included in the compiled app and is not an authorization boundary; database/storage access requires correct RLS and storage policies. Flutter does not make define values secret.

The supplied Supabase project URL is configured for local development. This integration does not create or alter database tables, buckets, Auth settings, SMS providers, maps credentials, Firebase projects or app store records.

## Platform baseline

- Android target/compile SDK follows the pinned Flutter template; minimum API 24. JDK 17 required.
- iOS minimum deployment target 15.0. Native validation needs macOS, compatible Xcode and CocoaPods.
- Package/bundle identifier `com.fixpk.fixpk` is provisional and unregistered by this work.
- The web target supports customer flows and the role-gated Flutter admin console. Native release validation still requires Android/iOS device testing.
- No camera/location/notification permission is requested in Phase 1.
- Android internet permission is declared for future network features; no network is initialized by the preview.
- The supplied FixPK artwork now provides Android, iOS and web/PWA launcher icons. The Android application ID and iOS bundle ID remain provisional.

Build-time environment isolation exists. Separate native flavours/schemes, unique install IDs, associated domains, signing identities and production provider configuration are release prerequisites and are not claimed as complete here.

## Safe automation

Set `CI=true` and `FLUTTER_SUPPRESS_ANALYTICS=true` for automation. Inspection of Flutter 3.47.7 `packages/flutter_tools/lib/src/base/bot_detector.dart` confirms that CI detection short-circuits its optional Azure metadata probe. No metadata service access is needed for this project. Do not enable that probe to make checks pass.

CI environments must contain no production provider credentials during foundation verification. Native CI builds use the development preview example and are not store releases.
