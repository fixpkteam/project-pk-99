# FixPK brand artwork — October 2026 refresh

The supplied FixPK brand remains the identity: navy roof/window and FIX, bright blue PK and slash, on white. The replacement wordmark removes the small unreadable tagline and uses a larger crisp master. It was generated with the imagegen tool in reference-edit mode; the Home hero and service atlas were generated using the supplied Home/Services screens as style references.

## Assets and exports

| Asset | Purpose |
|---|---|
| `fixpk-logo.png` | 1774 × 887 wordmark source master; not bundled in Flutter. |
| `fixpk-logo.webp` | Lossless runtime wordmark with the same pixels and dimensions. |
| `fixpk-app-icon.png` | 1024 × 1024 source for Android, iOS and PWA icons. |
| `service-icons-master.png` | 1448 × 1086 atlas; 4 columns × 3 rows; not bundled in Flutter. |
| `../service-icons/*.webp` | Twelve 256 × 256 runtime icons, about 80 KB combined. |
| `../images/engineering-home.webp` | 1400 × 700 Home hero, about 200 KB. |

The platform launch exports are in Android `drawable-nodpi` and the iOS `LaunchImage.imageset`. Android 12+ uses a padded splash icon so the wordmark stays inside the OS mask. Earlier Android uses a centred 208 × 104 dp image. Android launcher masks control the apparent size; app content uses the shared `FixPkLogo` widget. Runtime decode sizes follow physical pixels and are bounded by the source resolution.

## Generation directions

Logo: preserve the provided FixPK identity, exact uppercase FIXPK, navy #092754 roof/window and FIX, azure #2196F3 PK and slash; flat, crisp edges on pure white; no tagline, shadow or glow; tightly framed 2:1 master.

Home hero: photorealistic modern house with rooftop solar at blue hour, house on the right, dark navy sky on the left for widget text; match the approved reference; no text, logos, buttons or UI drawn into the image.

Service atlas: consistent colourful 3D icons on pale blue-white tiles, four columns and three rows. Ordered solar panels, solar geyser, CCTV, HVAC, electricity, maintenance tools, plumbing, aluminium/glass, UPVC, construction, printing, digital services. No text. Export each tile independently for lazy-loaded Flutter widgets.

All text, navigation, filters, cards and actions in the app are Flutter widgets. The reference screenshots are not displayed as app screens.
