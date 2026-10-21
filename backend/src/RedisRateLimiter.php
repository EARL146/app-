<?php
declare(strict_types=1);

namespace BurgerBites\Api;

use Redis;
use Throwable;

final class RedisRateLimiter
{
    private static ?Redis $connection = null;
    private static bool $failureLogged = false;

    public static function increment(string $key, int $ttlSeconds): ?int
    {
        $host = getenv('REDIS_HOST') ?: '';
        if ($host === '' || !class_exists(Redis::class)) return null;

        try {
            $redis = self::$connection;
            if ($redis === null) {
                $redis = new Redis();
                $port = filter_var(getenv('REDIS_PORT') ?: '6379', FILTER_VALIDATE_INT);
                $timeout = filter_var(getenv('REDIS_CONNECT_TIMEOUT') ?: '0.25', FILTER_VALIDATE_FLOAT);
                if ($port === false || $port < 1 || $port > 65535 || $timeout === false || $timeout <= 0) {
                    self::logUnavailable('invalid_configuration');
                    return null;
                }
                if (!$redis->connect($host, $port, $timeout)) {
                    self::logUnavailable('connection_failed');
                    return null;
                }
                $redis->setOption(Redis::OPT_READ_TIMEOUT, $timeout);
                self::$connection = $redis;
            }

            $count = $redis->eval(
                'local count = redis.call("INCR", KEYS[1]); if count == 1 then redis.call("EXPIRE", KEYS[1], ARGV[1]); end; return count;',
                [$key, $ttlSeconds],
                1,
            );
            if (is_int($count) || (is_string($count) && ctype_digit($count))) {
                self::$failureLogged = false;
                return (int)$count;
            }
            self::$connection = null;
            self::logUnavailable('invalid_response');
        } catch (Throwable) {
            self::$connection = null;
            self::logUnavailable('request_failed');
        }

        return null;
    }

    private static function logUnavailable(string $reason): void
    {
        if (self::$failureLogged) return;
        self::$failureLogged = true;
        error_log(json_encode([
            'event' => 'burger_bites_redis_rate_limit_unavailable',
            'reason' => $reason,
        ], JSON_UNESCAPED_SLASHES));
    }
}
