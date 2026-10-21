<?php
declare(strict_types=1);

foreach ([
    __DIR__ . '/src/ApiException.php',
    __DIR__ . '/src/Database.php',
    __DIR__ . '/src/Http.php',
    __DIR__ . '/src/Auth.php',
    __DIR__ . '/src/RedisRateLimiter.php',
    __DIR__ . '/src/ApiApplication.php',
] as $sourceFile) {
    require_once $sourceFile;
}

$envPath = __DIR__ . '/.env';
if (is_file($envPath) && is_readable($envPath)) {
    foreach (file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$name, $value] = explode('=', $line, 2);
        $name = trim($name); $value = trim($value);
        if (getenv($name) === false) {
            $value = trim($value, " \t\n\r\0\x0B\"'");
            putenv($name . '=' . $value);
            $_ENV[$name] = $value;
        }
    }
}
