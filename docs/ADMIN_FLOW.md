# Admin Flow

[[PROJECT_HOME]] · [[SCREEN_IMPLEMENTATION_STATUS]] · [[SECURITY]] · [[API_SPEC]]

## Preview sign-in and navigation

The sign-in form compares the email and password against the local constants in `lib/constants/demo_admin_account.dart`. A match navigates to `/admin-home`. This is a UI preview shortcut; it does not verify a password on a server or protect admin routes from direct navigation.

From the dashboard, the profile icon opens `/admin-profile`. The **More** screen also has an Admin profile entry. Profile shows the demo account's identity, branch, role, admin ID, access summary, and active label. Editing name, phone, and branch changes widget state for the current page/session only. **Log out** asks for confirmation and replaces the route with sign-in; it is not a server token revocation flow.

## Admin screens

| Screen | Local behavior | Limit |
| --- | --- | --- |
| Dashboard | Shows sample counts, sales/chart preview, and recent orders. | Metrics are not read from a business database. |
| Orders | Search/filter and update sample order status. | No server persistence or audited transitions. |
| Products | Browse/filter/add/edit/delete sample products and toggle availability. | No API, durable storage, or image upload. |
| Customers | List/search sample customers and toggle local active state. | No server authorization or persisted customer data. |
| More | Admin navigation and preview settings. | Not connected to account/security services. |
| Profile | Displays details, local edits, and sign-out navigation. | Demo identity; changes are not persisted. |

## Routes and source

See `lib/navigation/app_routes.dart`, `lib/navigation/app_router.dart`, and `lib/screens/admin/`. State is held by `AdminOrdersProvider`, `AdminProductsProvider`, and `AdminCustomersProvider`. No role-enforcing API was found; see [[SECURITY]] and [[API_SPEC]].
