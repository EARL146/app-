-- Apply after 001_initial_schema.sql. This migration adds fields required by
-- customer account preferences, saved carts/reminders, support messages, and admin account controls.
ALTER TABLE users
    ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER role;

ALTER TABLE orders
    MODIFY status ENUM('pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending';

ALTER TABLE order_items
    DROP INDEX uq_order_product,
    ADD COLUMN customizations_json JSON NULL AFTER image_url,
    ADD KEY ix_order_items_order (order_id, id);

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id BIGINT UNSIGNED NOT NULL,
    language VARCHAR(16) NOT NULL DEFAULT 'en',
    theme_mode ENUM('light', 'dark', 'system') NOT NULL DEFAULT 'light',
    theme_palette VARCHAR(40) NOT NULL DEFAULT 'Burger Bites',
    order_updates TINYINT(1) NOT NULL DEFAULT 1,
    digital_receipt TINYINT(1) NOT NULL DEFAULT 1,
    promotional_alerts TINYINT(1) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_preferences_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contact_messages (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL,
    full_name VARCHAR(120) NOT NULL,
    email_or_phone VARCHAR(254) NOT NULL,
    topic VARCHAR(80) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('new', 'in_progress', 'resolved') NOT NULL DEFAULT 'new',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_contact_status_created (status, created_at),
    KEY ix_contact_user_created (user_id, created_at),
    CONSTRAINT fk_contact_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cart_items (
    user_id BIGINT UNSIGNED NOT NULL,
    product_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    configuration_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    customizations_json JSON NOT NULL,
    quantity SMALLINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, product_id, configuration_hash),
    KEY ix_cart_items_product (product_id),
    CONSTRAINT fk_cart_items_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT chk_cart_items_quantity CHECK (quantity BETWEEN 1 AND 99)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_calendar_reminders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    reminder_date DATE NOT NULL,
    title VARCHAR(100) NOT NULL,
    notes VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_calendar_user_date (user_id, reminder_date, id),
    CONSTRAINT fk_calendar_reminders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Public business details managed by an admin; never store provider secrets here.
CREATE TABLE IF NOT EXISTS store_profile (
    id TINYINT UNSIGNED NOT NULL,
    store_name VARCHAR(120) NOT NULL DEFAULT 'BurgerBites',
    support_email VARCHAR(254) NULL,
    support_phone VARCHAR(32) NULL,
    facebook_url VARCHAR(500) NULL,
    street_address VARCHAR(500) NULL,
    opening_hours VARCHAR(160) NULL,
    delivery_coverage VARCHAR(500) NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT chk_store_profile_singleton CHECK (id = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO store_profile (id) VALUES (1);
