# FixPK — Phase 1 foundation

Flutter customer-app foundation for Android and iOS, with a web target for development review.

## Included

- Flutter **3.47.7**, bundled Dart **3.13.5**, exact direct dependency pins and a resolved lockfile.
- Feature-based structure, Riverpod dependency injection and `go_router` indexed navigation.
- Home, Services, Requests, Projects and Account shell. Service search and branch state work locally.
- FixPK blue/navy/white theme and interactive component gallery at `/components`.
- Startup loading/failure/retry, unknown-route recovery, configuration validation and event-only logging.
- Preferences and secure-storage interfaces/adapters, ready for future feature integration.
- Unit/widget tests, CI configuration and architectural/API planning documents.

This is a clearly labelled foundation preview. It does not authenticate, submit requests, upload files, create backend resources or contain customer data. Gallery examples are explicitly samples.

## Run

Install Flutter 3.47.7 from the official SDK archive, or use FVM with `.fvmrc`. Verify `flutter --version` reports Dart 3.13.5.

If a prebuilt archive is unavailable, install the verified source release tag:

```sh
git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git flutter-sdk
export PATH="$PWD/flutter-sdk/bin:$PATH"
CI=true FLUTTER_SUPPRESS_ANALYTICS=true flutter --version
```

CI uses this source-tag route and verifies commit `abaf9c523780a608bd46686fd5e53740a07077f8`.

```sh
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=config/development.example.json
```

For a browser review, select an installed Chrome device:

```sh
flutter run -d chrome --dart-define-from-file=config/development.example.json
```

Do not use a development preview as a production release. Staging/production examples intentionally fail until configured; connected bootstrap is deliberately gated until Phase 2.

## Validate

```sh
bash tool/check.sh
flutter build apk --debug --dart-define-from-file=config/development.example.json
# macOS with Xcode and CocoaPods:
flutter build ios --simulator --debug --dart-define-from-file=config/development.example.json
```

`tool/check.sh` performs version, dependency-lock, formatting, analysis, unit/widget tests and web-build checks. Native builds require their platform toolchains. CI includes Android and iOS simulator build jobs, but a local workflow file does not mean hosted CI has run.

## Structure

| Path | Responsibility |
|---|---|
| `lib/app/` | Bootstrap, root providers, router and shell |
| `lib/core/config/` | Validated build-time public configuration |
| `lib/core/theme/` | Palette, typography, spacing and Material theme |
| `lib/core/widgets/` | Reusable controls, cards and states |
| `lib/core/storage/` | Preference and secret adapters |
| `lib/core/logging/` | Enumerated, payload-free events |
| `lib/features/foundation/presentation/` | Preview shell and component gallery |
| `test/` | Config, navigation, responsive controls and forms |
| `docs/` | Decisions, contracts, migration plan and validation record |

## Brand and release limitations

The app uses plain `FixPK` text as its title, not a recreated logo. Place an approved master logo in `assets/brand/` and register it when supplied. Default Flutter launcher icons are development placeholders. Screenshot product prices, example reviews and photographs have not been imported as real data. System fonts are used pending the approved typeface asset.

Initial native identifier is `com.fixpk.fixpk`; confirm ownership and environment-specific identifiers before release. Android minimum API and iOS deployment target are documented in `docs/ENVIRONMENTS.md`.

Read `docs/PHASE_1_STATUS.md` for checks actually performed and remaining acceptance gates.

## Verified handoff

Static analysis, all 13 unit/widget tests and the web release build passed on 11 October 2026. Android/iOS builds and device storage checks remain outstanding. Review phone renders in `docs/previews/home.png` and `docs/previews/services.png`; reproduction instructions are in the validation record. Phase 2 is not implemented.
