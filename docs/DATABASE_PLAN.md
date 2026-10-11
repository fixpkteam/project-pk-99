# Migration and integrity plan — no migrations created

Use the approved Part 5 logical schema as the source of truth. This document establishes implementation order and highlights transactional constraints to implement in later phases.

1. Auth-linked profiles, preferences and trusted role records.
2. Service/product categories, services, form versions, questions/options and coverage.
3. Products/projects, media metadata and content records.
4. Addresses and service requests, preserving source/snapshot relationships.
5. Answers, attachments and append-only request events.
6. Surveys, quotes, quote items and decisions.
7. Vendors, technicians, jobs, assignments and appointments. Create deferred cross-table FKs after referenced tables exist.
8. Reviews, support, callbacks, notifications, device tokens, outbox and audit.
9. Storage policies and publication/transaction commands.

Each migration group must include RLS and relevant grants. No interval may expose private tables without policies. Apply schema in isolated development, run backend tests, apply to staging, test from customer/admin JWTs, then promote with a backup and rollback/forward-fix plan.

## Integrity requirements

- A published form version is immutable. A partial unique constraint alone is insufficient: publication must retire the prior current version in one transaction.
- Cross-table service/form/question consistency needs composite FKs or explicit transactional validation plus constrained write access.
- Customers cannot set request status, quote totals, roles, appointment assignment or internal fields.
- Quote decisions lock/check the actionable revision and validity at server time; publication and decision operations must coordinate to prevent races.
- Request numbers come from a server generator, never client counters.
- Published financial fields are immutable; status changes use commands.
- Review requires a completed owned job and a unique job reference.
- Parent ownership must be checked in both RLS USING and WITH CHECK where relevant.
- Index all ownership and policy lookup paths. Avoid recursively querying role policies.
- Private storage metadata and object ownership must match; path naming alone is not authorization.
- Public buckets must contain only publishable assets. Removing a catalogue row does not itself revoke a public URL.
- Retention and anonymization rules require FixPK approval before account-deletion execution is implemented.

Backend test matrix: guest, owner, different customer, each staff role and worker. Test denied reads/writes, mixed-parent IDs, expired quote approvals, duplicate commands and simultaneous transitions. No production data is needed for these tests.
