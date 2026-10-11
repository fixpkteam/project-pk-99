# Backend contracts — design only

No endpoint is deployed in Phase 1. Supabase SDK is pinned for later integration but is not initialized.

## Query contracts

| Repository | Read contract | Visibility |
|---|---|---|
| ServiceRepository | published categories/services, current form version, coverage | guest |
| RequestRepository | cursor-paginated own requests and visible events | authenticated owner |
| SurveyRepository | own survey/appointment summaries | authenticated owner |
| QuoteRepository | own published quote revision with items and permitted actions | authenticated owner |
| ProductRepository | published products, specs and media | guest |
| ProjectRepository | published portfolio | guest |
| SupportRepository | own tickets and customer-visible messages | authenticated owner |

Pagination uses stable `(created_at,id)` cursors; catalogue list pages default to 20. DTOs validate unknown enums and missing fields instead of assuming valid backend data. Realtime is an invalidation signal followed by an authorized read.

## Command envelope

Commands carry an idempotency UUID, typed payload and an expected version where relevant. Caller identity comes from the verified JWT, never a client-selected role or owner field. Response includes entity ID, public reference, server timestamp and resulting state. Transport errors map to configuration, network, unauthenticated, forbidden, validation, conflict, rate-limited or unavailable failures. User copy must not display raw provider exceptions.

| Command | Transactional guarantees |
|---|---|
| SubmitRequest | validate form version, answers, owner address, coverage and attachment ownership; create request/answers/event/outbox once |
| RequestSurvey | ensure owner and valid request; record preference without promising availability |
| ConfirmAppointment | staff permission; linked entities share request; reject resource overlap |
| PublishQuote | estimator permission; server totals; immutable published snapshot; replace prior actionable version |
| DecideQuote | owner, current revision and expiry checked under lock; one terminal decision; event/outbox |
| TransitionJob | staff permission and allowed transition; atomic request/job/event consistency |
| SubmitReview | completed job owned by caller; one review per job |
| SendSupportMessage | ticket ownership/role and visibility; idempotent insertion |

Quote PDF generation and push delivery run from durable post-transaction work, not inside the customer mutation transaction. Privileged functions must authenticate and authorize before using service credentials. Published public media differs from private request evidence.

## Admin boundary

Operations, estimators, support and content editors have separate server-enforced permissions. Customer DTOs must exclude internal notes, vendor contacts and moderation reasons. Use explicit safe projections; do not fetch private columns and hide them only in widgets.
