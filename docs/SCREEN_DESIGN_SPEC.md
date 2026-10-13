# BurgerBites Screen Design Spec

> Status: implemented from the supplied screenshot references; not visually verified against an original Figma file.

## Navigation

- [[PROJECT_MAP]]
- [[FILE_REGISTRY]]
- [[SCREEN_IMPLEMENTATION_STATUS]]
- [[README]]

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
| Settings / language / theme | Local preference previews with explicit status where persistence or localization is not implemented. |
| Calendar | Selectable dates and milestone preview, with sample data labeled. |
| Contact / about | Contact options, validated local message form, FAQs, brand story, and clear sample-content labels. |

### Admin

| Screen | Expected content |
| --- | --- |
| Dashboard | Order/revenue/customer/product metrics, sales overview, quick actions, and recent orders. Metrics must be identified as local sample data. |
| Orders | Search and status filters, order summary, valid status choices, and cancellation controls. |
| Products | Search, categories, product images, availability, price, add/edit/delete actions. |
| Add/edit product | Dark editor surface, image path/ID, product fields, category, availability, and save action. |
| Customers / more | Searchable local customer state and supporting admin options, clearly distinguished from live data. |

## Local image assets

- `assets/products/smash_burger.jpg`
- `assets/products/loaded_fries.jpg`
- `assets/products/crispy_chicken.jpg`
- `assets/products/cola.jpg`

`lib/widgets/food_image.dart` resolves bundled image paths and category fallbacks. Network URLs are supported by the widget, but the demo catalog uses local assets.

## Data and interaction limits

- The Flutter archive contains no PHP API controllers, SQL schema, or live database connection.
- Catalog, order history, admin metrics, and account details are sample data held in app state.
- Payment, social login, calendar milestones, profile persistence, message sending, tracking, and global theme/language application are not connected to production services.
- The design uses the screenshot references as a direction; exact Figma spacing, type scale, colors, and transitions remain unverified.

## Related implementation status

See [[SCREEN_IMPLEMENTATION_STATUS]] for the current per-screen implementation and verification state.
