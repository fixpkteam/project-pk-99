# Implemented design foundation

Source: supplied FixPK fourteen-screen preview. This document records implementation details; the original PRD/design brief still controls future feature scope.

## Tokens

| Token | Value |
|---|---|
| Brand accent | #0088F5 |
| Accessible action | #006BC7 |
| Navy | #00263E |
| Primary text | #101828 |
| Supporting text | #475467 |
| Muted text | #667085 |
| Background | #FFFFFF |
| Subtle surface | #F3F5F8 |
| Border | #D0D5DD |

Semantic status pairs are defined centrally in `FixPkColors`. A textual status accompanies each colour. Values are visually approximated from the source and await brand-master verification. Bright accent blue is not used behind small white button labels; the darker action token is used.

Spacing: 4, 8, 12, 16, 20, 24, 32, 40. Cards/buttons use 12-radius corners, inputs 10, hero 16. Standard page gutters are 16. Scrollable content is capped at 720 logical pixels for comfortable large-screen reading.

Typography: display 28/34 bold; page title 22/28 bold; section title 18/24 semibold; card title 16/22 semibold; body 14/21; caption 12/18; button 15/20 semibold. System sans-serif remains until the approved font is available.

## Components and coverage

| Requirement | Implementation |
|---|---|
| Primary/secondary/outline/text button | `AppButton` with four variants, busy and disabled states |
| Service card | `ServiceCard` |
| Request/quote card | `SummaryCard`, composed with meaningful status |
| Product/project card | `MediaCard` with injectable media and action |
| Status chip | `StatusChip` with semantic tones |
| Input/dropdown | themed Material form controls and validated gallery example |
| Search | `AppSearchField`, clear action and working local filter |
| Upload | `UploadControl`, sample selection/removal; actual files are Phase 4 |
| Date | themed Material date picker in gallery |
| Bottom navigation/app bar | `AppShell` and Material components |
| Dialog/sheet/snackbar | confirmation helper, safe-area sheet and feedback helper |
| Skeleton/empty/error | `SkeletonCard`, `AppStatePanel` |

Native Material controls are reused rather than wrapped without added behaviour. Feature-specific types will compose the generic cards when real models arrive.

## Accessibility and responsive behaviour

- Minimum 48 logical-pixel button and icon actions.
- Cards allow multiline titles and descriptions.
- Scrolling handles small phones, keyboard insets and large text.
- Text scaling is not disabled globally.
- Icon-only actions have tooltips; decorative icons are excluded from semantics.
- Status and errors use text as well as colour; error panels are live regions.
- Loading skeleton is static; no compulsory animated shimmer.
- Standard safe areas respect system UI.
- Gallery samples are labelled, including simulated upload and placeholder images.

Manual physical-device screen-reader and keyboard checks remain part of later native validation; widget checks cannot prove all platform accessibility behaviour.
