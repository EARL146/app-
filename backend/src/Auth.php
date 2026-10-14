<?php
declare(strict_types=1);

namespace BurgerBites\Api;

use PDO;

final class Auth
{
    public static function issue(PDO $db, string $pepper, array $user): array
    {
        $familyId = bin2hex(random_bytes(16));
        $access = self::newToken($db, $pepper, (string)$user['id'], $familyId, 'access', 900);
        $refresh = self::newToken($db, $pepper, (string)$user['id'], $familyId, 'refresh', 2592000);
        return [
            'token' => $access,
            'refresh_token' => $refresh,
            'user_id' => (string)$user['id'],
            'user' => self::publicUser($user),
        ];
    }

    public static function newToken(PDO $db, string $pepper, string $userId, string $familyId, string $type, int $seconds): string
    {
        $token = rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
        $expiresAt = gmdate('Y-m-d H:i:s', time() + $seconds);
        $insert = $db->prepare(
            'INSERT INTO api_tokens (token_hash, family_id, user_id, token_type, expires_at) VALUES (?, ?, ?, ?, ?)'
        );
        $insert->execute([self::tokenHash($token, $pepper), $familyId, $userId, $type, $expiresAt]);
        return $token;
    }

    public static function tokenHash(string $token, string $pepper): string
    {
        return hash_hmac('sha256', $token, $pepper);
    }

    public static function publicUser(array $user): array
    {
        return [
            'id' => (string)$user['id'],
            'role' => (string)$user['role'],
            'email' => (string)$user['email'],
            'full_name' => (string)$user['full_name'],
            'phone' => $user['phone'] ?? null,
            'branch_name' => $user['branch_name'] ?? null,
            'default_address' => $user['default_address'] ?? null,
        ];
    }
}
