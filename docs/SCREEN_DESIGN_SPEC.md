# BurgerBites Screen Design Spec

[[PROJECT_HOME]] · [[SCREEN_IMPLEMENTATION_STATUS]] · [[FILE_REGISTRY]]

> Status: implemented from the supplied screenshot references; not visually verified against an original Figma file.

## Contents

- [Reference source](#reference-source)
- [Visual language](#visual-language)
- [Screen requirements](#screen-requirements-from-the-screenshots)
- [Local image assets](#local-image-assets)
- [Data and interaction limits](#data-and-interaction-limits)
- [Related implementation status](#related-implementation-status)

## Reference source

The reference is the set of BurgerBites customer and admin screen screenshots supplied in the project conversation on 2026-10-13. No Figma file, design tokens export, or original frame export was found in the project archive. Screens should only be marked **Verified Against Figma** after an actual Figma frame is available and compared.

## Visual language

- Warm cream page background, white surfaces, coral-orange actions, dark brown feature panels, and red wordmark accents.
- Compact mobile-first layout with rounded cards, short section labels, clear price emphasis, and persistent bottom navigation for the primary customer/admin areas.
- Product photography appears in hero panels, product cards, search results, product detail, cart, and order management.
- Use local product imagery for the catalog so the primary UI does not rely on network access.
- Use Roboto and Material icons already bundled by Flutter.

## Screen requirements from the screenshots

### Customer

| Screen | Expected content |
| --- | --- |
| Sign in / registration | BurgerBites branding, email/password fields, primary action, social sign-in affordances, and terms note. Social providers remain visibly demo-only until connected. |
| Home | Delivery location, search/cart access, promotional hero, category shortcuts, bestseller cards, and recent orders. |
| Menu | Search entry, category filters, promotion, product grid, prices, and add-to-cart actions. |
| Search | Search field, category filters, matching items, recent searches, and trending items. |
| Product details | Product image, rating, description, size/topping selectors, quantity, and add-to-cart total. |
| Cart / checkout | Editable quantities, delivery details, payment option selection, itemized fees, total, and demo status. |
| Order history | Active/completed views, status, item summaries, reorder action, and clear tracking limitation. |
| Profile | Customer identity card, rewards preview, account/settings links, calendar, contact, and about. |
| Settings / language / theme | Preferences persist through the API after migration 003; app-wide translations and theme application remain unimplemented. |
| Calendar | Selectable dates and account-owned reminders with create/edit/delete; explain that alerts are not sent. |
| Contact / about | Contact options, validated local message form, FAQs, brand story, and clear sample-content labels. |

### Admin

| Screen | Expected content |
| --- | --- |
| Dashboard | SQL order/revenue/customer/product metrics, seven-day sales overview, quick actions, and recent orders; show loading/error/empty states. |
| Orders | Search and status filters, SQL order summaries, valid server-approved status choices, and cancellation controls. |
| Products | SQL product search/categories, images, availability, price, stock, and add/edit/archive actions. |
| Add/edit product | Dark editor surface, image path/ID, product fields, category, availability, stock, and save action. |
| Customers / more / profile | Searchable SQL customer state and status actions, provider/readiness limits, server-backed profile editing/password change, and logout. Label any preview-only values. |

## Local image assets

- `assets/products/smash_burger.jpg`
- `assets/products/loaded_fries.jpg`
- `assets/products/crispy_chicken.jpg`
- `assets/products/cola.jpg`

`lib/widgets/food_image.dart` resolves bundled image paths and category fallbacks. Network URLs are supported by the widget, but the demo catalog uses local assets.

## Data and interaction limits

- The original Flutter archive contained no PHP API controllers or SQL schema. The API and migrations were added during the 2026-10-14 implementation pass; migration 001 is installed and the public catalog read was smoke-tested. Migration 003 is still awaiting import.
- Customer catalog, favorites, cart, order history, admin metrics/management, profile preferences, support messages, and calendar reminders use SQL-backed API routes in code. The database has no menu products or customer/order records; one development admin account exists. Admin login and role authorization were smoke-tested, while migration 003 workflows still await import and verification.
- Payment, social login, outgoing notifications, tracking, and global theme/language application are not connected to production services. Calendar reminder records do not trigger alerts.
- The design uses the screenshot references as a direction; exact Figma spacing, type scale, colors, and transitions remain unverified.

## Related implementation status

See [[SCREEN_IMPLEMENTATION_STATUS]] for the current per-screen implementation and verification state.
