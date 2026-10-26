-- Apply after 006_customer_presence_product_gallery_sales.sql.
-- Preserve timed-sale pricing on each order line so later product edits do not
-- change what the customer paid or what the admin sees in order history.
ALTER TABLE order_items
    ADD COLUMN original_unit_price DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER unit_price,
    ADD COLUMN sale_discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0 AFTER original_unit_price,
    ADD COLUMN sale_discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER sale_discount_percent;

UPDATE order_items
SET original_unit_price = unit_price
WHERE original_unit_price = 0 AND unit_price > 0;
