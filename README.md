# FixPK — Flutter application

Flutter customer-app foundation for Android and iOS, with a web target for development review.

## Included

- Flutter **3.47.7**, bundled Dart **3.13.5**, exact direct dependency pins and a resolved lockfile.
- Feature-based structure, Riverpod dependency injection and `go_router` indexed navigation.
- Home, searchable service catalogue, service categories/details, guest browsing, and an account entry point.
- Supabase Auth sign-in/sign-up, password-reset email request, profile editing, and sign-out in connected mode.
- Published service categories and services load from Supabase; preview mode remains credential-free.
- Saved address management and a dynamic five-step request form with answers, schedule preferences, and private attachment uploads.
- Customer request history/details, site-survey requests, appointment summaries, quote line items, and secure quote decisions through PostgreSQL functions.
- Published product and project catalogues with media/specifications, and customer-safe job progress tracking. Product/project enquiry context carries into the service request notes.
- Customer notifications, support tickets and FAQ, review submission, preferences, legal information, and staff queues for requests/jobs/support/review moderation.
- FixPK blue/navy/white theme and interactive component gallery at `/components`.
- Startup loading/failure/retry, unknown-route recovery, configuration validation and event-only logging.
- Preferences and secure-storage interfaces/adapters, ready for future feature integration.
- Unit/widget tests, CI configuration and architectural/API planning documents.

The app supports a local preview and connected Supabase mode. Delivery 3 implements the customer request-to-quote journey, and the user reports running the supplemental survey/quote command SQL. Delivery 4 implements job progress, products, and projects. Delivery 5 implements customer care and an in-app staff console. Live backend verification still depends on a connected environment. Gallery examples are explicitly samples.

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
cp config/development.example.json config/development.json
# Edit config/development.json: set FOUNDATION_PREVIEW=false and supply your
# Supabase project URL and publishable key to connect the Flutter client.
flutter run --dart-define-from-file=config/development.json
```

For a browser review, select an installed Chrome device:

```sh
flutter run -d chrome --dart-define-from-file=config/development.example.json
```

The development example remains a credential-free preview. Do not use it as a production release. Staging/production examples intentionally fail until configured. `config/*.json` is ignored by Git; never place server secrets in build-time config.

## Validate

```sh
bash tool/check.sh
flutter build apk --debug --dart-define-from-file=config/development.example.json
# macOS with Xcode and CocoaPods:
flutter build ios --simulator --debug --dart-define-from-file=config/development.example.json
```

`tool/check.sh` performs version, dependency-lock, formatting, analysis, unit/widget tests and web-build checks. Native builds require their platform toolchains. CI includes Android and iOS simulator build jobs, but a local workflow file does not mean hosted CI has run.

For a read-only health check of the configured connected development project, run `python3 tool/supabase_smoke_check.py --config config/development.json`. It checks Auth settings and public categories/services/FAQ only; it does not verify private customer data access, staff role policies, or production release credentials.

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
| `lib/features/auth/` | Supabase Auth and customer profile screens/data access |
| `lib/features/services/` | Service catalogue models, queries and screens |
| `lib/features/requests/` | Saved addresses, request submission/history, surveys and quotations |
| `lib/features/catalogue/` | Published product/project catalogue reads, media, specifications and screens |
| `lib/features/jobs/` | Customer-safe job progress and staff job status operations |
| `lib/features/care/` | Notifications, support, FAQs, preferences, reviews, legal information and staff queues |
| `test/` | Config, navigation, responsive controls and forms |
| `supabase/sql/` | Customer-safe survey and quote command functions to apply after the core schema |
| `docs/` | Decisions, contracts, migration plan and validation record |

## Brand and release limitations

The app uses plain `FixPK` text as its title, not a recreated logo. Place an approved master logo in `assets/brand/` and register it when supplied. Default Flutter launcher icons are development placeholders. Screenshot product prices, example reviews and photographs have not been imported as real data. System fonts are used pending the approved typeface asset.

Initial native identifier is `com.fixpk.fixpk`; confirm ownership and environment-specific identifiers before release. Android minimum API and iOS deployment target are documented in `docs/ENVIRONMENTS.md`.

Read `docs/ROADMAP.md` for the combined delivery plan, `docs/COMBINED_DELIVERY_5_STATUS.md` for customer care delivery, `docs/COMBINED_DELIVERY_6_STATUS.md` for release readiness, and `docs/PHASE_1_STATUS.md` for the foundation record.

## Verified handoff

Combined Delivery 5 validation and the limited connected Supabase smoke check are recorded in `docs/COMBINED_DELIVERY_5_STATUS.md` and `docs/COMBINED_DELIVERY_6_STATUS.md`. Customer/staff RLS and Android/iOS device checks remain outstanding. Review phone renders in `docs/previews/home.png` and `docs/previews/services.png`; reproduction instructions are in the validation records.
