# Database Schema

[[PROJECT_HOME]] · [[PROJECT_MAP]] · [[API_SPEC]] · [[SECURITY]]

## Inspection result

No MySQL schema can be documented from this project tree: no SQL dump, migration, PHP connection file, or database config was found under `Burger_bites`. The AMPPS/phpMyAdmin database may be stored or defined elsewhere; it has not been inspected. Do not treat the Dart models below as actual database tables.

## Client-side data models (not database tables)

The following JSON keys are visible in the Flutter model serializers. They are client serialization shapes only; their compatibility with any server/database is unverified.

| Dart type | Client fields/JSON keys |
| --- | --- |
| `Product` in `lib/models/product_model.dart` | `id`, `name`, `description`, `price`, `image_url`, `category`, `rating`, `review_count`, `available`, `created_at`. |
| `OrderItem` in `lib/models/order_model.dart` | `product_id`, `product_name`, `price`, `quantity`, `product_image`. |
| `Order` in `lib/models/order_model.dart` | `id`, `user_id`, `items`, `subtotal`, `tax`, `shipping_cost`, `total`, `status`, `notes`, `delivery_address`, `created_at`, `updated_at`, `delivered_at`. |
| `User` in `lib/models/user_model.dart` | `id`, `email`, `first_name`, `last_name`, `phone_number`, `profile_image`, `created_at`. |

## Local-only state

`DemoData` seeds sample products and customer orders. Cart and admin providers mutate in-memory Dart lists. Closing/restarting the app does not provide durable order/product/customer persistence. Checkout totals are computed on the client and are not authoritative for a real purchase.

## To document the real AMPPS database

Provide or inspect the separate backend directory and a safe schema export (table/column definitions without passwords or customer data). Then record actual tables, column types, primary/foreign keys, indexes, constraints, migrations, and backup procedure. Do not copy database credentials into this vault. See [[NEXT_SESSION]].
