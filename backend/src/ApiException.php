<?php
declare(strict_types=1);

namespace BurgerBites\Api;

final class ApiException extends \RuntimeException
{
    public function __construct(public readonly int $status, string $message)
    {
        parent::__construct($message);
    }
}
