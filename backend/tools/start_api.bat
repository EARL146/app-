@echo off
title BurgerBites API Server (Port 8081)
cd /d "%~dp0\.."
echo Starting BurgerBites PHP API on http://127.0.0.1:8081 ...
if exist "D:\Ampps\php\php.exe" (
    "D:\Ampps\php\php.exe" -S 127.0.0.1:8081 -t public public/index.php
) else (
    php -S 127.0.0.1:8081 -t public public/index.php
)
pause
