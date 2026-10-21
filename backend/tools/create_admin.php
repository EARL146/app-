<?php
declare(strict_types=1);

use BurgerBites\Api\Database;

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit(1);
}

require_once __DIR__ . '/../bootstrap.php';

$email = strtolower(trim($argv[1] ?? ''));
$name = trim($argv[2] ?? '');
$password = getenv('ADMIN_BOOTSTRAP_PASSWORD') ?: '';
if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($name) < 2 || mb_strlen($name) > 120) {
    fwrite(STDERR, "Usage: create_admin.php <email> <full-name>\n");
    exit(2);
}
if (!defined('PASSWORD_ARGON2ID')) {
    fwrite(STDERR, "This PHP installation does not support Argon2id password hashing. No admin account was created.\n");
    exit(2);
}
$emailName = explode('@', $email, 2)[0];
$passwordUsesEmail = strlen($emailName) >= 4 && stripos($password, $emailName) !== false;
$commonPasswords = ['password123!', 'password123456', 'qwerty123456', 'letmein123456', '123456789012', 'welcome123456', 'adminadmin123', 'iloveyou12345', 'changeme12345', 'p@ssword12345'];
if (mb_strlen($password) < 12 || mb_strlen($password) > 200 || $passwordUsesEmail || in_array(strtolower($password), $commonPasswords, true)) {
    fwrite(STDERR, "Set a unique ADMIN_BOOTSTRAP_PASSWORD of at least 12 characters using the secure PowerShell helper.\n");
    exit(2);
}

try {
    $db = Database::connect();
    $insert = $db->prepare("INSERT INTO users (role, email, password_hash, full_name) VALUES ('admin', ?, ?, ?)");
    $insert->execute([$email, password_hash($password, PASSWORD_ARGON2ID), $name]);
    fwrite(STDOUT, "Admin account created. Sign in with this email and the password entered in the secure prompt.\n");
} catch (PDOException $error) {
    if ($error->getCode() === '23000') {
        fwrite(STDERR, "That email already belongs to an account; no account was changed.\n");
        exit(3);
    }
    fwrite(STDERR, "Could not create the admin account. Check API database configuration and migration state.\n");
    exit(1);
}
