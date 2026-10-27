<?php
declare(strict_types=1);

namespace BurgerBites\Api;

use PDO;
use Throwable;

final class ApiApplication
{
    private static array $columnCache = [];

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
        if ($method === 'GET' && $path === '/store-profile') {
            Http::json(['store_profile' => self::readStoreProfile($db)]);
        }
        if ($method === 'POST' && $path === '/contact') {
            self::createContactMessage($db, $pepper, Http::body());
        }

        $user = self::requireUser($db, $pepper);
        if ($method === 'POST' && $path === '/me/activity') {
            $body = Http::body();
            $offline = $body['offline'] ?? false;
            if (!is_bool($offline)) throw new ApiException(422, 'Activity state must be true or false.');
            if (self::hasColumn($db, 'users', 'last_seen_at')) {
                $timestamp = $offline
                    ? 'UTC_TIMESTAMP() - INTERVAL 121 SECOND'
                    : 'UTC_TIMESTAMP()';
                $activity = $db->prepare('UPDATE users SET last_seen_at = ' . $timestamp . ' WHERE id = ?');
                $activity->execute([$user['id']]);
            }
            Http::json(['success' => true, 'tracking_available' => self::hasColumn($db, 'users', 'last_seen_at')]);
        }
        if ($method === 'GET' && $path === '/me') {
            Http::json(['user' => Auth::publicUser($user)]);
        }
        if ($method === 'PUT' && $path === '/me') {
            self::updateProfile($db, $user, Http::body());
        }
        if ($method === 'PUT' && $path === '/me/profile-image') {
            self::saveProfileImage($db, $user, Http::body());
        }
        if ($method === 'DELETE' && $path === '/me/profile-image') {
            $clear = $db->prepare('UPDATE users SET profile_image = NULL, profile_image_mime = NULL WHERE id = ?');
            $clear->execute([$user['id']]);
            Http::json(['success' => true]);
        }
        if ($method === 'PUT' && $path === '/me/password') {
            self::changePassword($db, $pepper, $user, Http::body());
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
        if ($method === 'GET' && $path === '/me/cart') self::cart($db, $user);
        if ($method === 'PUT' && $path === '/me/cart') self::updateCart($db, $user, Http::body());
        if ($method === 'DELETE' && $path === '/me/cart') self::clearCart($db, $user);
        if ($method === 'POST' && $path === '/orders') {
            self::createOrder($db, $user, Http::body());
        }
        if ($method === 'GET' && $path === '/me/orders') {
            self::orders($db, (string)$user['id']);
        }
        if ($method === 'PUT' && preg_match('#^/me/orders/(\d+)/cancel$#', $path, $match)) {
            self::cancelCustomerOrder($db, (string)$user['id'], $match[1]);
        }
        if ($method === 'GET' && $path === '/me/preferences') {
            self::preferences($db, (string)$user['id']);
        }
        if ($method === 'PUT' && $path === '/me/preferences') {
            self::updatePreferences($db, (string)$user['id'], Http::body());
        }
        if ($method === 'GET' && $path === '/me/calendar-reminders') self::calendarReminders($db, $user);
        if ($method === 'POST' && $path === '/me/calendar-reminders') self::createCalendarReminder($db, $user, Http::body());
        if ($method === 'PUT' && preg_match('#^/me/calendar-reminders/(\d+)$#', $path, $match)) {
            self::updateCalendarReminder($db, $user, $match[1], Http::body());
        }
        if ($method === 'DELETE' && preg_match('#^/me/calendar-reminders/(\d+)$#', $path, $match)) {
            self::deleteCalendarReminder($db, $user, $match[1]);
        }
        if (str_starts_with($path, '/admin/')) {
            if ($user['role'] !== 'admin') {
                throw new ApiException(403, 'You do not have permission to perform this action.');
            }
            if ($method === 'GET' && $path === '/admin/system-status') self::adminSystemStatus($db);
            if ($method === 'GET' && $path === '/admin/store-profile') {
                Http::json(['store_profile' => self::readStoreProfile($db)]);
            }
            if ($method === 'PUT' && $path === '/admin/store-profile') {
                self::updateStoreProfile($db, Http::body());
            }
            if ($method === 'GET' && $path === '/admin/payment-summary') {
                self::adminPaymentSummary($db);
            }
            if ($method === 'POST' && $path === '/admin/withdrawals') {
                self::createAdminWithdrawal($db, $user, Http::body());
            }
            if ($method === 'GET' && $path === '/admin/dashboard') self::adminDashboard($db);
            if ($method === 'GET' && $path === '/admin/orders') self::orders($db, null);
            if ($method === 'PUT' && preg_match('#^/admin/orders/(\d+)$#', $path, $match)) {
                self::updateOrderStatus($db, $match[1], Http::body());
            }
            if ($method === 'GET' && $path === '/admin/products') self::adminProducts($db);
            if ($method === 'POST' && $path === '/admin/products') self::createProduct($db, Http::body());
            if ($method === 'PUT' && preg_match('#^/admin/products/([A-Za-z0-9_-]{1,64})$#', $path, $match)) {
                self::updateProduct($db, $match[1], Http::body());
            }
            if ($method === 'DELETE' && preg_match('#^/admin/products/([A-Za-z0-9_-]{1,64})$#', $path, $match)) {
                self::archiveProduct($db, $match[1]);
            }
            if ($method === 'GET' && $path === '/admin/customers') self::adminCustomers($db);
            if ($method === 'GET' && preg_match('#^/admin/customers/(\d+)/photo$#', $path, $match)) {
                self::adminCustomerPhoto($db, $match[1]);
            }
            if ($method === 'PUT' && preg_match('#^/admin/customers/(\d+)$#', $path, $match)) {
                self::updateCustomerStatus($db, $match[1], Http::body());
            }
            if ($method === 'GET' && $path === '/admin/contact-messages') self::adminContactMessages($db);
            if ($method === 'GET' && preg_match('#^/admin/contact-messages/(\d+)/attachments$#', $path, $match)) {
                self::adminContactAttachments($db, $match[1]);
            }
            if ($method === 'PUT' && preg_match('#^/admin/contact-messages/(\d+)$#', $path, $match)) {
                self::updateContactMessageStatus($db, $match[1], Http::body());
            }
        }
        throw new ApiException(404, 'Route not found.');
    }

    private static function register(PDO $db, string $pepper, array $body): never
    {
        $rawName = $body['full_name'] ?? null;
        $rawEmail = $body['email'] ?? null;
        $name = is_string($rawName) ? trim($rawName) : '';
        $email = is_string($rawEmail) ? strtolower(trim($rawEmail)) : '';
        $password = $body['password'] ?? null;
        $emailName = explode('@', $email, 2)[0];
        $passwordUsesEmail = strlen($emailName) >= 4 && is_string($password) && stripos($password, $emailName) !== false;
        self::applyAuthLimits($db, $pepper, 'register', $email, 5, 3600, 2, 3600);
        if (!is_string($rawName) || mb_strlen($name) < 2 || mb_strlen($name) > 120) {
            throw new ApiException(422, 'Enter a name between 2 and 120 characters.');
        }
        if (!is_string($rawEmail) || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 254) {
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
        $rawEmail = $body['email'] ?? null;
        $email = is_string($rawEmail) ? strtolower(trim($rawEmail)) : '';
        $password = $body['password'] ?? null;
        self::applyAuthLimits($db, $pepper, 'login', $email, 30, 900, 10, 900);
        if (!is_string($rawEmail) || !filter_var($email, FILTER_VALIDATE_EMAIL) ||
            !is_string($password) || strlen($password) > 200) {
            throw new ApiException(401, 'Email or password is incorrect.');
        }
        $query = $db->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $query->execute([$email]);
        $user = $query->fetch();
        if (!$user || !password_verify($password, (string)$user['password_hash'])) {
            throw new ApiException(401, 'Email or password is incorrect.');
        }
        if (array_key_exists('is_active', $user) && !(bool)$user['is_active']) {
            throw new ApiException(401, 'This account is inactive. Contact BurgerBites support.');
        }
        if (defined('PASSWORD_ARGON2ID') &&
            password_needs_rehash((string)$user['password_hash'], PASSWORD_ARGON2ID)) {
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
            if (array_key_exists('is_active', $row) && !(bool)$row['is_active']) {
                $db->rollBack();
                throw new ApiException(401, 'This account is inactive. Contact BurgerBites support.');
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
        if (array_key_exists('is_active', $user) && !(bool)$user['is_active']) {
            throw new ApiException(401, 'This account is inactive. Contact BurgerBites support.');
        }
        return $user;
    }

    private static function updateProfile(PDO $db, array $user, array $body): never
    {
        $fields = [];
        $values = [];
        if (array_key_exists('full_name', $body)) {
            $rawName = $body['full_name'];
            if (!is_string($rawName)) {
                throw new ApiException(422, 'Enter a name between 2 and 120 characters.');
            }
            $name = trim($rawName);
            if (mb_strlen($name) < 2 || mb_strlen($name) > 120) {
                throw new ApiException(422, 'Enter a name between 2 and 120 characters.');
            }
            $fields[] = 'full_name = ?'; $values[] = $name;
        }
        if (array_key_exists('email', $body)) {
            if (!is_string($body['email'])) throw new ApiException(422, 'Enter a valid email address.');
            $email = strtolower(trim($body['email']));
            if (strlen($email) > 254 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                throw new ApiException(422, 'Enter a valid email address.');
            }
            $exists = $db->prepare('SELECT 1 FROM users WHERE email = ? AND id <> ? LIMIT 1');
            $exists->execute([$email, $user['id']]);
            if ($exists->fetchColumn()) throw new ApiException(409, 'That email is already in use.');
            $fields[] = 'email = ?'; $values[] = $email;
        }
        foreach (['phone' => 32, 'branch_name' => 120, 'default_address' => 500] as $key => $max) {
            if (!array_key_exists($key, $body)) continue;
            if (!is_string($body[$key])) {
                throw new ApiException(422, 'Profile fields must be text.');
            }
            $value = trim($body[$key]);
            if (mb_strlen($value) > $max) throw new ApiException(422, 'One of the profile fields is too long.');
            $fields[] = $key . ' = ?'; $values[] = $value === '' ? null : $value;
        }
        if ($fields === []) throw new ApiException(422, 'There are no profile changes to save.');
        $values[] = $user['id'];
        $query = $db->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ?');
        try {
            $query->execute($values);
        } catch (\PDOException $error) {
            if (array_key_exists('email', $body) && (string)$error->getCode() === '23000') {
                throw new ApiException(409, 'That email is already in use.');
            }
            throw $error;
        }
        Http::json(['user' => Auth::publicUser(self::findUser($db, (string)$user['id']))]);
    }

    private static function saveProfileImage(PDO $db, array $user, array $body): never
    {
        $encoded = $body['image_base64'] ?? null;
        if (!is_string($encoded) || strlen($encoded) > 700000) {
            throw new ApiException(422, 'Choose an image no larger than 512 KB.');
        }
        $bytes = base64_decode($encoded, true);
        if ($bytes === false || strlen($bytes) > 512 * 1024) {
            throw new ApiException(422, 'Choose an image no larger than 512 KB.');
        }
        $info = @getimagesizefromstring($bytes);
        $mime = is_array($info) ? (string)($info['mime'] ?? '') : '';
        if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], true)) {
            throw new ApiException(422, 'Use a JPEG, PNG, WebP, or GIF image.');
        }
        $save = $db->prepare('UPDATE users SET profile_image = ?, profile_image_mime = ? WHERE id = ?');
        $save->execute([$bytes, $mime, $user['id']]);
        Http::json(['user' => Auth::publicUser(self::findUser($db, (string)$user['id']))]);
    }

    private static function changePassword(PDO $db, string $pepper, array $user, array $body): never
    {
        self::applyAuthLimits($db, $pepper, 'password', (string)$user['email'], 10, 900, 5, 900);
        $current = $body['current_password'] ?? null;
        $next = $body['new_password'] ?? null;
        if (!is_string($current) || !is_string($next) || strlen($current) > 200 || mb_strlen($next) < 12 || mb_strlen($next) > 200) {
            throw new ApiException(422, 'Enter your current password and a new password of at least 12 characters.');
        }
        $query = $db->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
        $query->execute([$user['id']]);
        $hash = $query->fetchColumn();
        if (!is_string($hash) || !password_verify($current, $hash)) throw new ApiException(422, 'Your current password is incorrect.');
        $emailName = explode('@', (string)$user['email'], 2)[0];
        $commonPasswords = ['password123!', 'password123456', 'qwerty123456', 'letmein123456', '123456789012', 'welcome123456', 'adminadmin123', 'iloveyou12345', 'changeme12345', 'p@ssword12345'];
        if ((strlen($emailName) >= 4 && stripos($next, $emailName) !== false) || in_array(strtolower($next), $commonPasswords, true)) {
            throw new ApiException(422, 'Choose a password that is not based on your email or a common password.');
        }
        if (!defined('PASSWORD_ARGON2ID')) throw new ApiException(503, 'Secure password hashing is unavailable on this server.');
        $db->beginTransaction();
        try {
            $update = $db->prepare('UPDATE users SET password_hash = ? WHERE id = ?');
            $update->execute([password_hash($next, PASSWORD_ARGON2ID), $user['id']]);
            $revokeOtherSessions = $db->prepare('DELETE FROM api_tokens WHERE user_id = ? AND family_id <> ?');
            $revokeOtherSessions->execute([$user['id'], $user['_token_family']]);
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['success' => true]);
    }

    private static function products(PDO $db, string $path): never
    {
        if (preg_match('#^/products/([A-Za-z0-9_-]{1,64})$#', $path, $match)) {
            $query = $db->prepare('SELECT ' . self::productFields($db, '', true) . ' FROM products WHERE id = ? LIMIT 1');
            $query->execute([$match[1]]);
            $product = $query->fetch();
            if (!$product) throw new ApiException(404, 'Product not found.');
            Http::json(['product' => self::productJson($product)]);
        }
        $limit = min(50, max(1, (int)($_GET['limit'] ?? 20)));
        $offset = min(10000, max(0, (int)($_GET['offset'] ?? 0)));
        $filters = ['is_available = 1', 'stock_quantity > 0']; $values = [];
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
        $query = $db->prepare('SELECT ' . self::productFields($db) . ' FROM products WHERE ' . implode(' AND ', $filters) . ' ORDER BY ' . $sort . ' LIMIT ? OFFSET ?');
        $index = 1;
        foreach ($values as $value) $query->bindValue($index++, $value, PDO::PARAM_STR);
        $query->bindValue($index++, $limit, PDO::PARAM_INT);
        $query->bindValue($index, $offset, PDO::PARAM_INT);
        $query->execute();
        Http::json(['products' => array_map([self::class, 'productJson'], $query->fetchAll()), 'limit' => $limit, 'offset' => $offset]);
    }

    private static function favorites(PDO $db, string $userId): never
    {
        $query = $db->prepare('SELECT ' . self::productFields($db, 'p', true) . ' FROM favorites f JOIN products p ON p.id = f.product_id WHERE f.user_id = ? ORDER BY f.created_at DESC');
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

    private static function cart(PDO $db, array $user): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use a shopping cart.');
        $query = $db->prepare(
            'SELECT ci.product_id, ci.quantity, ci.customizations_json,
                    p.name, p.price, p.discount_percent, p.discount_scope, p.image_url, p.category, ' . self::discountFields($db, 'p') . '
             FROM cart_items ci
             INNER JOIN products p ON p.id = ci.product_id
             WHERE ci.user_id = ?
             ORDER BY ci.created_at, p.name'
        );
        $query->execute([$user['id']]);
        $items = [];
        foreach ($query->fetchAll() as $row) {
            $customizations = self::normalizeCustomizations(
                json_decode((string)$row['customizations_json'], true, 16, JSON_THROW_ON_ERROR)
            );
            $items[] = [
                'product_id' => (string)$row['product_id'],
                'product_name' => self::customizedProductName((string)$row['name'], (string)$row['category'], $customizations),
                'price' => self::productUnitPrice($row, $customizations) / 100,
                'quantity' => (int)$row['quantity'],
                'product_image' => $row['image_url'],
                'customizations' => $customizations,
            ];
        }
        Http::json(['items' => $items]);
    }

    private static function updateCart(PDO $db, array $user, array $body): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use a shopping cart.');
        $items = $body['items'] ?? null;
        $redeemRewards = $body['redeem_rewards'] ?? false;
        if (!is_bool($redeemRewards)) throw new ApiException(422, 'Choose a valid rewards option.');
        if (!is_array($items) || !array_is_list($items) || count($items) > 50) {
            throw new ApiException(422, 'A cart can contain up to 50 item configurations.');
        }

        $normalized = [];
        foreach ($items as $item) {
            $id = is_array($item) ? ($item['product_id'] ?? null) : null;
            $quantity = is_array($item) ? filter_var($item['quantity'] ?? null, FILTER_VALIDATE_INT) : false;
            if (!is_string($id) || !preg_match('/^[A-Za-z0-9_-]{1,64}$/', $id) || $quantity === false || $quantity < 1 || $quantity > 99) {
                throw new ApiException(422, 'One of the cart items is invalid.');
            }
            if (array_key_exists('customizations', $item) && !is_array($item['customizations'])) {
                throw new ApiException(422, 'One of the product customizations is invalid.');
            }
            $customizations = self::normalizeCustomizations($item['customizations'] ?? []);
            $configurationJson = json_encode($customizations, JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
            $hash = hash('sha256', $configurationJson);
            $key = $id . ':' . $hash;
            if (!isset($normalized[$key])) {
                $normalized[$key] = [
                    'product_id' => $id,
                    'configuration_hash' => $hash,
                    'configuration_json' => $configurationJson,
                    'customizations' => $customizations,
                    'quantity' => 0,
                ];
            }
            $normalized[$key]['quantity'] += $quantity;
            if ($normalized[$key]['quantity'] > 99) throw new ApiException(422, 'An item quantity cannot exceed 99.');
        }
        ksort($normalized, SORT_STRING);

        $db->beginTransaction();
        try {
            $productQuery = $db->prepare('SELECT name, category, is_available, stock_quantity FROM products WHERE id = ? FOR UPDATE');
            foreach ($normalized as $item) {
                $productQuery->execute([$item['product_id']]);
                $product = $productQuery->fetch();
                if (!$product || !(bool)$product['is_available'] || (int)$product['stock_quantity'] < 1) {
                    throw new ApiException(409, 'An item in your cart is no longer available.');
                }
                self::validateProductCustomizations((string)$product['name'], (string)$product['category'], $item['customizations']);
            }

            $delete = $db->prepare('DELETE FROM cart_items WHERE user_id = ?');
            $delete->execute([$user['id']]);
            $insert = $db->prepare(
                'INSERT INTO cart_items (user_id, product_id, configuration_hash, customizations_json, quantity)
                 VALUES (?, ?, ?, ?, ?)'
            );
            foreach ($normalized as $item) {
                $insert->execute([
                    $user['id'],
                    $item['product_id'],
                    $item['configuration_hash'],
                    $item['configuration_json'],
                    $item['quantity'],
                ]);
            }
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['success' => true, 'item_count' => count($normalized)]);
    }

    private static function clearCart(PDO $db, array $user): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use a shopping cart.');
        $delete = $db->prepare('DELETE FROM cart_items WHERE user_id = ?');
        $delete->execute([$user['id']]);
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
            if (array_key_exists('customizations', $item) && !is_array($item['customizations'])) {
                throw new ApiException(422, 'One of the product customizations is invalid.');
            }
            $configuration = self::normalizeCustomizations($item['customizations'] ?? []);
            $key = $id . ':' . hash('sha256', json_encode($configuration, JSON_UNESCAPED_SLASHES));
            if (!isset($quantities[$key])) $quantities[$key] = ['product_id' => $id, 'quantity' => 0, 'customizations' => $configuration];
            $quantities[$key]['quantity'] += $quantity;
            if ($quantities[$key]['quantity'] > 99) throw new ApiException(422, 'An item quantity cannot exceed 99.');
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
            $balanceQuery = $db->prepare('SELECT reward_points FROM users WHERE id = ? FOR UPDATE');
            $balanceQuery->execute([$user['id']]);
            $startingPoints = (float)$balanceQuery->fetchColumn();
            if ($redeemRewards && $startingPoints < 2500) {
                throw new ApiException(409, 'You need at least 2,500 points to redeem this reward.');
            }
            $pointsRedeemed = $redeemRewards ? 2500 : 0;
            $rewardUnitsRemaining = $redeemRewards ? 5 : 0;
            $rewardDiscount = 0;
            $productQuery = $db->prepare('SELECT id, name, price, discount_percent, discount_scope, image_url, category, is_available, stock_quantity, ' . self::discountFields($db) . ' FROM products WHERE id = ? FOR UPDATE');
            $subtotal = 0;
            $totalOrderedUnits = 0;
            $orderLines = [];
            $remainingStock = [];
            foreach ($quantities as $requested) {
                $id = $requested['product_id'];
                $quantity = $requested['quantity'];
                $totalOrderedUnits += $quantity;
                $customizations = $requested['customizations'];
                $productQuery->execute([$id]);
                $product = $productQuery->fetch();
                if (!$product || !(bool)$product['is_available']) throw new ApiException(409, 'An item in your cart is no longer available.');
                $remainingStock[$id] ??= (int)$product['stock_quantity'];
                if ($remainingStock[$id] < $quantity) throw new ApiException(409, 'There is not enough stock for ' . $product['name'] . '.');
                $remainingStock[$id] -= $quantity;
                self::validateProductCustomizations((string)$product['name'], (string)$product['category'], $customizations);
                $pricing = self::productPriceBreakdown($product, $customizations);
                $unitPrice = $pricing['unit_price'];
                $customName = self::customizedProductName((string)$product['name'], (string)$product['category'], $customizations);
                $rewardQuantity = min($quantity, $rewardUnitsRemaining);
                $rewardUnitsRemaining -= $rewardQuantity;
                $regularQuantity = $quantity - $rewardQuantity;
                if ($rewardQuantity > 0) {
                    $rewardUnitPrice = (int)round($unitPrice * 0.2);
                    $subtotal += $rewardUnitPrice * $rewardQuantity;
                    $rewardDiscount += ($unitPrice - $rewardUnitPrice) * $rewardQuantity;
                    $orderLines[] = [
                        'product' => $product, 'quantity' => $rewardQuantity, 'unit_price' => $rewardUnitPrice,
                        'product_name' => $customName . ' · 80% reward',
                        'original_unit_price' => $pricing['original_unit_price'],
                        'sale_discount_percent' => $pricing['sale_discount_percent'],
                        'sale_discount_amount' => $pricing['sale_discount_amount'] * $rewardQuantity,
                        'customizations' => $customizations,
                    ];
                }
                if ($regularQuantity > 0) {
                    $subtotal += $unitPrice * $regularQuantity;
                    $orderLines[] = [
                        'product' => $product, 'quantity' => $regularQuantity, 'unit_price' => $unitPrice,
                        'product_name' => $customName,
                        'original_unit_price' => $pricing['original_unit_price'],
                        'sale_discount_percent' => $pricing['sale_discount_percent'],
                        'sale_discount_amount' => $pricing['sale_discount_amount'] * $regularQuantity,
                        'customizations' => $customizations,
                    ];
                }
            }
            $pointsAwarded = round($totalOrderedUnits * 0.5, 1);
            $tax = (int)round($subtotal * $taxPercent / 100);
            $total = $subtotal + $tax + $deliveryFee;
            $insert = $db->prepare('INSERT INTO orders (user_id, customer_name, delivery_address, phone, payment_method, status, notes, subtotal, tax, delivery_fee, total, reward_points_awarded, reward_points_redeemed, reward_discount) VALUES (?, ?, ?, ?, \'cod\', \'pending\', ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$user['id'], $name, $address, $phone, $notes === '' ? null : $notes, self::decimal($subtotal), self::decimal($tax), self::decimal($deliveryFee), self::decimal($total), $pointsAwarded, $pointsRedeemed, self::decimal($rewardDiscount)]);
            $orderId = (string)$db->lastInsertId();
            $hasSaleSnapshot = self::hasColumn($db, 'order_items', 'original_unit_price')
                && self::hasColumn($db, 'order_items', 'sale_discount_percent')
                && self::hasColumn($db, 'order_items', 'sale_discount_amount');
            $lineInsert = $db->prepare($hasSaleSnapshot
                ? 'INSERT INTO order_items (order_id, product_id, product_name, image_url, customizations_json, quantity, unit_price, original_unit_price, sale_discount_percent, sale_discount_amount, line_total) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                : 'INSERT INTO order_items (order_id, product_id, product_name, image_url, customizations_json, quantity, unit_price, line_total) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
            $stockUpdate = $db->prepare('UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ? AND stock_quantity >= ?');
            foreach ($orderLines as $line) {
                $product = $line['product']; $quantity = $line['quantity']; $unit = $line['unit_price'];
                $stockUpdate->execute([$quantity, $product['id'], $quantity]);
                if ($stockUpdate->rowCount() !== 1) throw new ApiException(409, 'Stock changed while placing your order. Please try again.');
                $customizationsJson = $line['customizations'] === null ? null : json_encode($line['customizations'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
                $lineValues = [$orderId, $product['id'], $line['product_name'], $product['image_url'], $customizationsJson, $quantity, self::decimal($unit)];
                if ($hasSaleSnapshot) {
                    $lineValues[] = self::decimal($line['original_unit_price']);
                    $lineValues[] = number_format($line['sale_discount_percent'], 2, '.', '');
                    $lineValues[] = self::decimal($line['sale_discount_amount']);
                }
                $lineValues[] = self::decimal($unit * $quantity);
                $lineInsert->execute($lineValues);
            }
            $pointsUpdate = $db->prepare('UPDATE users SET reward_points = reward_points - ? + ? WHERE id = ?');
            $pointsUpdate->execute([$pointsRedeemed, $pointsAwarded, $user['id']]);
            $earn = $db->prepare('INSERT INTO reward_transactions (user_id, order_id, action_key, points_delta) VALUES (?, ?, \'order_earn\', ?)');
            $earn->execute([$user['id'], $orderId, $pointsAwarded]);
            if ($pointsRedeemed > 0) {
                $redeem = $db->prepare('INSERT INTO reward_transactions (user_id, order_id, action_key, points_delta) VALUES (?, ?, \'order_redeem\', -2500)');
                $redeem->execute([$user['id'], $orderId]);
            }
            $clearCart = $db->prepare('DELETE FROM cart_items WHERE user_id = ?');
            $clearCart->execute([$user['id']]);
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json([
            'order_id' => $orderId,
            'status' => 'pending',
            'total' => self::decimal($total),
            'reward_points_awarded' => $pointsAwarded,
            'reward_points_redeemed' => $pointsRedeemed,
            'reward_discount' => self::decimal($rewardDiscount),
            'reward_points_balance' => $startingPoints - $pointsRedeemed + $pointsAwarded,
        ], 201);
    }

    private static function orders(PDO $db, ?string $userId): never
    {
        $sql = 'SELECT o.*, CAST(o.id AS CHAR) AS id, CAST(o.user_id AS CHAR) AS user_id FROM orders o';
        if ($userId !== null) $sql .= ' WHERE o.user_id = ?';
        $sql .= ' ORDER BY o.created_at DESC LIMIT 200';
        $query = $db->prepare($sql);
        $query->execute($userId === null ? [] : [$userId]);
        $orders = $query->fetchAll();
        if ($orders === []) Http::json(['orders' => []]);

        $ids = array_map(static fn(array $order): string => (string)$order['id'], $orders);
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $originalUnitPrice = self::hasColumn($db, 'order_items', 'original_unit_price') ? 'oi.original_unit_price' : 'oi.unit_price';
        $saleDiscountPercent = self::hasColumn($db, 'order_items', 'sale_discount_percent') ? 'oi.sale_discount_percent' : '0';
        $saleDiscountAmount = self::hasColumn($db, 'order_items', 'sale_discount_amount') ? 'oi.sale_discount_amount' : '0';
        $itemQuery = $db->prepare("SELECT CAST(oi.order_id AS CHAR) AS order_id, oi.product_id, oi.product_name, oi.unit_price AS price, $originalUnitPrice AS original_unit_price, $saleDiscountPercent AS sale_discount_percent, $saleDiscountAmount AS sale_discount_amount, oi.quantity, oi.image_url AS product_image, p.category AS product_category, oi.customizations_json FROM order_items oi LEFT JOIN products p ON p.id = oi.product_id WHERE oi.order_id IN ($placeholders) ORDER BY oi.id");
        $itemQuery->execute($ids);
        $itemsByOrder = [];
        foreach ($itemQuery->fetchAll() as $item) {
            $item['price'] = (float)$item['price'];
            $item['original_unit_price'] = (float)$item['original_unit_price'];
            $item['sale_discount_percent'] = (float)$item['sale_discount_percent'];
            $item['sale_discount_amount'] = (float)$item['sale_discount_amount'];
            $item['quantity'] = (int)$item['quantity'];
            $item['customizations'] = $item['customizations_json'] === null ? null : json_decode((string)$item['customizations_json'], true);
            unset($item['customizations_json']);
            $itemsByOrder[(string)$item['order_id']][] = $item;
        }
        $result = [];
        foreach ($orders as $order) {
            $order['status'] = self::orderStatusForClient((string)$order['status']);
            $order['subtotal'] = (float)$order['subtotal'];
            $order['tax'] = (float)$order['tax'];
            $order['shipping_cost'] = (float)$order['delivery_fee'];
            $order['total'] = (float)$order['total'];
            $order['items'] = $itemsByOrder[(string)$order['id']] ?? [];
            $order['created_at'] = self::isoDate((string)$order['created_at']);
            $order['updated_at'] = self::isoDate((string)$order['updated_at']);
            $result[] = $order;
        }
        Http::json(['orders' => $result]);
    }

    private static function cancelCustomerOrder(PDO $db, string $userId, string $orderId): never
    {
        $db->beginTransaction();
        try {
            $query = $db->prepare('SELECT status FROM orders WHERE id = ? AND user_id = ? FOR UPDATE');
            $query->execute([$orderId, $userId]);
            $status = $query->fetchColumn();
            if ($status === false) throw new ApiException(404, 'Order not found.');
            if ($status !== 'pending') throw new ApiException(409, 'Only pending orders can be cancelled from your account.');
            $update = $db->prepare("UPDATE orders SET status = 'cancelled' WHERE id = ?");
            $update->execute([$orderId]);
            self::reverseOrderRewards($db, $orderId);
            self::restoreOrderStock($db, $orderId);
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['success' => true, 'status' => 'cancelled']);
    }

    private static function updateOrderStatus(PDO $db, string $orderId, array $body): never
    {
        $status = $body['status'] ?? null;
        $allowed = ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'];
        if (!is_string($status) || !in_array($status, $allowed, true)) {
            throw new ApiException(422, 'Choose a valid order status.');
        }
        $db->beginTransaction();
        try {
            $query = $db->prepare('SELECT status FROM orders WHERE id = ? FOR UPDATE');
            $query->execute([$orderId]);
            $current = $query->fetchColumn();
            if ($current === false) throw new ApiException(404, 'Order not found.');
            $next = [
                'pending' => ['confirmed', 'preparing', 'cancelled'],
                'confirmed' => ['preparing', 'cancelled'],
                'preparing' => ['ready', 'cancelled'],
                'ready' => ['out_for_delivery', 'cancelled'],
                'out_for_delivery' => ['delivered'],
                'delivered' => [],
                'cancelled' => [],
            ];
            if ($current !== $status && !in_array($status, $next[(string)$current] ?? [], true)) {
                throw new ApiException(409, 'That order status change is not allowed. Refresh the order and try again.');
            }
            if ($current !== $status) {
                $update = $db->prepare('UPDATE orders SET status = ? WHERE id = ?');
                $update->execute([$status, $orderId]);
                if ($status === 'cancelled') {
                    self::reverseOrderRewards($db, $orderId);
                    self::restoreOrderStock($db, $orderId);
                }
            }
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['success' => true, 'status' => $status]);
    }

    private static function restoreOrderStock(PDO $db, string $orderId): void
    {
        $query = $db->prepare('UPDATE products p JOIN (SELECT product_id, SUM(quantity) AS quantity FROM order_items WHERE order_id = ? GROUP BY product_id) i ON i.product_id = p.id SET p.stock_quantity = p.stock_quantity + i.quantity');
        $query->execute([$orderId]);
    }

    private static function reverseOrderRewards(PDO $db, string $orderId): void
    {
        $query = $db->prepare('SELECT user_id, reward_points_awarded, reward_points_redeemed, reward_reversed FROM orders WHERE id = ? FOR UPDATE');
        $query->execute([$orderId]);
        $order = $query->fetch();
        if (!$order || (bool)$order['reward_reversed']) return;

        $awarded = (float)$order['reward_points_awarded'];
        $redeemed = (int)$order['reward_points_redeemed'];
        $update = $db->prepare('UPDATE users SET reward_points = GREATEST(0, reward_points - ? + ?) WHERE id = ?');
        $update->execute([$awarded, $redeemed, $order['user_id']]);
        $ledger = $db->prepare('INSERT INTO reward_transactions (user_id, order_id, action_key, points_delta) VALUES (?, ?, ?, ?)');
        if ($awarded > 0) $ledger->execute([$order['user_id'], $orderId, 'cancel_earn', -$awarded]);
        if ($redeemed > 0) $ledger->execute([$order['user_id'], $orderId, 'restore_redeem', $redeemed]);
        $mark = $db->prepare('UPDATE orders SET reward_reversed = 1 WHERE id = ?');
        $mark->execute([$orderId]);
    }

    private static function adminProducts(PDO $db): never
    {
        $query = $db->query('SELECT ' . self::productFields($db, '', true) . ' FROM products ORDER BY created_at DESC, id');
        Http::json(['products' => array_map(static fn(array $product): array => self::productJson($product, true), $query->fetchAll())]);
    }

    private static function createProduct(PDO $db, array $body): never
    {
        $product = self::validatedProduct($body);
        self::requireProductFeatureSchema($db, $product);
        $baseId = strtolower(trim((string)preg_replace('/[^A-Za-z0-9]+/', '-', $product['name']), '-'));
        $baseId = substr($baseId === '' ? 'product' : $baseId, 0, 52);
        $id = $baseId;
        $check = $db->prepare('SELECT 1 FROM products WHERE id = ?');
        for ($attempt = 0; $attempt < 8; $attempt++) {
            $check->execute([$id]);
            if (!$check->fetchColumn()) break;
            $id = substr($baseId, 0, 44) . '-' . bin2hex(random_bytes(4));
        }
        $columns = ['id', 'name', 'description', 'price', 'discount_percent', 'discount_scope', 'image_url', 'category', 'stock_quantity', 'is_available'];
        $values = [$id, $product['name'], $product['description'], $product['price'], $product['discount_percent'], $product['discount_scope'], $product['image_url'], $product['category'], $product['stock_quantity'], $product['available'] ? 1 : 0];
        if (self::hasColumn($db, 'products', 'image_urls_json')) {
            $columns[] = 'image_urls_json';
            $values[] = json_encode($product['image_urls'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }
        if (self::hasColumn($db, 'products', 'discount_starts_at') && self::hasColumn($db, 'products', 'discount_ends_at')) {
            $columns[] = 'discount_starts_at';
            $columns[] = 'discount_ends_at';
            $values[] = $product['discount_starts_at'];
            $values[] = $product['discount_ends_at'];
        }
        $insert = $db->prepare('INSERT INTO products (' . implode(', ', $columns) . ') VALUES (' . implode(', ', array_fill(0, count($columns), '?')) . ')');
        try {
            $insert->execute($values);
        } catch (\PDOException $error) {
            if ($error->getCode() === '23000') throw new ApiException(409, 'A product with that identifier already exists.');
            throw $error;
        }
        $query = $db->prepare('SELECT ' . self::productFields($db, '', true) . ' FROM products WHERE id = ?');
        $query->execute([$id]);
        Http::json(['product' => self::productJson($query->fetch(), true)], 201);
    }

    private static function updateProduct(PDO $db, string $id, array $body): never
    {
        $product = self::validatedProduct($body);
        self::requireProductFeatureSchema($db, $product);
        $sets = ['name = ?', 'description = ?', 'price = ?', 'discount_percent = ?', 'discount_scope = ?', 'image_url = ?', 'category = ?', 'stock_quantity = ?', 'is_available = ?'];
        $values = [$product['name'], $product['description'], $product['price'], $product['discount_percent'], $product['discount_scope'], $product['image_url'], $product['category'], $product['stock_quantity'], $product['available'] ? 1 : 0];
        if (self::hasColumn($db, 'products', 'image_urls_json')) {
            $sets[] = 'image_urls_json = ?';
            $values[] = json_encode($product['image_urls'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }
        if (self::hasColumn($db, 'products', 'discount_starts_at') && self::hasColumn($db, 'products', 'discount_ends_at')) {
            $sets[] = 'discount_starts_at = ?';
            $sets[] = 'discount_ends_at = ?';
            $values[] = $product['discount_starts_at'];
            $values[] = $product['discount_ends_at'];
        }
        $values[] = $id;
        $update = $db->prepare('UPDATE products SET ' . implode(', ', $sets) . ' WHERE id = ?');
        $update->execute($values);
        if ($update->rowCount() === 0) {
            $exists = $db->prepare('SELECT 1 FROM products WHERE id = ?');
            $exists->execute([$id]);
            if (!$exists->fetchColumn()) throw new ApiException(404, 'Product not found.');
        }
        $query = $db->prepare('SELECT ' . self::productFields($db, '', true) . ' FROM products WHERE id = ?');
        $query->execute([$id]);
        Http::json(['product' => self::productJson($query->fetch(), true)]);
    }

    private static function archiveProduct(PDO $db, string $id): never
    {
        $query = $db->prepare('UPDATE products SET is_available = 0 WHERE id = ?');
        $query->execute([$id]);
        if ($query->rowCount() === 0) {
            $exists = $db->prepare('SELECT 1 FROM products WHERE id = ?');
            $exists->execute([$id]);
            if (!$exists->fetchColumn()) throw new ApiException(404, 'Product not found.');
        }
        Http::json(['success' => true]);
    }

    private static function validatedProduct(array $body): array
    {
        $name = trim((string)($body['name'] ?? ''));
        $description = trim((string)($body['description'] ?? ''));
        $category = trim((string)($body['category'] ?? ''));
        $image = trim((string)($body['image_url'] ?? ''));
        $rawImages = $body['image_urls'] ?? null;
        $imageUrls = [];
        $price = $body['price'] ?? null;
        $stock = filter_var($body['stock_quantity'] ?? 0, FILTER_VALIDATE_INT);
        $discount = $body['discount_percent'] ?? 0;
        $discountScope = $body['discount_scope'] ?? 'all';
        $discountValue = is_numeric($discount) ? (float)$discount : 0.0;
        $scheduleProvided = array_key_exists('discount_starts_at', $body) || array_key_exists('discount_ends_at', $body);
        $discountStartsAt = self::normalizeSaleDate($body['discount_starts_at'] ?? null);
        $discountEndsAt = self::normalizeSaleDate($body['discount_ends_at'] ?? null);
        $nowSaleDate = gmdate('Y-m-d H:i:s');
        $hasScheduleDate = $discountStartsAt !== null || $discountEndsAt !== null;
        $invalidSchedule = $scheduleProvided && (
            ($discountValue > 0 && $discountEndsAt === null) ||
            ($discountValue > 0 && $discountEndsAt !== null && $discountEndsAt <= $nowSaleDate) ||
            ($hasScheduleDate && (
                $discountStartsAt === null || $discountEndsAt === null ||
                $discountStartsAt >= $discountEndsAt
            ))
        );
        if ($rawImages !== null && (!is_array($rawImages) || !array_is_list($rawImages) || count($rawImages) > 3)) {
            throw new ApiException(422, 'Add no more than three product images.');
        }
        if (is_array($rawImages)) {
            foreach ($rawImages as $rawImage) {
                if (!is_string($rawImage)) throw new ApiException(422, 'Each product image must be an image path or URL.');
                $value = trim($rawImage);
                if ($value !== '') $imageUrls[] = $value;
            }
        }
        if ($imageUrls === [] && $image !== '') $imageUrls[] = $image;
        if ($imageUrls !== []) $image = $imageUrls[0];
        $validImage = static fn(string $value): bool => mb_strlen($value) <= 1000 && preg_match('#^(https?://|assets/|[A-Za-z0-9_-]{1,80}$)#i', $value) === 1;
        if (mb_strlen($name) < 2 || mb_strlen($name) > 160 || mb_strlen($description) > 5000 ||
            mb_strlen($category) < 2 || mb_strlen($category) > 80 || mb_strlen($image) > 1000 ||
            ($image !== '' && !$validImage($image)) ||
            array_filter($imageUrls, static fn(string $value): bool => !$validImage($value)) !== [] ||
            (!is_int($price) && !is_float($price) && !is_string($price)) ||
            !is_numeric($price) || (float)$price <= 0 || (float)$price > 99999999.99 ||
            (!is_int($discount) && !is_float($discount) && !is_string($discount)) ||
            !is_numeric($discount) || (float)$discount < 0 || (float)$discount > 90 ||
            !is_string($discountScope) || !preg_match('/^(all|size:(Regular|Small|Medium|Large|Double|XL)|brand:(Coca-Cola|Sprite|Pepsi|Royal|Mountain Dew|7Up))$/', $discountScope) ||
            $invalidSchedule ||
            $stock === false || $stock < 0 || $stock > 100000 ||
            (isset($body['available']) && !is_bool($body['available']))) {
            throw new ApiException(422, 'Check the product name, description, price, category, image, and stock.');
        }
        return [
            'name' => $name, 'description' => $description, 'category' => $category,
            'image_url' => $image === '' ? null : $image,
            'image_urls' => array_slice($imageUrls, 0, 3),
            'price' => number_format((float)$price, 2, '.', ''), 'stock_quantity' => $stock,
            'discount_percent' => number_format((float)$discount, 2, '.', ''),
            'discount_scope' => $discountScope,
            'discount_starts_at' => $discountValue > 0 ? $nowSaleDate : null,
            'discount_ends_at' => $discountEndsAt,
            'available' => $body['available'] ?? true,
        ];
    }

    private static function normalizeSaleDate(mixed $value): ?string
    {
        if ($value === null || $value === '') return null;
        if (!is_string($value) || strlen($value) > 64) throw new ApiException(422, 'Choose a valid sale start and end time.');
        try {
            return (new \DateTimeImmutable($value))
                ->setTimezone(new \DateTimeZone('UTC'))
                ->format('Y-m-d H:i:s');
        } catch (\Throwable) {
            throw new ApiException(422, 'Choose a valid sale start and end time.');
        }
    }

    private static function requireProductFeatureSchema(PDO $db, array $product): void
    {
        if (count($product['image_urls']) > 1 && !self::hasColumn($db, 'products', 'image_urls_json')) {
            throw new ApiException(503, 'Import migration 006 to save product galleries.');
        }
        $hasSaleSchedule = self::hasColumn($db, 'products', 'discount_starts_at') && self::hasColumn($db, 'products', 'discount_ends_at');
        if (($product['discount_starts_at'] !== null || $product['discount_ends_at'] !== null) && !$hasSaleSchedule) {
            throw new ApiException(503, 'Import migration 006 to schedule timed discount sales.');
        }
    }

    private static function adminCustomers(PDO $db): never
    {
        $lastSeen = self::hasColumn($db, 'users', 'last_seen_at') ? 'u.last_seen_at' : 'NULL AS last_seen_at';
        $query = $db->query("SELECT CAST(u.id AS CHAR) AS id, u.full_name AS name, u.email, COALESCE(u.phone, '') AS phone, COALESCE(u.default_address, '') AS address, u.reward_points, u.created_at AS joined_at, u.is_active, $lastSeen, COUNT(DISTINCT o.id) AS order_count, COALESCE(SUM(CASE WHEN o.status <> 'cancelled' THEN o.total ELSE 0 END), 0) AS total_spent FROM users u LEFT JOIN orders o ON o.user_id = u.id WHERE u.role = 'customer' GROUP BY u.id ORDER BY u.created_at DESC LIMIT 500");
        $customers = $query->fetchAll();
        $now = time();
        $onlineCount = 0;
        foreach ($customers as &$customer) {
            $customer['order_count'] = (int)$customer['order_count'];
            $customer['total_spent'] = (float)$customer['total_spent'];
            $customer['reward_points'] = (float)$customer['reward_points'];
            $customer['is_active'] = (bool)$customer['is_active'];
            $customer['joined_at'] = self::isoDate((string)$customer['joined_at']);
            $lastSeenAt = $customer['last_seen_at'] === null ? null : self::isoDate((string)$customer['last_seen_at']);
            $lastSeenTimestamp = $lastSeenAt === null ? false : strtotime($lastSeenAt);
            $customer['is_online'] = $lastSeenTimestamp !== false && $now - $lastSeenTimestamp <= 120;
            if ($customer['is_online']) $onlineCount++;
            $customer['last_seen_at'] = $lastSeenAt;
        }
        unset($customer);
        $totalQuery = $db->query("SELECT COUNT(*) FROM users WHERE role = 'customer'");
        Http::json(['customers' => $customers, 'total_customers' => (int)$totalQuery->fetchColumn(), 'online_customers' => $onlineCount]);
    }

    private static function adminCustomerPhoto(PDO $db, string $id): never
    {
        if (!self::hasColumn($db, 'users', 'profile_image')) {
            Http::json(['image_base64' => null, 'mime_type' => null]);
        }
        $hasMime = self::hasColumn($db, 'users', 'profile_image_mime');
        $mimeField = $hasMime ? 'profile_image_mime' : 'NULL AS profile_image_mime';
        $query = $db->prepare("SELECT profile_image, $mimeField FROM users WHERE id = ? AND role = 'customer' LIMIT 1");
        $query->execute([$id]);
        $row = $query->fetch();
        if (!$row) throw new ApiException(404, 'Customer not found.');
        Http::json([
            'image_base64' => empty($row['profile_image']) ? null : base64_encode((string)$row['profile_image']),
            'mime_type' => $row['profile_image_mime'] ?? null,
        ]);
    }

    private static function updateCustomerStatus(PDO $db, string $id, array $body): never
    {
        if (!isset($body['is_active']) || !is_bool($body['is_active'])) throw new ApiException(422, 'Choose an active or inactive account status.');
        $query = $db->prepare("UPDATE users SET is_active = ? WHERE id = ? AND role = 'customer'");
        $query->execute([$body['is_active'] ? 1 : 0, $id]);
        if ($query->rowCount() === 0) {
            $exists = $db->prepare("SELECT 1 FROM users WHERE id = ? AND role = 'customer'");
            $exists->execute([$id]);
            if (!$exists->fetchColumn()) throw new ApiException(404, 'Customer not found.');
        }
        if (!$body['is_active']) {
            $delete = $db->prepare('DELETE FROM api_tokens WHERE user_id = ?');
            $delete->execute([$id]);
        }
        Http::json(['success' => true, 'is_active' => $body['is_active']]);
    }

    private static function adminDashboard(PDO $db): never
    {
        $stats = $db->query("SELECT (SELECT COUNT(*) FROM orders) AS total_orders, (SELECT COUNT(*) FROM orders WHERE status = 'pending') AS pending_orders, (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery')) AS processing_orders, (SELECT COUNT(*) FROM orders WHERE status = 'delivered') AS delivered_orders, (SELECT COUNT(*) FROM orders WHERE status = 'cancelled') AS cancelled_orders, (SELECT COALESCE(SUM(total), 0) FROM orders WHERE status = 'delivered') AS delivered_revenue, (SELECT COUNT(*) FROM users WHERE role = 'customer') AS total_customers, (SELECT COUNT(*) FROM users WHERE role = 'customer' AND is_active = 1) AS active_customers, (SELECT COUNT(*) FROM products) AS total_products, (SELECT COUNT(*) FROM products WHERE is_available = 1 AND stock_quantity > 0) AS available_products")->fetch();
        foreach ($stats as $key => $value) $stats[$key] = str_ends_with((string)$key, 'revenue') ? (float)$value : (int)$value;
        $dailyRevenue = $db->query(
            "SELECT DATE_FORMAT(calendar.day_value, '%Y-%m-%d') AS day,
                    COALESCE(SUM(orders.total), 0) AS revenue
             FROM (
                 SELECT CURRENT_DATE - INTERVAL 6 DAY AS day_value UNION ALL
                 SELECT CURRENT_DATE - INTERVAL 5 DAY UNION ALL
                 SELECT CURRENT_DATE - INTERVAL 4 DAY UNION ALL
                 SELECT CURRENT_DATE - INTERVAL 3 DAY UNION ALL
                 SELECT CURRENT_DATE - INTERVAL 2 DAY UNION ALL
                 SELECT CURRENT_DATE - INTERVAL 1 DAY UNION ALL
                 SELECT CURRENT_DATE
             ) AS calendar
             LEFT JOIN orders
               ON DATE(orders.created_at) = calendar.day_value
              AND orders.status <> 'cancelled'
             GROUP BY calendar.day_value
             ORDER BY calendar.day_value"
        )->fetchAll();
        $stats['daily_revenue'] = array_map(
            static fn(array $day): array => [
                'day' => (string)$day['day'],
                'revenue' => (float)$day['revenue'],
            ],
            $dailyRevenue
        );
        Http::json(['dashboard' => $stats]);
    }

    private static function adminPaymentSummary(PDO $db): never
    {
        if (!self::hasColumn($db, 'store_withdrawals', 'amount')) {
            throw new ApiException(503, 'Apply database migration 008 before using Payment Setup.');
        }
        Http::json(self::paymentSummary($db));
    }

    private static function createAdminWithdrawal(PDO $db, array $admin, array $body): never
    {
        if (!self::hasColumn($db, 'store_withdrawals', 'amount')) {
            throw new ApiException(503, 'Apply database migration 008 before using Payment Setup.');
        }

        $rawAmount = $body['amount'] ?? null;
        $amount = is_string($rawAmount)
            ? trim($rawAmount)
            : (is_int($rawAmount) || is_float($rawAmount)
                ? json_encode($rawAmount, JSON_PRESERVE_ZERO_FRACTION)
                : false);
        if (!is_string($amount) || !preg_match('/^\d{1,8}(?:\.\d{1,2})?$/', $amount)) {
            throw new ApiException(422, 'Enter a valid withdrawal amount with up to two decimal places.');
        }
        [$whole, $fraction] = array_pad(explode('.', $amount, 2), 2, '');
        $amountCents = ((int)$whole * 100) + (int)str_pad($fraction, 2, '0');
        if ($amountCents <= 0) {
            throw new ApiException(422, 'Withdrawal amount must be greater than zero.');
        }

        $note = $body['note'] ?? null;
        if ($note !== null && (!is_string($note) || mb_strlen(trim($note)) > 200)) {
            throw new ApiException(422, 'Withdrawal note must be 200 characters or fewer.');
        }
        $note = is_string($note) && trim($note) !== '' ? trim($note) : null;

        try {
            $db->beginTransaction();
            // Serialize admin withdrawals against the same row so two requests
            // cannot both spend the same available balance.
            $db->exec('INSERT IGNORE INTO store_profile (id) VALUES (1)');
            $db->query('SELECT id FROM store_profile WHERE id = 1 FOR UPDATE')->fetch();
            $revenueQuery = $db->query("SELECT COALESCE(SUM(total), 0) FROM orders WHERE status = 'delivered'");
            $withdrawnQuery = $db->query('SELECT COALESCE(SUM(amount), 0) FROM store_withdrawals');
            $revenueCents = self::moneyCents((string)$revenueQuery->fetchColumn());
            $withdrawnCents = self::moneyCents((string)$withdrawnQuery->fetchColumn());
            $availableCents = max(0, $revenueCents - $withdrawnCents);
            if ($amountCents > $availableCents) {
                $db->rollBack();
                throw new ApiException(
                    409,
                    'Insufficient funds. Available balance is ₱' . self::decimal($availableCents) . '.'
                );
            }

            $insert = $db->prepare(
                'INSERT INTO store_withdrawals (admin_user_id, amount, note) VALUES (?, ?, ?)'
            );
            $insert->execute([(int)$admin['id'], self::decimal($amountCents), $note]);
            $withdrawalId = (int)$db->lastInsertId();
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }

        Http::json([
            'success' => true,
            'withdrawal_id' => $withdrawalId,
            'amount' => $amountCents / 100,
            'payment_summary' => self::paymentSummary($db),
        ], 201);
    }

    private static function paymentSummary(PDO $db): array
    {
        $totals = $db->query(
            "SELECT
                (SELECT COALESCE(SUM(total), 0) FROM orders WHERE status = 'delivered') AS delivered_revenue,
                (SELECT COALESCE(SUM(amount), 0) FROM store_withdrawals) AS total_withdrawn"
        )->fetch();
        $revenueCents = self::moneyCents((string)($totals['delivered_revenue'] ?? '0'));
        $withdrawnCents = self::moneyCents((string)($totals['total_withdrawn'] ?? '0'));
        $query = $db->query(
            'SELECT id, amount, note, created_at FROM store_withdrawals ORDER BY id DESC LIMIT 10'
        );
        $withdrawals = array_map(static fn(array $row): array => [
            'id' => (int)$row['id'],
            'amount' => (float)$row['amount'],
            'note' => $row['note'],
            'created_at' => self::isoDate((string)$row['created_at']),
        ], $query->fetchAll());

        return [
            'delivered_revenue' => $revenueCents / 100,
            'total_withdrawn' => $withdrawnCents / 100,
            'available_balance' => max(0, $revenueCents - $withdrawnCents) / 100,
            'recent_withdrawals' => $withdrawals,
        ];
    }

    private static function adminSystemStatus(PDO $db): never
    {
        $columns = [];
        $columnQuery = $db->prepare(
            'SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE
             FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND ((TABLE_NAME = \'users\' AND COLUMN_NAME = \'is_active\')
                 OR (TABLE_NAME = \'users\' AND COLUMN_NAME = \'last_seen_at\')
                 OR (TABLE_NAME = \'users\' AND COLUMN_NAME IN (\'reward_points\', \'profile_image\'))
                 OR (TABLE_NAME = \'order_items\' AND COLUMN_NAME = \'customizations_json\')
                 OR (TABLE_NAME = \'order_items\' AND COLUMN_NAME IN (\'original_unit_price\', \'sale_discount_percent\', \'sale_discount_amount\'))
                 OR (TABLE_NAME = \'orders\' AND COLUMN_NAME IN (\'status\', \'reward_points_awarded\', \'reward_points_redeemed\', \'reward_discount\', \'reward_reversed\'))
                 OR (TABLE_NAME = \'products\' AND COLUMN_NAME IN (\'discount_percent\', \'discount_scope\', \'image_urls_json\', \'discount_starts_at\', \'discount_ends_at\'))
                 OR (TABLE_NAME = \'user_calendar_reminders\' AND COLUMN_NAME = \'reminder_time\'))'
        );
        $columnQuery->execute();
        foreach ($columnQuery->fetchAll() as $column) {
            $columns[$column['TABLE_NAME'] . '.' . $column['COLUMN_NAME']] = (string)$column['COLUMN_TYPE'];
        }

        $tableQuery = $db->prepare(
            'SELECT TABLE_NAME
             FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME IN (\'user_preferences\', \'contact_messages\', \'cart_items\', \'user_calendar_reminders\', \'store_profile\', \'reward_transactions\', \'contact_attachments\', \'store_withdrawals\')'
        );
        $tableQuery->execute();
        $tables = array_fill_keys(array_map('strval', $tableQuery->fetchAll(PDO::FETCH_COLUMN)), true);

        $requirements = [
            'users.is_active' => isset($columns['users.is_active']),
            'users.last_seen_at' => isset($columns['users.last_seen_at']),
            'order_items.customizations_json' => isset($columns['order_items.customizations_json']),
            'order_items.sale_price_snapshots' => isset($columns['order_items.original_unit_price']) && isset($columns['order_items.sale_discount_percent']) && isset($columns['order_items.sale_discount_amount']),
            'orders.status.out_for_delivery' => isset($columns['orders.status']) && str_contains($columns['orders.status'], 'out_for_delivery'),
            'users.reward_points' => isset($columns['users.reward_points']),
            'users.profile_image' => isset($columns['users.profile_image']),
            'products.discount_percent' => isset($columns['products.discount_percent']),
            'products.discount_scope' => isset($columns['products.discount_scope']),
            'products.image_urls_json' => isset($columns['products.image_urls_json']),
            'products.discount_starts_at' => isset($columns['products.discount_starts_at']),
            'products.discount_ends_at' => isset($columns['products.discount_ends_at']),
            'orders.reward_columns' => isset($columns['orders.reward_points_awarded']) && isset($columns['orders.reward_points_redeemed']) && isset($columns['orders.reward_discount']) && isset($columns['orders.reward_reversed']),
            'user_preferences' => isset($tables['user_preferences']),
            'contact_messages' => isset($tables['contact_messages']),
            'cart_items' => isset($tables['cart_items']),
            'user_calendar_reminders' => isset($tables['user_calendar_reminders']),
            'user_calendar_reminders.reminder_time' => isset($columns['user_calendar_reminders.reminder_time']),
            'store_profile' => isset($tables['store_profile']),
            'store_withdrawals' => isset($tables['store_withdrawals']),
            'reward_transactions' => isset($tables['reward_transactions']),
            'contact_attachments' => isset($tables['contact_attachments']),
        ];
        $missing = array_keys(array_filter($requirements, static fn(bool $ready): bool => !$ready));

        Http::json([
            'database_connected' => true,
            'workflow_schema_ready' => $missing === [],
            'missing_requirements' => $missing,
        ]);
    }

    private static function readStoreProfile(PDO $db): array
    {
        $query = $db->query(
            'SELECT store_name, support_email, support_phone, facebook_url, street_address, opening_hours, delivery_coverage
             FROM store_profile WHERE id = 1'
        );
        return $query->fetch() ?: [
            'store_name' => 'BurgerBites',
            'support_email' => null,
            'support_phone' => null,
            'facebook_url' => null,
            'street_address' => null,
            'opening_hours' => null,
            'delivery_coverage' => null,
        ];
    }

    private static function updateStoreProfile(PDO $db, array $body): never
    {
        $storeName = $body['store_name'] ?? null;
        if (!is_string($storeName) || mb_strlen(trim($storeName)) < 2 || mb_strlen(trim($storeName)) > 120) {
            throw new ApiException(422, 'Enter a store name between 2 and 120 characters.');
        }
        $storeName = trim($storeName);
        $email = self::optionalStoreField($body, 'support_email', 254, 'Support email');
        if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException(422, 'Enter a valid support email address.');
        }
        $phone = self::optionalStoreField($body, 'support_phone', 32, 'Support phone');
        $facebook = self::optionalStoreField($body, 'facebook_url', 500, 'Facebook URL');
        if ($facebook !== null) {
            $url = filter_var($facebook, FILTER_VALIDATE_URL);
            if ($url === false || strtolower((string)parse_url($facebook, PHP_URL_SCHEME)) !== 'https') {
                throw new ApiException(422, 'Enter a valid HTTPS Facebook page URL.');
            }
        }
        $address = self::optionalStoreField($body, 'street_address', 500, 'Store address');
        $hours = self::optionalStoreField($body, 'opening_hours', 160, 'Opening hours');
        $coverage = self::optionalStoreField($body, 'delivery_coverage', 500, 'Delivery coverage');

        $query = $db->prepare(
            'INSERT INTO store_profile (id, store_name, support_email, support_phone, facebook_url, street_address, opening_hours, delivery_coverage)
             VALUES (1, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE store_name = VALUES(store_name), support_email = VALUES(support_email),
                 support_phone = VALUES(support_phone), facebook_url = VALUES(facebook_url),
                 street_address = VALUES(street_address), opening_hours = VALUES(opening_hours),
                 delivery_coverage = VALUES(delivery_coverage)'
        );
        $query->execute([$storeName, $email, $phone, $facebook, $address, $hours, $coverage]);
        Http::json(['store_profile' => self::readStoreProfile($db)]);
    }

    private static function optionalStoreField(array $body, string $key, int $maxLength, string $label): ?string
    {
        $value = $body[$key] ?? '';
        if (!is_string($value)) {
            throw new ApiException(422, $label . ' must be text.');
        }
        $value = trim($value);
        if (mb_strlen($value) > $maxLength) {
            throw new ApiException(422, $label . ' is too long.');
        }
        return $value === '' ? null : $value;
    }

    private static function preferences(PDO $db, string $userId): never
    {
        $insert = $db->prepare('INSERT IGNORE INTO user_preferences (user_id) VALUES (?)');
        $insert->execute([$userId]);
        $query = $db->prepare('SELECT language, theme_mode, theme_palette, order_updates, digital_receipt, promotional_alerts FROM user_preferences WHERE user_id = ?');
        $query->execute([$userId]);
        $data = $query->fetch();
        foreach (['order_updates', 'digital_receipt', 'promotional_alerts'] as $key) $data[$key] = (bool)$data[$key];
        Http::json(['preferences' => $data]);
    }

    private static function updatePreferences(PDO $db, string $userId, array $body): never
    {
        $current = ['language' => 'en', 'theme_mode' => 'light', 'theme_palette' => 'Burger Bites', 'order_updates' => true, 'digital_receipt' => true, 'promotional_alerts' => false];
        $query = $db->prepare('SELECT language, theme_mode, theme_palette, order_updates, digital_receipt, promotional_alerts FROM user_preferences WHERE user_id = ?');
        $query->execute([$userId]);
        $stored = $query->fetch();
        if ($stored) foreach ($current as $key => $value) $current[$key] = $stored[$key];
        foreach (['language', 'theme_mode', 'theme_palette', 'order_updates', 'digital_receipt', 'promotional_alerts'] as $key) if (array_key_exists($key, $body)) $current[$key] = $body[$key];
        $languages = ['en', 'fil', 'ceb', 'ilo', 'war', 'es', 'ja', 'ko'];
        $palettes = ['Burger Bites', 'Sizzling Crimson', 'Golden Mustard Cheddar', 'Emerald Mint Fresh', 'Midnight Smoke Black', 'Sweet Berry Bloom'];
        if (!is_string($current['language']) || !in_array($current['language'], $languages, true) ||
            !is_string($current['theme_mode']) || !in_array($current['theme_mode'], ['light', 'dark', 'system'], true) ||
            !is_string($current['theme_palette']) || !in_array($current['theme_palette'], $palettes, true)) {
            throw new ApiException(422, 'Choose a supported language and display mode.');
        }
        foreach (['order_updates', 'digital_receipt', 'promotional_alerts'] as $key) if (!is_bool($current[$key])) throw new ApiException(422, 'Notification preferences must be on or off.');
        $save = $db->prepare('INSERT INTO user_preferences (user_id, language, theme_mode, theme_palette, order_updates, digital_receipt, promotional_alerts) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE language = VALUES(language), theme_mode = VALUES(theme_mode), theme_palette = VALUES(theme_palette), order_updates = VALUES(order_updates), digital_receipt = VALUES(digital_receipt), promotional_alerts = VALUES(promotional_alerts)');
        $save->execute([$userId, $current['language'], $current['theme_mode'], $current['theme_palette'], (int)$current['order_updates'], (int)$current['digital_receipt'], (int)$current['promotional_alerts']]);
        Http::json(['preferences' => $current]);
    }

    private static function calendarReminders(PDO $db, array $user): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use the calendar.');
        $reminderTimeSelect = self::calendarReminderTimeReady($db)
            ? 'TIME_FORMAT(reminder_time, \'%H:%i\') AS reminder_time'
            : '\'09:00\' AS reminder_time';
        $query = $db->prepare(
            'SELECT CAST(id AS CHAR) AS id, DATE_FORMAT(reminder_date, \'%Y-%m-%d\') AS reminder_date,
                    ' . $reminderTimeSelect . ',
                    title, notes, created_at
             FROM user_calendar_reminders
             WHERE user_id = ?
             ORDER BY reminder_date, reminder_time, id
             LIMIT 200'
        );
        $query->execute([$user['id']]);
        $reminders = $query->fetchAll();
        foreach ($reminders as &$reminder) $reminder['created_at'] = self::isoDate((string)$reminder['created_at']);
        unset($reminder);
        Http::json(['reminders' => $reminders]);
    }

    private static function createCalendarReminder(PDO $db, array $user, array $body): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use the calendar.');
        if (!self::calendarReminderTimeReady($db)) {
            throw new ApiException(503, 'The calendar reminder-time database update has not been applied yet.');
        }
        [$date, $time, $title, $notes] = self::calendarReminderFields($body);
        $insert = $db->prepare('INSERT INTO user_calendar_reminders (user_id, reminder_date, reminder_time, title, notes) VALUES (?, ?, ?, ?, ?)');
        $insert->execute([$user['id'], $date, $time, $title, $notes]);
        Http::json(['success' => true, 'id' => (string)$db->lastInsertId()], 201);
    }

    private static function updateCalendarReminder(PDO $db, array $user, string $id, array $body): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use the calendar.');
        if (!self::calendarReminderTimeReady($db)) {
            throw new ApiException(503, 'The calendar reminder-time database update has not been applied yet.');
        }
        [$date, $time, $title, $notes] = self::calendarReminderFields($body);
        $update = $db->prepare('UPDATE user_calendar_reminders SET reminder_date = ?, reminder_time = ?, title = ?, notes = ? WHERE id = ? AND user_id = ?');
        $update->execute([$date, $time, $title, $notes, $id, $user['id']]);
        if ($update->rowCount() === 0) {
            $exists = $db->prepare('SELECT 1 FROM user_calendar_reminders WHERE id = ? AND user_id = ?');
            $exists->execute([$id, $user['id']]);
            if (!$exists->fetchColumn()) throw new ApiException(404, 'Reminder not found.');
        }
        Http::json(['success' => true]);
    }

    private static function deleteCalendarReminder(PDO $db, array $user, string $id): never
    {
        if ($user['role'] !== 'customer') throw new ApiException(403, 'Only customer accounts can use the calendar.');
        $delete = $db->prepare('DELETE FROM user_calendar_reminders WHERE id = ? AND user_id = ?');
        $delete->execute([$id, $user['id']]);
        if ($delete->rowCount() === 0) throw new ApiException(404, 'Reminder not found.');
        Http::json(['success' => true]);
    }

    private static function calendarReminderFields(array $body): array
    {
        $date = $body['reminder_date'] ?? null;
        $time = $body['reminder_time'] ?? null;
        $title = $body['title'] ?? null;
        $notes = $body['notes'] ?? '';
        if (!is_string($date) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            throw new ApiException(422, 'Choose a valid reminder date.');
        }
        $parsedDate = \DateTimeImmutable::createFromFormat('!Y-m-d', $date);
        if (!$parsedDate || $parsedDate->format('Y-m-d') !== $date) {
            throw new ApiException(422, 'Choose a valid reminder date.');
        }
        if (!is_string($time) || !preg_match('/^\d{2}:\d{2}$/', $time)) {
            throw new ApiException(422, 'Choose a valid reminder time.');
        }
        $parsedTime = \DateTimeImmutable::createFromFormat('!H:i', $time);
        if (!$parsedTime || $parsedTime->format('H:i') !== $time) {
            throw new ApiException(422, 'Choose a valid reminder time.');
        }
        if (!is_string($title) || mb_strlen(trim($title)) < 2 || mb_strlen(trim($title)) > 100 ||
            !is_string($notes) || mb_strlen(trim($notes)) > 500) {
            throw new ApiException(422, 'Enter a reminder title and keep notes under 500 characters.');
        }
        $notes = trim($notes);
        return [$date, $time, trim($title), $notes === '' ? null : $notes];
    }

    private static function calendarReminderTimeReady(PDO $db): bool
    {
        $query = $db->prepare(
            'SELECT 1 FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = \'user_calendar_reminders\'
               AND COLUMN_NAME = \'reminder_time\'
             LIMIT 1'
        );
        $query->execute();
        return (bool)$query->fetchColumn();
    }

    private static function createContactMessage(PDO $db, string $pepper, array $body): never
    {
        $rawName = $body['full_name'] ?? null;
        $rawContact = $body['email_or_phone'] ?? null;
        $rawTopic = $body['topic'] ?? null;
        $rawMessage = $body['message'] ?? null;
        if (!is_string($rawName) || !is_string($rawContact) ||
            !is_string($rawTopic) || !is_string($rawMessage)) {
            throw new ApiException(422, 'Check your name, contact information, topic, and message.');
        }
        $name = trim($rawName);
        $contact = trim($rawContact);
        $topic = trim($rawTopic);
        $message = trim($rawMessage);
        if (mb_strlen($name) < 2 || mb_strlen($name) > 120 || mb_strlen($contact) < 5 || mb_strlen($contact) > 254 ||
            mb_strlen($topic) < 2 || mb_strlen($topic) > 80 || mb_strlen($message) < 5 || mb_strlen($message) > 2000) {
            throw new ApiException(422, 'Check your name, contact information, topic, and message.');
        }
        $rawAttachments = $body['attachments'] ?? [];
        if (!is_array($rawAttachments) || !array_is_list($rawAttachments) || count($rawAttachments) > 5) {
            throw new ApiException(422, 'Attach up to five images.');
        }
        $attachments = [];
        foreach ($rawAttachments as $attachment) {
            if (!is_array($attachment) || !is_string($attachment['name'] ?? null) ||
                !is_string($attachment['image_base64'] ?? null) || strlen($attachment['image_base64']) > 700000) {
                throw new ApiException(422, 'One of the attached images is invalid or too large.');
            }
            $bytes = base64_decode($attachment['image_base64'], true);
            if ($bytes === false || strlen($bytes) > 512 * 1024) {
                throw new ApiException(422, 'Each photo must be 512 KB or smaller.');
            }
            $info = @getimagesizefromstring($bytes);
            $mime = is_array($info) ? (string)($info['mime'] ?? '') : '';
            if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], true)) {
                throw new ApiException(422, 'Use JPEG, PNG, WebP, or GIF photos.');
            }
            $fileName = trim(basename($attachment['name']));
            if ($fileName === '' || mb_strlen($fileName) > 200) $fileName = 'support-photo';
            $attachments[] = ['name' => $fileName, 'mime' => $mime, 'bytes' => $bytes];
        }
        self::applyAuthLimits($db, $pepper, 'contact', $contact, 10, 3600, 3, 3600);
        $db->beginTransaction();
        try {
            $insert = $db->prepare('INSERT INTO contact_messages (full_name, email_or_phone, topic, message) VALUES (?, ?, ?, ?)');
            $insert->execute([$name, $contact, $topic, $message]);
            $messageId = (string)$db->lastInsertId();
            $add = $db->prepare('INSERT INTO contact_attachments (message_id, file_name, mime_type, file_data, byte_size) VALUES (?, ?, ?, ?, ?)');
            foreach ($attachments as $attachment) {
                $add->execute([$messageId, $attachment['name'], $attachment['mime'], $attachment['bytes'], strlen($attachment['bytes'])]);
            }
            $db->commit();
        } catch (Throwable $error) {
            if ($db->inTransaction()) $db->rollBack();
            throw $error;
        }
        Http::json(['success' => true, 'message_id' => $messageId, 'attachment_count' => count($attachments)], 201);
    }

    private static function adminContactMessages(PDO $db): never
    {
        $query = $db->query('SELECT CAST(m.id AS CHAR) AS id, CAST(m.user_id AS CHAR) AS user_id, m.full_name, m.email_or_phone, m.topic, m.message, m.status, m.created_at, COUNT(a.id) AS attachment_count FROM contact_messages m LEFT JOIN contact_attachments a ON a.message_id = m.id GROUP BY m.id ORDER BY m.created_at DESC LIMIT 200');
        $messages = $query->fetchAll();
        foreach ($messages as &$message) $message['created_at'] = self::isoDate((string)$message['created_at']);
        unset($message);
        Http::json(['messages' => $messages]);
    }

    private static function adminContactAttachments(PDO $db, string $messageId): never
    {
        $query = $db->prepare('SELECT file_name, mime_type, file_data FROM contact_attachments WHERE message_id = ? ORDER BY id LIMIT 5');
        $query->execute([$messageId]);
        $attachments = array_map(static fn(array $row): array => [
            'name' => (string)$row['file_name'],
            'mime_type' => (string)$row['mime_type'],
            'image_base64' => base64_encode((string)$row['file_data']),
        ], $query->fetchAll());
        Http::json(['attachments' => $attachments]);
    }

    private static function updateContactMessageStatus(PDO $db, string $id, array $body): never
    {
        $status = $body['status'] ?? null;
        if (!is_string($status) || !in_array($status, ['new', 'in_progress', 'resolved'], true)) {
            throw new ApiException(422, 'Choose a valid support message status.');
        }
        $query = $db->prepare('UPDATE contact_messages SET status = ? WHERE id = ?');
        $query->execute([$status, $id]);
        if ($query->rowCount() === 0) {
            $exists = $db->prepare('SELECT 1 FROM contact_messages WHERE id = ?');
            $exists->execute([$id]);
            if (!$exists->fetchColumn()) throw new ApiException(404, 'Support message not found.');
        }
        Http::json(['success' => true, 'status' => $status]);
    }

    private static function orderStatusForClient(string $status): string
    {
        return match ($status) {
            'confirmed', 'preparing' => 'processing',
            'out_for_delivery' => 'shipped',
            'cancelled' => 'canceled',
            default => $status,
        };
    }

    private static function isoDate(string $value): string
    {
        $timestamp = strtotime($value . ' UTC');
        return gmdate('Y-m-d\TH:i:s\Z', $timestamp === false ? time() : $timestamp);
    }

    private static function findUser(PDO $db, string $id): array
    {
        $query = $db->prepare('SELECT id, role, email, full_name, phone, branch_name, default_address FROM users WHERE id = ? LIMIT 1');
        $query->execute([$id]);
        $user = $query->fetch();
        if (!$user) throw new ApiException(404, 'Account not found.');
        return $user;
    }

    private static function productJson(array $product, bool $includeStock = false): array
    {
        $images = [];
        if (isset($product['image_urls_json']) && is_string($product['image_urls_json'])) {
            $decoded = json_decode($product['image_urls_json'], true);
            if (is_array($decoded) && array_is_list($decoded)) {
                $images = array_values(array_slice(array_filter($decoded, static fn($value): bool => is_string($value) && trim($value) !== ''), 0, 3));
            }
        }
        if ($images === [] && is_string($product['image_url'] ?? null) && trim((string)$product['image_url']) !== '') {
            $images[] = (string)$product['image_url'];
        }
        $result = [
            'id' => (string)$product['id'], 'name' => (string)$product['name'],
            'description' => (string)($product['description'] ?? ''),
            'price' => (float)$product['price'], 'image_url' => $product['image_url'],
            'image_urls' => $images,
            'discount_percent' => isset($product['discount_percent']) ? (float)$product['discount_percent'] : 0.0,
            'discount_scope' => (string)($product['discount_scope'] ?? 'all'),
            'discount_starts_at' => !empty($product['discount_starts_at']) ? self::isoDate((string)$product['discount_starts_at']) : null,
            'discount_ends_at' => !empty($product['discount_ends_at']) ? self::isoDate((string)$product['discount_ends_at']) : null,
            'category' => $product['category'], 'rating' => $product['rating'] === null ? null : (float)$product['rating'],
            'review_count' => $product['review_count'] === null ? null : (int)$product['review_count'],
            'available' => (bool)$product['is_available'] && (!isset($product['stock_quantity']) || (int)$product['stock_quantity'] > 0),
            'created_at' => gmdate('Y-m-d\TH:i:s\Z', strtotime((string)$product['created_at'] . ' UTC')),
        ];
        if ($includeStock && isset($product['stock_quantity'])) $result['stock_quantity'] = (int)$product['stock_quantity'];
        return $result;
    }

    private static function productUnitPrice(array $product, array $customizations): int
    {
        return self::productPriceBreakdown($product, $customizations)['unit_price'];
    }

    /** Return server-authoritative list price and timed-sale price in cents. */
    private static function productPriceBreakdown(array $product, array $customizations): array
    {
        $listPrice = self::customizedUnitPrice(
            (string)$product['price'],
            (string)$product['category'],
            $customizations,
            (string)$product['name']
        );
        $discount = (float)($product['discount_percent'] ?? 0);
        $scope = (string)($product['discount_scope'] ?? 'all');
        $now = time();
        $endsAt = !empty($product['discount_ends_at']) ? strtotime((string)$product['discount_ends_at'] . ' UTC') : false;
        $matches = $scope === 'all'
            || (str_starts_with($scope, 'size:') && substr($scope, 5) === $customizations['size'])
            || (str_starts_with($scope, 'brand:') && substr($scope, 6) === $customizations['drink_brand']);
        $appliedDiscount = $discount > 0 && $matches
            && !($endsAt !== false && $now >= $endsAt)
            ? $discount
            : 0.0;
        $unitPrice = $appliedDiscount > 0
            ? (int)round($listPrice * (100 - $appliedDiscount) / 100)
            : $listPrice;
        return [
            'original_unit_price' => $listPrice,
            'sale_discount_percent' => $appliedDiscount,
            'sale_discount_amount' => $listPrice - $unitPrice,
            'unit_price' => $unitPrice,
        ];
    }

    private static function productFields(PDO $db, string $alias = '', bool $includeStock = false): string
    {
        $prefix = $alias === '' ? '' : $alias . '.';
        $fields = ['id', 'name', 'description', 'price', 'discount_percent', 'discount_scope', 'image_url', 'category', 'rating', 'review_count'];
        if ($includeStock) $fields[] = 'stock_quantity';
        $fields[] = 'is_available';
        $fields[] = 'created_at';
        $selected = array_map(static fn(string $field): string => $prefix . $field, $fields);
        foreach (['image_urls_json', 'discount_starts_at', 'discount_ends_at'] as $optional) {
            $selected[] = self::hasColumn($db, 'products', $optional)
                ? $prefix . $optional
                : 'NULL AS ' . $optional;
        }
        return implode(', ', $selected);
    }

    private static function discountFields(PDO $db, string $alias = ''): string
    {
        $prefix = $alias === '' ? '' : $alias . '.';
        $fields = [];
        foreach (['discount_starts_at', 'discount_ends_at'] as $column) {
            $fields[] = self::hasColumn($db, 'products', $column)
                ? $prefix . $column
                : 'NULL AS ' . $column;
        }
        return implode(', ', $fields);
    }

    private static function hasColumn(PDO $db, string $table, string $column): bool
    {
        $key = $table . '.' . $column;
        if (array_key_exists($key, self::$columnCache)) return self::$columnCache[$key];
        $query = $db->prepare('SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1');
        $query->execute([$table, $column]);
        return self::$columnCache[$key] = (bool)$query->fetchColumn();
    }

    private static function normalizeCustomizations(mixed $customizations): array
    {
        if (!is_array($customizations) || array_diff(array_keys($customizations), ['size', 'toppings', 'drink_brand']) !== []) {
            throw new ApiException(422, 'One of the product customizations is invalid.');
        }
        $size = $customizations['size'] ?? 'Regular';
        $toppings = $customizations['toppings'] ?? [];
        $drinkBrand = $customizations['drink_brand'] ?? null;
        $allowedToppings = ['Extra cheese', 'Crispy bacon'];
        $allowedDrinkBrands = ['Coca-Cola', 'Sprite', 'Pepsi', 'Royal', 'Mountain Dew', '7Up'];
        if (!is_string($size) || !in_array($size, ['Regular', 'Small', 'Medium', 'Large', 'Double', 'XL'], true) || !is_array($toppings) || !array_is_list($toppings) ||
            count(array_filter($toppings, static fn($topping): bool => is_string($topping) && in_array($topping, $allowedToppings, true))) !== count($toppings) ||
            count(array_unique($toppings)) !== count($toppings) ||
            ($drinkBrand !== null && (!is_string($drinkBrand) || !in_array($drinkBrand, $allowedDrinkBrands, true)))) {
            throw new ApiException(422, 'One of the product customizations is invalid.');
        }
        sort($toppings, SORT_STRING);
        return ['size' => $size, 'toppings' => $toppings, 'drink_brand' => $drinkBrand];
    }

    private static function validateProductCustomizations(string $name, string $category, array $customizations): void
    {
        $category = strtolower(trim($category));
        $isBurger = $category === 'burgers';
        $isFries = $category === 'fries' || ($category === 'sides' && str_contains(strtolower($name), 'fries'));
        $isDrink = $category === 'drinks';

        if ($isBurger) {
            $valid = in_array($customizations['size'], ['Regular', 'Large', 'Double'], true) &&
                $customizations['drink_brand'] === null;
        } elseif ($isFries) {
            $valid = in_array($customizations['size'], ['Regular', 'Small', 'Medium', 'Large'], true) &&
                $customizations['toppings'] === [] && $customizations['drink_brand'] === null;
        } elseif ($isDrink) {
            $valid = in_array($customizations['size'], ['Regular', 'Large', 'XL'], true) &&
                $customizations['toppings'] === [];
        } else {
            $valid = $customizations['size'] === 'Regular' && $customizations['toppings'] === [] &&
                $customizations['drink_brand'] === null;
        }

        if (!$valid) throw new ApiException(422, 'Those options are not available for this product.');
    }

    private static function customizedUnitPrice(string $basePrice, string $category, array $customizations, string $name): int
    {
        $unitPrice = self::moneyCents($basePrice);
        $category = strtolower(trim($category));
        if ($category === 'drinks') {
            return match ($customizations['size']) {
                'Regular' => 15000,
                'Large' => 17000,
                'XL' => 18000,
                default => $unitPrice,
            };
        }
        $isFries = $category === 'fries' ||
            ($category === 'sides' && str_contains(strtolower($name), 'fries'));
        if ($isFries) {
            return match ($customizations['size']) {
                'Small' => 17000,
                'Medium' => 18000,
                'Large' => 19000,
                default => $unitPrice,
            };
        }
        if ($category !== 'burgers') return $unitPrice;
        $unitPrice += match ($customizations['size']) {
            'Large' => 8000,
            'Double' => 12000,
            default => 0,
        };
        foreach ($customizations['toppings'] as $topping) $unitPrice += $topping === 'Extra cheese' ? 2500 : 4500;
        return $unitPrice;
    }

    private static function customizedProductName(string $name, string $category, array $customizations): string
    {
        $category = strtolower(trim($category));
        $isFries = $category === 'fries' || ($category === 'sides' && str_contains(strtolower($name), 'fries'));
        if ($category === 'drinks' && $customizations['drink_brand'] !== null) {
            $size = $customizations['size'] === 'Regular' ? '' : ' ' . $customizations['size'];
            return $customizations['drink_brand'] . $size;
        }
        if ($category !== 'burgers' && !$isFries) return $name;
        $showSize = $customizations['size'] !== 'Regular';
        return ($showSize ? $customizations['size'] . ' ' : '') .
            $name . ($customizations['toppings'] === [] ? '' : ' + ' . implode(', ', $customizations['toppings']));
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
        $redisAttempts = RedisRateLimiter::increment('burgerbites:auth:' . $action . ':' . $hash . ':' . $window, $seconds);
        if ($redisAttempts !== null) {
            if ($redisAttempts > $limit) throw new ApiException(429, 'Too many attempts. Wait a little and try again.');
            return;
        }

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
