-- Apply after 005_calendar_reminder_time.sql. Back up Burger_Bites first.
-- Adds customer activity timestamps, up to three gallery images per product,
-- and UTC sale windows so the same discount rules can be used by the API and app.
ALTER TABLE users
    ADD COLUMN last_seen_at DATETIME NULL AFTER updated_at,
    ADD KEY ix_users_role_last_seen (role, last_seen_at);

ALTER TABLE products
    ADD COLUMN image_urls_json JSON NULL AFTER image_url,
    ADD COLUMN discount_starts_at DATETIME NULL AFTER discount_scope,
    ADD COLUMN discount_ends_at DATETIME NULL AFTER discount_starts_at,
    ADD KEY ix_products_discount_window (is_available, discount_ends_at);
