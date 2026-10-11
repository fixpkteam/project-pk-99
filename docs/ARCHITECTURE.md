# FixPK application architecture

This document records the project architecture decisions and the current customer app boundaries. Phase-specific status is recorded separately in the delivery status files.

## ADR-001 — toolchain

Pin Flutter 3.47.7 (stable release tag, commit abaf9c523780a608bd46686fd5e53740a07077f8) and bundled Dart 3.13.5. A detached SDK checkout can report `user-branch` even though it points to the exact stable release tag. `.fvmrc`, CI and the version check agree. Direct dependencies are exact; transitive versions and archive hashes live in `pubspec.lock`.

Upgrade via a dedicated change that updates pins and lockfile, runs all checks, validates Android/iOS, and passes staging. Never automatically upgrade dependencies in a release job.

## ADR-002 — module boundaries

UI -> application/controller -> repository interface -> data adapter -> authorized backend.

Core owns cross-cutting code only. Implemented customer modules currently separate `presentation/` and `data/`; add application/domain layers when a feature needs shared business rules or multiple presentation clients. Do not add empty speculative classes or depend on UI classes from repositories. DTOs belong in data; domain models contain no widget or Supabase types.

The connected service catalogue reads published categories and services from Supabase. Preview mode remains explicitly labelled and makes no network calls or claims about current pricing or availability.

## ADR-003 — state and dependencies

Riverpod owns root configuration, bootstrap, logger, storage adapters and router lifecycle. Riverpod providers expose explicit loading/data/failure state and repository providers provide feature-level dependency injection. Use provider overrides for tests. Do not add a second DI container. Use widget-local state for short-lived gallery interactions.

Configuration errors are not network errors. Startup must fail safely, show a retry action and never print configuration values. Connected builds initialize Supabase during bootstrap before exposing the client provider. A publishable key is public and all data access still requires server-side RLS and storage policies.

## ADR-004 — navigation

`StatefulShellRoute.indexedStack` preserves branch state for Home, Services, Requests, Projects and Account. Component gallery is a separate route so system back returns to the previous branch. Unknown links show recovery to Home. Private request and address screens require an authenticated user and rely on backend ownership policies. Deep-link route parsing alone never grants access. Universal/app-link registration and full password recovery callback handling remain release work.

Verified route families include `/`, `/home`, `/services`, `/services/:serviceId`, `/requests`, `/requests/new`, `/requests/:requestId`, `/account`, `/account/addresses`, `/projects`, and `/components`.

## ADR-005 — configuration and secrets

Only public mobile configuration can use Dart defines. A mobile binary is inspectable. No service-role key, FCM server secret, SMS password or database password can be embedded. Connected mode accepts only the explicit `sb_publishable_` key form and HTTPS origins. Backend RLS remains mandatory; a publishable key is not an authorization boundary.

Development preview remains the default example. Staging and production reject preview. Connected mode accepts only HTTPS origins and the explicit `sb_publishable_` key form. Keep actual environment files out of Git; configure all backend access with least privilege and RLS.

## ADR-006 — persistence and diagnostics

`PreferencesStore` is for non-sensitive flags. `SecretStore` namespaces keys and delegates to platform secure storage. Supabase Auth persists its SDK session. The custom secure-storage adapter is not wired into the Supabase client, and no encrypted request drafts are stored. Adding the adapter does not encrypt arbitrary files or the SDK default session store.

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


## Combined Delivery 3 — request-to-quote

The customer request feature is implemented in `lib/features/requests/`. Presentation pages use Riverpod providers, which call `RequestRepository`; repository DTOs own the Supabase row mapping. The delivery covers saved addresses, dynamic service questions, request submission, attachment uploads, preferred scheduling, request history/details, survey/appointment reads, and quote display/decisions.

Customer survey and quote mutations use the narrowly scoped `SECURITY DEFINER` functions in `supabase/sql/request_quote_commands.sql` because customer RLS deliberately denies direct writes to those tables. Apply and review that SQL against the Supabase project before using the connected workflow. The app must never receive a service-role key.

The customer upload flow stores binary data in the private `request-attachments` bucket and only metadata in PostgreSQL. Quote PDFs use the private `quote-documents` bucket; the UI currently presents the quote's structured line items and amounts.

The request row is durable before answers/files are written. The client handles that partial-failure case by navigating to the saved request and discouraging a duplicate submission. A transactional submission RPC plus resumable upload orchestration remains a reliability improvement for a later hardening pass.


## Combined Delivery 4 — fulfilment and catalogue

`CatalogueRepository` owns published product/project reads and maps media object paths to public Storage URLs. Customer-facing product enquiries and similar-project enquiries preserve context by passing a prefilled note through service selection into the existing service request form. The approved schema has no product-inquiry table, so this delivery does not invent one.

`JobsRepository` selects customer-safe fields from `jobs` by `request_id`. RLS must confirm ownership through `service_requests`; customer projections omit staff notes and job assignments. The progress component renders current status and the available schedule/completion timestamps because no job-event history table exists.

## Combined Delivery 5 — customer care and staff operations

`CareRepository` maps the approved notification, support ticket, FAQ, preference, review, role, and request columns into data records. Customer pages are account routes; FAQs are guest-readable. The operations route checks the signed-in user's `user_roles` before showing staff queues and role-specific controls. Backend RLS is the actual authorization boundary. Since the approved core SQL's `staff_manage` policy grants broad staff writes, `supabase/sql/staff_role_policies.sql` supplies role-scoped replacement policies for jobs, support tickets, and reviews.

The current schema has no device-token/outbox table, support conversation table, notification event/entity key, or staff content-management workflow. Consequently this delivery implements an in-app notification inbox and notification preferences, one-message support tickets with status, FAQ reads, and limited operational queues. FCM delivery, ticket replies, full quote/survey management, and catalogue/content CRUD require server/schema additions and are not represented as complete.
