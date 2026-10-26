<?php
declare(strict_types=1);

namespace BurgerBites\Api;

final class Http
{
    public static function json(array $payload, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
        exit;
    }

    public static function body(): array
    {
        $length = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
        if ($length > 4 * 1024 * 1024) {
            throw new ApiException(413, 'The request is too large.');
        }
        $raw = file_get_contents('php://input');
        if ($raw === false || trim($raw) === '') {
            return [];
        }
        if (strlen($raw) > 4 * 1024 * 1024) {
            throw new ApiException(413, 'The request is too large.');
        }
        try {
            $data = json_decode($raw, true, 32, JSON_THROW_ON_ERROR);
        } catch (\JsonException) {
            throw new ApiException(400, 'Send a valid JSON request.');
        }
        if (!is_array($data) || ($data !== [] && array_is_list($data)) || trim($raw) === '[]') {
            throw new ApiException(400, 'Send a JSON object.');
        }
        return $data;
    }

    public static function method(): string
    {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public static function path(): string
    {
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
        if (!is_string($path)) {
            return '/';
        }
        $scriptDirectory = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/')), '/');
        if ($scriptDirectory !== '' && str_starts_with($path, $scriptDirectory . '/')) {
            $path = substr($path, strlen($scriptDirectory));
        }
        if ($path === '/api/v1') {
            $path = '/';
        } elseif (str_starts_with($path, '/api/v1/')) {
            $path = substr($path, strlen('/api/v1'));
        }
        return '/' . trim($path, '/');
    }

    public static function requireMethod(string $expected): void
    {
        if (self::method() !== $expected) {
            header('Allow: ' . $expected);
            throw new ApiException(405, 'This method is not supported for this route.');
        }
    }

    public static function cors(): void
    {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        $allowed = array_filter(array_map('trim', explode(',', getenv('APP_ALLOWED_ORIGINS') ?: '')));
        if ($origin !== '' && in_array($origin, $allowed, true)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Vary: Origin');
            header('Access-Control-Allow-Headers: Authorization, Content-Type');
            header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        } elseif ($origin !== '') {
            throw new ApiException(403, 'This app origin is not allowed.');
        }
        if (self::method() === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
}
