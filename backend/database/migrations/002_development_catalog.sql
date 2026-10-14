-- Optional development-only catalog matching lib/data/demo_data.dart.
-- Replace these sample products and stock levels before accepting real orders.
INSERT INTO products (id, name, description, price, image_url, category, rating, review_count, stock_quantity, is_available) VALUES
('classic-burger', 'Classic Burger', 'A juicy double patty with cheddar, lettuce, and signature sauce.', 280.00, 'assets/products/smash_burger.jpg', 'Burgers', 4.80, 216, 100, 1),
('smash-burger', 'Smash Burger', 'Thin crispy patties stacked with caramelized onions and pickles.', 260.00, 'assets/products/smash_burger.jpg', 'Burgers', 4.70, 184, 100, 1),
('chicken-wrap', 'Chicken Wrap', 'Grilled chicken, crisp greens, and smoky mayo wrapped to go.', 220.00, 'assets/products/crispy_chicken.jpg', 'Chicken', 4.60, 139, 100, 1),
('loaded-fries', 'Loaded Fries', 'Crispy fries topped with cheese sauce and herb seasoning.', 180.00, 'assets/products/loaded_fries.jpg', 'Sides', 4.50, 201, 100, 1),
('crispy-chicken', 'Crispy Chicken', 'Golden fried chicken with crunchy slaw and honey glaze.', 240.00, 'assets/products/crispy_chicken.jpg', 'Chicken', 4.90, 168, 100, 1),
('mocha-shake', 'Mocha Shake', 'Creamy mocha shake with a hint of espresso and cocoa.', 150.00, 'assets/products/cola.jpg', 'Drinks', 4.40, 112, 100, 1)
ON DUPLICATE KEY UPDATE name = VALUES(name);
