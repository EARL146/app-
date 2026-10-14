<?php
declare(strict_types=1);

namespace BurgerBites\Api;

use PDO;
use Throwable;

final class ApiApplication
{
    public static function run(): never
    {
        ini_set('display_errors', '0');
        ini_set('log_errors', '1');
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('Referrer-Policy: no-referrer');
        header('Cache-Control: no-store');
        try {
            Http::cors();
            $pepper = getenv('APP_TOKEN_PEPPER') ?: '';
            if (strlen($pepper) < 32 || str_starts_with($pepper, 'replace-with-')) {
                throw new ApiException(503, 'The API is not configured yet.');
            }
            $db = Database::connect();
            self::dispatch($db, $pepper, Http::method(), Http::path());
        } catch (ApiException $error) {
            Http::json(['message' => $error->getMessage()], $error->status);
        } catch (\PDOException $error) {
            $eventId = bin2hex(random_bytes(8));
            error_log(json_encode([
                'event' => 'burger_bites_api_database_unavailable',
                'event_id' => $eventId,
            ], JSON_UNESCAPED_SLASHES));
            Http::json(['message' => 'The BurgerBites service is temporarily unavailable. Try again shortly.'], 503);
        } catch (Throwable $error) {
            $eventId = bin2hex(random_bytes(8));
            error_log(json_encode([
                'event' => 'burger_bites_api_error',
                'event_id' => $eventId,
                'type' => get_class($error),
            ], JSON_UNESCAPED_SLASHES));
            Http::json(['message' => 'BurgerBites could not complete the request. Try again.'], 500);
        }
        Http::json(['message' => 'Route not found.'], 404);
    }

    private static function dispatch(PDO $db, string $pepper, string $method, string $path): void
    {
        if ($method === 'POST' && $path === '/auth/register') {
            self::register($db, $pepper, Http::body());
        }
        if ($method === 'POST' && $path === '/auth/login') {
            self::login($db, $pepper, Http::body());
        }
        if ($method === 'POST' && $path === '/auth/refresh') {
            self::refresh($db, $pepper, Http::body());
        }

        if ($method === 'GET' && ($path === '/products' || preg_match('#^/products/[A-Za-z0-9_-]{1,64}$#', $path))) {
            self::products($db, $path);
        }

        $user = self::requireUser($db, $pepper);
        if ($method === 'GET' && $path === '/me') {
            Http::json(['user' => Auth::publicUser($user)]);
        }
        if ($method === 'PUT' && $path === '/me') {
            self::updateProfile($db, $user, Http::body());
        }
        if ($method === 'POST' && $path === '/auth/logout') {
            $delete = $db->prepare('DELETE FROM api_tokens WHERE family_id = ?');
            $delete->execute([$user['_token_family']]);
            Http::json(['success' => true]);
        }
        if ($method === 'GET' && $path === '/me/favorites') {
            self::favorites($db, (string)$user['id']);
        }
        if ($method === 'POST' && $path === '/me/favorites') {
            self::addFavorite($db, (string)$user['id'], Http::body());
        }
        if ($method === 'DELETE' && preg_match('#^/me/favorites/([A-Za-z0-9_-]{1,64})$#', $path, $match)) {
            $delete = $db->prepare('DELETE FROM favorites WHERE user_id = ? AND product_id = ?');
            $delete->execute([$user['id'], $match[1]]);
            Http::json(['success' => true]);
        }
        if ($method === 'POST' && $path === '/orders') {
            self::createOrder($db, $user, Http::body());
        }
        if (str_starts_with($path, '/admin/')) {
            if ($user['role'] !== 'admin') {
                throw new ApiException(403, 'You do not have permission to perform this action.');
            }
            throw new ApiException(501, 'This admin API operation is not available yet.');
        }
        throw new ApiException(404, 'Route not found.');
    }

    private static function register(PDO $db, string $pepper, array $body): never
    {
        $name = trim((string)($body['full_name'] ?? ''));
        $email = strtolower(trim((string)($body['email'] ?? '')));
        $password = $body['password'] ?? null;
        $emailName = explode('@', $email, 2)[0];
        $passwordUsesEmail = strlen($emailName) >= 4 && is_string($password) && stripos($password, $emailName) !== false;
        self::applyAuthLimits($db, $pepper, 'register', $email, 5, 3600, 2, 3600);
        if (mb_strlen($name) < 2 || mb_strlen($name) > 120) {
            throw new ApiException(422, 'Enter a name between 2 and 120 characters.');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 254) {
            throw new ApiException(422, 'Enter a valid email address.');
        }
        $commonPasswords = ['password123!', 'password123456', 'qwerty123456', 'letmein123456', '123456789012', 'welcome123456', 'adminadmin123', 'iloveyou12345', 'changeme12345', 'p@ssword12345'];
        if (!is_string($password) || mb_strlen($password) < 12 || mb_strlen($password) > 200 ||
            $passwordUsesEmail || in_array(strtolower($password), $commonPasswords, true)) {
            throw new ApiException(422, 'Use a password of at least 12 characters that is not based on your email or a common password.');
        }
        if (!defined('PASSWORD_ARGON2ID')) {
            throw new ApiException(503, 'Secure password hashing is unavailable on this server.');
        }
        try {
            $db->beginTransaction();
            $insert = $db->prepare('INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, \'customer\')');
            $insert->execute([$name, $email, password_hash($password, PASSWORD_ARGON2ID)]);
            $id = (string)$db->lastInsertId();
            $user = self::findUser($db, $id);
            $session = Auth::issue($db, $pepper, $user);
            $db->commit();
        } catch (\PDOException $error) {
            if ($db->inTransaction()) $db->rollBack();
            if ($error->getCode() === '23000') {
                throw new ApiException(409, 'We could not create this account. Try signing in or use another email.');
            }
            throw $error;
        }
        Http::json($session, 201);
    }

    private static function login(PDO $db, string $pepper, array $body): never
    {
        $email = strtolower(trim((string)($body['email'] ?? '')));
        $password = $body['password'] ?? null;
        self::applyAuthLimits($db, $pepper, 'login', $email, 30, 900, 10, 900);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || !is_string($password) || strlen($password) > 200) {
            throw new ApiException(401, 'Email or password is incorrect.');
        }
        $query = $db->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $query->execute([$email]);
        $user = $query->fetch();
        if (!$user || !password_verify($password, (string)$user['password_hash'])) {
            throw new ApiException(401, 'Email or password is incorrect.');
        }
        if (password_needs_rehash((string)$user['password_hash'], PASSWORD_ARGON2ID)) {
            $update = $db->prepare('UPDATE users SET password_hash = ? WHERE id = ?');
            $update->execute([password_hash($password, PASSWORD_ARGON2ID), $user['id']]);
        }
        $db->beginTransaction();
        try {
            $session = Auth::issue($db, $pepper, $user);
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json($session);
    }

    private static function refresh(PDO $db, string $pepper, array $body): never
    {
        $token = $body['refresh_token'] ?? null;
        if (!is_string($token) || strlen($token) < 30 || strlen($token) > 200) {
            throw new ApiException(401, 'Your session has expired. Sign in again.');
        }
        $db->beginTransaction();
        try {
            $query = $db->prepare('SELECT t.family_id, t.user_id, t.expires_at, u.* FROM api_tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = ? AND t.token_type = \'refresh\' FOR UPDATE');
            $query->execute([Auth::tokenHash($token, $pepper)]);
            $row = $query->fetch();
            if (!$row || strtotime((string)$row['expires_at'] . ' UTC') <= time()) {
                $db->rollBack();
                throw new ApiException(401, 'Your session has expired. Sign in again.');
            }
            $delete = $db->prepare('DELETE FROM api_tokens WHERE family_id = ?');
            $delete->execute([$row['family_id']]);
            $user = self::findUser($db, (string)$row['user_id']);
            $session = Auth::issue($db, $pepper, $user);
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json($session);
    }

    private static function requireUser(PDO $db, string $pepper): array
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if ($header === '' && function_exists('getallheaders')) {
            foreach (getallheaders() as $name => $value) {
                if (strtolower($name) === 'authorization') $header = $value;
            }
        }
        if (!preg_match('/^Bearer ([A-Za-z0-9_-]{30,200})$/', $header, $match)) {
            throw new ApiException(401, 'Sign in to continue.');
        }
        $query = $db->prepare('SELECT u.*, t.family_id AS _token_family FROM api_tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = ? AND t.token_type = \'access\' AND t.expires_at > UTC_TIMESTAMP() LIMIT 1');
        $query->execute([Auth::tokenHash($match[1], $pepper)]);
        $user = $query->fetch();
        if (!$user) throw new ApiException(401, 'Your session has expired. Sign in again.');
        return $user;
    }

    private static function updateProfile(PDO $db, array $user, array $body): never
    {
        $fields = [];
        $values = [];
        if (array_key_exists('full_name', $body)) {
            $name = trim((string)$body['full_name']);
            if (mb_strlen($name) < 2 || mb_strlen($name) > 120) {
                throw new ApiException(422, 'Enter a name between 2 and 120 characters.');
            }
            $fields[] = 'full_name = ?'; $values[] = $name;
        }
        foreach (['phone' => 32, 'branch_name' => 120, 'default_address' => 500] as $key => $max) {
            if (!array_key_exists($key, $body)) continue;
            $value = trim((string)$body[$key]);
            if (mb_strlen($value) > $max) throw new ApiException(422, 'One of the profile fields is too long.');
            $fields[] = $key . ' = ?'; $values[] = $value === '' ? null : $value;
        }
        if ($fields === []) throw new ApiException(422, 'There are no profile changes to save.');
        $values[] = $user['id'];
        $query = $db->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ?');
        $query->execute($values);
        Http::json(['user' => Auth::publicUser(self::findUser($db, (string)$user['id']))]);
    }

    private static function products(PDO $db, string $path): never
    {
        if (preg_match('#^/products/([A-Za-z0-9_-]{1,64})$#', $path, $match)) {
            $query = $db->prepare('SELECT id, name, description, price, image_url, category, rating, review_count, is_available, created_at FROM products WHERE id = ? LIMIT 1');
            $query->execute([$match[1]]);
            $product = $query->fetch();
            if (!$product) throw new ApiException(404, 'Product not found.');
            Http::json(['product' => self::productJson($product)]);
        }
        $limit = min(50, max(1, (int)($_GET['limit'] ?? 20)));
        $offset = min(10000, max(0, (int)($_GET['offset'] ?? 0)));
        $filters = ['is_available = 1']; $values = [];
        $category = trim((string)($_GET['category'] ?? ''));
        $search = trim((string)($_GET['q'] ?? ''));
        if ($category !== '' && mb_strlen($category) <= 80) { $filters[] = 'category = ?'; $values[] = $category; }
        if ($search !== '' && mb_strlen($search) <= 100) { $filters[] = '(name LIKE ? OR description LIKE ?)'; $values[] = '%' . $search . '%'; $values[] = '%' . $search . '%'; }
        $sort = match ($_GET['sort'] ?? 'recommended') {
            'price_asc' => 'price ASC, id ASC',
            'price_desc' => 'price DESC, id ASC',
            'rating' => 'rating DESC, id ASC',
            default => 'created_at DESC, id ASC',
        };
        $query = $db->prepare('SELECT id, name, description, price, image_url, category, rating, review_count, is_available, created_at FROM products WHERE ' . implode(' AND ', $filters) . ' ORDER BY ' . $sort . ' LIMIT ? OFFSET ?');
        $index = 1;
        foreach ($values as $value) $query->bindValue($index++, $value, PDO::PARAM_STR);
        $query->bindValue($index++, $limit, PDO::PARAM_INT);
        $query->bindValue($index, $offset, PDO::PARAM_INT);
        $query->execute();
        Http::json(['products' => array_map([self::class, 'productJson'], $query->fetchAll()), 'limit' => $limit, 'offset' => $offset]);
    }

    private static function favorites(PDO $db, string $userId): never
    {
        $query = $db->prepare('SELECT p.id, p.name, p.description, p.price, p.image_url, p.category, p.rating, p.review_count, p.is_available, p.created_at FROM favorites f JOIN products p ON p.id = f.product_id WHERE f.user_id = ? ORDER BY f.created_at DESC');
        $query->execute([$userId]);
        Http::json(['favorites' => array_map([self::class, 'productJson'], $query->fetchAll())]);
    }

    private static function addFavorite(PDO $db, string $userId, array $body): never
    {
        $id = $body['product_id'] ?? null;
        if (!is_string($id) || !preg_match('/^[A-Za-z0-9_-]{1,64}$/', $id)) throw new ApiException(422, 'Choose a valid product.');
        $check = $db->prepare('SELECT id FROM products WHERE id = ? LIMIT 1');
        $check->execute([$id]);
        if (!$check->fetchColumn()) throw new ApiException(404, 'Product not found.');
        $insert = $db->prepare('INSERT IGNORE INTO favorites (user_id, product_id) VALUES (?, ?)');
        $insert->execute([$userId, $id]);
        Http::json(['success' => true]);
    }

    private static function createOrder(PDO $db, array $user, array $body): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can place orders.');
        $name = trim((string)($body['customer_name'] ?? ''));
        $address = trim((string)($body['delivery_address'] ?? ''));
        $phone = trim((string)($body['phone'] ?? ''));
        $notes = trim((string)($body['notes'] ?? ''));
        $items = $body['items'] ?? null;
        if (mb_strlen($name) < 2 || mb_strlen($name) > 120 || mb_strlen($address) < 8 || mb_strlen($address) > 500 || mb_strlen($phone) < 7 || mb_strlen($phone) > 32) {
            throw new ApiException(422, 'Check the name, delivery address, and phone number.');
        }
        if (($body['payment_method'] ?? '') !== 'cod') throw new ApiException(422, 'Cash on delivery is the only available payment method.');
        if (!is_array($items) || count($items) < 1 || count($items) > 50) throw new ApiException(422, 'Add between 1 and 50 items to your order.');
        $quantities = [];
        foreach ($items as $item) {
            $id = is_array($item) ? ($item['product_id'] ?? null) : null;
            $quantity = is_array($item) ? filter_var($item['quantity'] ?? null, FILTER_VALIDATE_INT) : false;
            if (!is_string($id) || !preg_match('/^[A-Za-z0-9_-]{1,64}$/', $id) || $quantity === false || $quantity < 1 || $quantity > 99) {
                throw new ApiException(422, 'One of the order items is invalid.');
            }
            $quantities[$id] = ($quantities[$id] ?? 0) + $quantity;
            if ($quantities[$id] > 99) throw new ApiException(422, 'An item quantity cannot exceed 99.');
        }
        ksort($quantities, SORT_STRING);
        if (mb_strlen($notes) > 500) throw new ApiException(422, 'Order notes must be 500 characters or fewer.');

        $taxPercent = filter_var(getenv('ORDER_TAX_PERCENT') ?: '12', FILTER_VALIDATE_FLOAT);
        $deliveryFee = self::moneyCents(getenv('ORDER_DELIVERY_FEE') ?: '25.00');
        if ($taxPercent === false || $taxPercent < 0 || $taxPercent > 100 || $deliveryFee < 0) {
            throw new ApiException(503, 'Order pricing is not configured correctly.');
        }

        $db->beginTransaction();
        try {
            $productQuery = $db->prepare('SELECT id, name, price, image_url, is_available, stock_quantity FROM products WHERE id = ? FOR UPDATE');
            $subtotal = 0;
            $orderLines = [];
            foreach ($quantities as $id => $quantity) {
                $productQuery->execute([$id]);
                $product = $productQuery->fetch();
                if (!$product || !(bool)$product['is_available']) throw new ApiException(409, 'An item in your cart is no longer available.');
                if ((int)$product['stock_quantity'] < $quantity) throw new ApiException(409, 'There is not enough stock for ' . $product['name'] . '.');
                $unitPrice = self::moneyCents((string)$product['price']);
                $subtotal += $unitPrice * $quantity;
                $orderLines[] = ['product' => $product, 'quantity' => $quantity, 'unit_price' => $unitPrice];
            }
            $tax = (int)round($subtotal * $taxPercent / 100);
            $total = $subtotal + $tax + $deliveryFee;
            $insert = $db->prepare('INSERT INTO orders (user_id, customer_name, delivery_address, phone, payment_method, status, notes, subtotal, tax, delivery_fee, total) VALUES (?, ?, ?, ?, \'cod\', \'pending\', ?, ?, ?, ?, ?)');
            $insert->execute([$user['id'], $name, $address, $phone, $notes === '' ? null : $notes, self::decimal($subtotal), self::decimal($tax), self::decimal($deliveryFee), self::decimal($total)]);
            $orderId = (string)$db->lastInsertId();
            $lineInsert = $db->prepare('INSERT INTO order_items (order_id, product_id, product_name, image_url, quantity, unit_price, line_total) VALUES (?, ?, ?, ?, ?, ?, ?)');
            $stockUpdate = $db->prepare('UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ? AND stock_quantity >= ?');
            foreach ($orderLines as $line) {
                $product = $line['product']; $quantity = $line['quantity']; $unit = $line['unit_price'];
                $stockUpdate->execute([$quantity, $product['id'], $quantity]);
                if ($stockUpdate->rowCount() !== 1) throw new ApiException(409, 'Stock changed while placing your order. Please try again.');
                $lineInsert->execute([$orderId, $product['id'], $product['name'], $product['image_url'], $quantity, self::decimal($unit), self::decimal($unit * $quantity)]);
            }
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['order_id' => $orderId, 'status' => 'pending', 'total' => self::decimal($total)], 201);
    }

    private static function findUser(PDO $db, string $id): array
    {
        $query = $db->prepare('SELECT id, role, email, full_name, phone, branch_name, default_address FROM users WHERE id = ? LIMIT 1');
        $query->execute([$id]);
        $user = $query->fetch();
        if (!$user) throw new ApiException(404, 'Account not found.');
        return $user;
    }

    private static function productJson(array $product): array
    {
        return [
            'id' => (string)$product['id'], 'name' => (string)$product['name'],
            'description' => (string)($product['description'] ?? ''),
            'price' => (float)$product['price'], 'image_url' => $product['image_url'],
            'category' => $product['category'], 'rating' => $product['rating'] === null ? null : (float)$product['rating'],
            'review_count' => $product['review_count'] === null ? null : (int)$product['review_count'],
            'available' => (bool)$product['is_available'],
            'created_at' => gmdate('Y-m-d\TH:i:s\Z', strtotime((string)$product['created_at'] . ' UTC')),
        ];
    }

    private static function moneyCents(string $value): int
    {
        if (!preg_match('/^\d{1,8}(?:\.\d{1,2})?$/', $value)) throw new ApiException(503, 'Product pricing is invalid.');
        [$whole, $fraction] = array_pad(explode('.', $value, 2), 2, '');
        return ((int)$whole * 100) + (int)str_pad($fraction, 2, '0');
    }

    private static function decimal(int $cents): string
    {
        return intdiv($cents, 100) . '.' . str_pad((string)($cents % 100), 2, '0', STR_PAD_LEFT);
    }

    private static function applyAuthLimits(PDO $db, string $pepper, string $action, string $email, int $ipLimit, int $seconds, int $identityLimit, int $identitySeconds): void
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        self::consumeRateLimit($db, $pepper, $action, 'ip:' . $ip, $ipLimit, $seconds);
        if ($email !== '') self::consumeRateLimit($db, $pepper, $action, 'identity:' . strtolower($email) . '|' . $ip, $identityLimit, $identitySeconds);
    }

    private static function consumeRateLimit(PDO $db, string $pepper, string $action, string $subject, int $limit, int $seconds): void
    {
        $window = intdiv(time(), $seconds);
        $hash = hash_hmac('sha256', $subject, $pepper);
        $insert = $db->prepare('INSERT INTO auth_rate_limits (action_name, subject_hash, window_id, attempts) VALUES (?, ?, ?, 1) ON DUPLICATE KEY UPDATE attempts = attempts + 1');
        $insert->execute([$action, $hash, $window]);
        $query = $db->prepare('SELECT attempts FROM auth_rate_limits WHERE action_name = ? AND subject_hash = ? AND window_id = ?');
        $query->execute([$action, $hash, $window]);
        if ((int)$query->fetchColumn() > $limit) throw new ApiException(429, 'Too many attempts. Wait a little and try again.');
        if (random_int(1, 100) === 1) {
            $prune = $db->prepare('DELETE FROM auth_rate_limits WHERE action_name = ? AND window_id < ?');
            $prune->execute([$action, $window - 10]);
        }
    }
}
