-- Apply once after migration 007. Back up Burger_Bites before applying.
-- This table records admin payout withdrawals; it does not transfer funds.
CREATE TABLE IF NOT EXISTS store_withdrawals (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    admin_user_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    note VARCHAR(200) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_store_withdrawals_created (created_at, id),
    CONSTRAINT chk_store_withdrawals_positive CHECK (amount > 0),
    CONSTRAINT fk_store_withdrawals_admin FOREIGN KEY (admin_user_id)
        REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
