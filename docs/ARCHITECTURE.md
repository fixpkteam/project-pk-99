# Phase 1 architecture decisions

Approved scope: foundation only, following the seven-part planning response. No Supabase project or migrations are created.

## ADR-001 — toolchain

Pin Flutter 3.47.7 (stable release tag, commit abaf9c523780a608bd46686fd5e53740a07077f8) and bundled Dart 3.13.5. A detached SDK checkout can report `user-branch` even though it points to the exact stable release tag. `.fvmrc`, CI and the version check agree. Direct dependencies are exact; transitive versions and archive hashes live in `pubspec.lock`.

Upgrade via a dedicated change that updates pins and lockfile, runs all checks, validates Android/iOS, and passes staging. Never automatically upgrade dependencies in a release job.

## ADR-002 — module boundaries

UI -> application/controller -> repository interface -> data adapter -> authorized backend.

Core owns cross-cutting code only. A future `features/requests/` module will have `presentation/`, `application/`, `domain/` and `data/` directories when those implementations exist. Do not add empty speculative classes or depend on UI classes from repositories. DTOs belong in data; domain models contain no widget or Supabase types.

The foundation catalogue is a small, explicitly labelled local presentation fixture. It must be replaced with the service repository in Phase 3. It makes no network calls and no claim of current pricing or availability.

## ADR-003 — state and dependencies

Riverpod owns root configuration, bootstrap, logger, storage adapters and router lifecycle. Future controllers expose explicit loading/data/failure state. Use provider overrides for tests. Do not add a second DI container. Use widget-local state for short-lived gallery interactions.

Configuration errors are not network errors. Startup must fail safely, show a retry action and never print configuration values. Live connections are not initialized during Phase 1.

## ADR-004 — navigation

`StatefulShellRoute.indexedStack` preserves branch state for Home, Services, Requests, Projects and Account. Component gallery is a separate route so system back returns to the previous branch. Unknown links show recovery to Home. Future private record routes need both an auth guard and backend ownership checks. Deep-link route parsing alone never grants access.

Verified routes: `/`, `/home`, `/services`, `/requests`, `/projects`, `/account`, `/components`. `/requests` and `/account` currently show preview placeholders; they contain no private data. Auth guards and universal/app link registration are Phase 2 work.

## ADR-005 — configuration and secrets

Only public mobile configuration can use Dart defines. A mobile binary is inspectable. No service-role key, FCM server secret, SMS password or database password can be embedded. Connected mode accepts only the explicit `sb_publishable_` key form and HTTPS origins. Backend RLS remains mandatory; a publishable key is not an authorization boundary.

Phase 1 uses development preview mode by default. Staging and production reject preview. Live mode is gated even with syntactically valid credentials. This prevents an incomplete app appearing operational.

## ADR-006 — persistence and diagnostics

`PreferencesStore` is for non-sensitive flags. `SecretStore` namespaces keys and delegates to platform secure storage. Authentication session integration and encrypted drafts are not yet implemented; adding the adapter does not encrypt arbitrary files or Supabase's defaults. Future session storage must explicitly use the secure adapter and be tested.

Logger accepts an `AppEvent` enum only: no free-text messages, exception values, URLs or payload maps. Framework and asynchronous errors record a generic event. Add a redacted, consent-aware crash reporter later; current diagnostics intentionally contain no exception detail.

## ADR-007 — design system

Palette follows the supplied FixPK screenshot, with a darker action blue for contrast. Values are provisional visual approximations. Use the exact approved logo when provided. No image generation, cropped UI screenshots or fabricated brand mark is used. System sans-serif is temporary; text scaling is preserved. Static skeletons avoid unnecessary motion.

## ADR-008 — admin/backend foundations

Admin remains a separate React/TypeScript application planned for later feature phases, sharing contracts rather than customer widget code. Phase 1 defines its boundary; no empty admin application is generated. Operational modules should be implemented alongside the related customer phases, not left entirely until Phase 12.

References checked during implementation:
- https://docs.flutter.dev/install/archive
- https://docs.flutter.dev/app-architecture/recommendations
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/go_router
- https://pub.dev/packages/supabase_flutter
