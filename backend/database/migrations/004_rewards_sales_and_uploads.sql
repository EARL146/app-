-- Apply once after 003_app_workflows.sql. Back up Burger_Bites first.
ALTER TABLE users
    ADD COLUMN reward_points DECIMAL(10,1) NOT NULL DEFAULT 0 AFTER default_address,
    ADD COLUMN profile_image MEDIUMBLOB NULL AFTER reward_points,
    ADD COLUMN profile_image_mime VARCHAR(32) NULL AFTER profile_image;

ALTER TABLE products
    ADD COLUMN discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0 AFTER price,
    ADD COLUMN discount_scope VARCHAR(80) NOT NULL DEFAULT 'all' AFTER discount_percent;

ALTER TABLE orders
    ADD COLUMN reward_points_awarded DECIMAL(5,1) NOT NULL DEFAULT 0 AFTER total,
    ADD COLUMN reward_points_redeemed SMALLINT UNSIGNED NOT NULL DEFAULT 0 AFTER reward_points_awarded,
    ADD COLUMN reward_discount DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER reward_points_redeemed,
    ADD COLUMN reward_reversed TINYINT(1) NOT NULL DEFAULT 0 AFTER reward_discount;

CREATE TABLE IF NOT EXISTS reward_transactions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED NULL,
    action_key VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    points_delta DECIMAL(10,1) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_reward_order_action (order_id, action_key),
    KEY ix_reward_user_created (user_id, created_at),
    CONSTRAINT fk_reward_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_reward_transactions_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contact_attachments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    message_id BIGINT UNSIGNED NOT NULL,
    file_name VARCHAR(200) NOT NULL,
    mime_type VARCHAR(32) NOT NULL,
    file_data MEDIUMBLOB NOT NULL,
    byte_size INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_contact_attachments_message (message_id, id),
    CONSTRAINT fk_contact_attachments_message FOREIGN KEY (message_id) REFERENCES contact_messages(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
