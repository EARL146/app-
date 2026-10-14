<?php
declare(strict_types=1);

namespace BurgerBites\Api;

use PDO;

final class Database
{
    public static function connect(): PDO
    {
        $dsn = getenv('DB_DSN') ?: '';
        $username = getenv('DB_USERNAME') ?: '';
        $password = getenv('DB_PASSWORD') ?: '';
        if ($dsn === '' || $username === '') {
            throw new ApiException(503, 'The API database is not configured yet.');
        }

        return new PDO($dsn, $username, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_STRINGIFY_FETCHES => false,
        ]);
    }
}
