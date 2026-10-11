# Combined Delivery 5 — customer care and operations

**Status:** Flutter implementation complete; server-side role hardening and live Supabase verification pending.

## Delivered

- Account navigation to notifications, support, FAQs, notification preferences, reviews, legal information, and the role-gated staff console.
- In-app notification list with unread/read state, mark-as-read behavior, refresh/retry, and restricted internal deep links.
- Customer support ticket creation and owned ticket history/status.
- Published FAQ reads; persisted push/email/SMS preference flags and language selection.
- Review history and 1–5 star review submission from a completed job, with pending moderation status.
- Staff queues for requests, jobs, support tickets, and pending reviews. Controls are limited by assigned UI role to job status, ticket status, and review moderation.
- The user confirms that the staff role has been added in Supabase. The optional `supabase/sql/staff_role_policies.sql` replaces broad staff write policies on `jobs`, `support_tickets`, and `reviews` with role-scoped policies. Authenticated staff/customer policy behavior still needs a real-session test.
- Care model tests and account navigation test coverage.

## Schema and service limitations

The approved SQL schema has no device-token/outbox or push-delivery function, so notifications display records inserted by trusted server processes; Firebase Cloud Messaging delivery is not configured. It has no support-message table, so a ticket has a submitted message and status but no reply thread. The app can display preferences but cannot claim delivery for push, email, or SMS. The approved FAQ schema has no staff-management policy, and this delivery does not build catalogue/FAQ content CRUD or a separate web admin app. Survey and quote management remain in the customer workflow; the staff dashboard does not provide a complete quote-preparation workstation.

Legal content is explicitly a draft placeholder and needs approved privacy/terms copy before production. The connected development configuration is present. Read-only health checks for Auth settings and public services/categories/FAQ passed; this does not verify customer ownership policies or staff write permissions.

## Validation

Final validation on 11 October 2026: `flutter analyze` passed with no issues, all 28 Flutter tests passed, and `flutter build web --release --dart-define-from-file=config/development.example.json` completed successfully. Android/iOS builds require configured platform SDKs and device testing.

## Next delivery

Combined Delivery 6 covers connected Supabase security review, environment configuration, device/regression testing, production crash monitoring, signing, and release readiness. Before production, review the role policy SQL, replace draft legal text, confirm app links and notification provider design, and exercise customer/staff RLS with real test accounts.
