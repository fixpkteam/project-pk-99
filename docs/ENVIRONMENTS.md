# Environment and platform configuration

| Environment | Preview | Backend | Purpose |
|---|---|---|---|
| Development | true by default | None | Phase 1 local UI and tests |
| Staging | false | Separate future project | Integration and UAT |
| Production | false | Separate future project | Approved live service |

Copy the appropriate example to an ignored local JSON file. Use `--dart-define-from-file` consistently for run/build. Empty staging and production files fail validation. Even configured live environments show the startup safety gate until connected bootstrap is implemented in Phase 2.

Keys: `APP_ENV`, `FOUNDATION_PREVIEW`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`. Never put backend secrets in these files. Public keys still require database/storage RLS. Flutter does not make define values secret.

No cloud accounts, databases, buckets, SMS providers, maps credentials, Firebase projects or app store records have been created. No existing external project is linked.

## Platform baseline

- Android target/compile SDK follows the pinned Flutter template; minimum API 24. JDK 17 required.
- iOS minimum deployment target 15.0. Native validation needs macOS, compatible Xcode and CocoaPods.
- Package/bundle identifier `com.fixpk.fixpk` is provisional and unregistered by this work.
- The web target supports reviewing the foundation. It is not a replacement for the separate admin or native release validation.
- No camera/location/notification permission is requested in Phase 1.
- Android internet permission is declared for future network features; no network is initialized by the preview.
- Default launcher icons are temporary until approved logo assets arrive.

Build-time environment isolation exists. Separate native flavours/schemes, unique install IDs, associated domains, signing identities and production provider configuration are release prerequisites and are not claimed as complete here.

## Safe automation

Set `CI=true` and `FLUTTER_SUPPRESS_ANALYTICS=true` for automation. Inspection of Flutter 3.47.7 `packages/flutter_tools/lib/src/base/bot_detector.dart` confirms that CI detection short-circuits its optional Azure metadata probe. No metadata service access is needed for this project. Do not enable that probe to make checks pass.

CI environments must contain no production provider credentials during foundation verification. Native CI builds use the development preview example and are not store releases.
