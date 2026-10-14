# Screen Implementation Status

[[PROJECT_HOME]] · [[SCREEN_DESIGN_SPEC]] · [[TESTING]] · [[FILE_REGISTRY]]

> Updated: 2026-10-14. “Implemented” refers to Flutter UI/local demo behavior. No screen has been compared with an original Figma frame.

## Contents

- [Customer screens](#customer-screens)
- [Admin screens](#admin-screens)
- [Reference verification](#reference-verification)
- [Verification record](#verification-record)

## Navigation

- [[PROJECT_MAP]]
- [[FILE_REGISTRY]]
- [[SCREEN_DESIGN_SPEC]]
- [[README]]

## Customer screens

| Screen | Status | Current behavior / limitation |
| --- | --- | --- |
| Welcome | Implemented | Prototype landing screen and route links. |
| Sign in | Implemented | Local demo admin credentials open the admin dashboard; other valid entries use demo customer navigation. No authentication service is connected. |
| Registration | Implemented | Local field validation and demo navigation; no account is created on a server. |
| Home | Implemented | Location, promotional hero, categories, sample bestsellers, and sample orders. |
| Menu | Implemented | Category filtering, local product images, add-to-cart actions. |
| Search | Implemented | Search by product/category/description, category filters, and local recent/trending UI. |
| Product details | Implemented | Size, topping, quantity, and local price previews feed the local cart. |
| Cart | Implemented | Quantity changes, removals, local subtotal, tax, delivery fee, and total. |
| Checkout | Implemented | Local form validation and payment selection preview; no payment is collected and no server order is saved. |
| Order confirmation | Implemented | Displays a local reference only. |
| Order history | Implemented | Static sample orders, status preview, local reorder behavior; live tracking is not connected. |
| Profile | Implemented | Sample customer identity, rewards summary, and routes to account pages. |
| Account settings | Implemented | Local switches and fields; preferences are not persisted. |
| Language | Implemented | Search and selection preview; app translations are not applied. |
| Theme | Implemented | Palette/display preview selection; global theme is not changed or persisted. |
| Calendar | Implemented | Date selection and labeled sample milestone content. |
| Contact | Implemented | Local message validation, sample contact options, and FAQ panels; no support message is sent. |
| About | Implemented | Sample brand content and bundled product image. |

## Admin screens

| Screen | Status | Current behavior / limitation |
| --- | --- | --- |
| Dashboard | Implemented | In-memory sample metrics, chart preview, quick actions, and recent sample orders. |
| Orders | Implemented | Local search/status filtering, status changes, and cancellation; not server-backed. |
| Products | Implemented | Local search/category filtering, product image cards, availability toggle, edit, delete, and add. |
| Add/edit product | Implemented | Local product provider state; no image upload or backend persistence. |
| Customers | Implemented | Sample customer state and local status controls. |
| More | Implemented | Local admin summary/settings UI; values are not live business records. |
| Admin profile | Implemented | Demo name, email, phone, branch, role, ID, access list; profile edits are session-only and logout returns to sign-in. |

## Reference verification

- Supplied screenshots are the design references currently available.
- No Figma project, exported frame, or design-token file was found in the archive.
- **Verified Against Figma:** none.
- Visual comparison in a running emulator/device: not performed for this update.

## Verification record

- Flutter: 3.47.6; Dart: 3.13.5.
- `dart format` on modified Dart files: completed.
- `flutter analyze --no-pub`: passed with no issues on 2026-10-14.
- `flutter build web --no-pub`: passed on 2026-10-14. Non-blocking WebAssembly compatibility notices were reported for the secure-storage web plugin; the standard Web build completed.
- Latest user `flutter run -d edge`: failed while writing `app.dill` because C: had about 0.12 GB free; see [[KNOWN_ISSUES]].
- `flutter build apk --debug --no-pub`: did not complete because Gradle could not remove an existing generated assets directory under `build/app/intermediates/assets/debug/mergeDebugAssets`; no new APK was produced.
- Automated tests: not run for this redesign.
