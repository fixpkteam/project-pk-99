# FixPK combined delivery roadmap

This plan groups the original 14 implementation phases into six larger deliveries. The database tables, storage buckets/policies, admin identity, Flutter foundation, CI workflow, and Supabase client initialization are already in place. Customer access/service discovery, request-to-quote, fulfilment/catalogue, and customer care implementations are complete. The remaining delivery is release quality and production readiness.

## Delivery 1 — Foundation (complete)

**Includes:** Flutter project structure, shared visual components, environment configuration, routing shell, error/loading states, Supabase bootstrap, and CI.

**Acceptance:** Static analysis, tests, and configured builds pass. Native Android/iOS device validation remains a release check.

## Delivery 2 — Customer access and service discovery (complete)

**Combines:** Authentication/profile (original Phase 2) and services/catalogue (original Phase 3).

**Includes:** Guest browsing, sign-in, account creation, password reset, profile editing, service categories, searchable service listing, and service details from Supabase.

**Acceptance:** Guests can browse the catalogue; users can register/sign in and manage basic profile details; catalogue content is loaded from published backend rows; loading, empty, error, and retry states are present.

## Delivery 3 — Request-to-quote workflow (complete)

**Combines:** Service requests, attachments/addresses, site surveys, appointments, and quotations (original Phases 4–6).

**Includes:** Dynamic forms, requirement answers, file uploads, saved addresses, scheduling, request confirmation/history, survey coordination, quote versions and items, and approve/reject/revision actions.

**Acceptance:** Customer screens, request/address repositories, dynamic answers, private uploads, survey/appointment reads, and quote actions are implemented. The user reports that `supabase/sql/request_quote_commands.sql` has been run in Supabase. Live connected verification remains to be performed.

## Delivery 4 — Fulfilment and solution catalogue (implementation complete; live backend verification pending)

**Combines:** Jobs/tracking, products, and projects (original Phases 7–9).

**Includes:** Job assignment and progress timeline, product browsing/specifications/enquiries, project portfolio and similar-project enquiries.

**Acceptance:** Request details show customer-safe job status/schedule/completion; published products, specifications, media and projects load from Supabase; quote/service enquiry context is carried into request notes.

## Delivery 5 — Customer care and operations (implementation complete; backend hardening and live verification pending)

**Combines:** Notifications/support, reviews/account completion, and admin workflows (original Phases 10–12).

**Includes:** In-app notifications, support tickets/FAQ, eligible reviews, account hub/preferences/legal entry, a role-gated staff console for request/job/support/review queues, and a Flutter admin console for user access and allowlisted service/catalogue/CMS CRUD. Quote preparation, support replies, outbound push delivery, and account deletion still require additional backend workflows.

**Acceptance:** Customer care screens and scoped staff operations are implemented. Run `supabase/sql/staff_role_policies.sql` to replace the broad approved `staff_manage` policies on jobs, support tickets, and reviews before relying on role-specific write permissions. Live Supabase behavior remains unverified.

**MVP completion point:** End of Delivery 5.

## Delivery 6 — Quality and production release

**Combines:** Hardening, release candidate, and launch (original Phases 13–14).

**Includes:** Security/RLS/storage review, regression and device testing, production configuration, store signing/submission, monitoring, and launch stabilization.

**Acceptance:** Release builds pass critical journey checks against production services, no known high-severity access issues remain, and crash/operational monitoring is active.

## Current delivery status

Delivery 5 implementation is complete. Delivery 6 release-readiness review is in progress. Static analysis, all 28 Flutter tests, and a release web build have passed. Read-only Auth settings, public service catalogue, and published FAQ checks against the configured development Supabase project returned HTTP 200. Authenticated ownership/staff RLS behavior is not verified yet.

## Dependency path

Foundation → Customer access/catalogue → Request-to-quote → Fulfilment/catalogue → Customer care/admin → Quality/release.

Delivery 6 is active: connected-backend security review, authenticated policy testing, real-device and regression testing, production configuration, signing/store preparation, and operational monitoring.
