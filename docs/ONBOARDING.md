# First launch and account location

## Customer flow

Welcome → service introduction → project/request introduction → **Get started** → create account (with a sign-in link for existing users) → Home after authentication.

The three screens use FixPK's existing logo, colors and bundled home/solar/project imagery. They require no image download or location permission. Each screen has a progress indicator; Next, previous-page navigation and horizontal swiping work together. Reduced-motion preferences are respected, content scrolls at large text sizes and the main action remains below the scrollable content.

## Launch decisions

| State when the app opens normally | Initial screen |
|---|---|
| Existing restored session, including users upgrading from an earlier build | Home |
| No session and introduction not completed | Welcome |
| Introduction completed but signup unfinished, email confirmation pending, or user signed out | Sign in |

Get started saves the completion flag before opening signup. The Sign in shortcut also saves it. Successful signup/sign-in records completion as well, including accounts reached through direct routes. Reading the restored session is local; launch does not wait for a new authentication event or backend content request.

The introduction is remembered on that installation. Clearing app data or installing on another device can show it again when there is no restored session. An existing session bypasses the introduction even if its local flag is absent, and records completion without delaying Home, so signing out after an upgrade does not introduce the app again. Explicit deep links and password recovery retain their existing routes.

An email-confirmation requirement is preserved. Creating an account with a pending confirmation does not manufacture an authenticated session or grant access to customer data.

## Country and city

Signup requires both fields. Country defaults to **Pakistan** and remains editable; city accepts typed input such as Islamabad or Rawalpindi. Country is limited to 80 characters and city to 100. Blank/whitespace-only values are rejected and saved values are trimmed.

The values are stored in Supabase Auth's customer-editable `user_metadata.country` and `user_metadata.city`, shown on Account, and editable through Edit profile. They are profile information only, never authorization claims or proof of a serviceable address. The full address and service-area checks remain part of the booking flow. The existing `profiles` table schema and role/RLS rules are unchanged; no SQL migration is required.

Returning users enter their email and password without having to re-enter location. Editing an older profile requires completing the location fields before saving.

## Verification

Widget coverage includes fresh launch, all three pages, returning session without a local flag, unfinished signup, preference read/write failure and retry, previous-page navigation, the existing-user shortcut, recovery-route access and 320-pixel layouts at normal/double text size. Auth tests check required location fields, email-confirmation behavior, successful signup navigation, duplicate-submit prevention and the actual Supabase client signup payload using a mocked HTTP transport.

Native Android integration coverage exercises the real preferences plugin, completes onboarding and recreates the app to confirm that the introduction stays completed. These tests do not send real confirmation emails or create production customer accounts.

The optional `tool/render_onboarding_test.dart` utility renders four phone screenshots into `build/verification` for visual inspection. Run it with the pinned SDK, `FIXPK_FLUTTER_SDK` set, and `flutter test --update-goldens tool/render_onboarding_test.dart`.
