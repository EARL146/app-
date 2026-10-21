# Local Docker and Redis workflow

The optional Docker stack runs a separate PHP API, MySQL database, and Redis rate-limit store. It is for local development and does not replace the existing AMPPS services or its `burger_bites` database.

## What runs

- PHP 8.2 API container with PDO MySQL and the Redis PHP extension.
- MySQL 8.4 in the named `burger-bites-docker-mysql-data` volume, using the separate `burger_bites_docker` database by default.
- Redis 7 for shared, expiring registration/login/password rate-limit counters. Redis is not published to the host and has a 64 MB cap; if it is unavailable, the API uses the existing MySQL rate-limit table.
- Only the API and MySQL ports are published, and both bind to `127.0.0.1`. Redis has no host port and is reachable only by Compose services.
- Migrations `001` and `003` are mounted as first-initialization scripts for this new database. Optional sample catalog migration `002` is intentionally omitted; no products are fabricated. The scripts run only when the named MySQL volume is first initialized.

## Start from PowerShell

From the BurgerBites project root:

```powershell
if (-not (Test-Path docker/.env)) {
    Copy-Item docker/dev.env.example docker/.env
}
notepad docker/.env
```

On first setup, replace both database password placeholders with different random passwords and set `APP_TOKEN_PEPPER` to at least 32 random bytes. Keep `docker/.env` private; Git ignores it. The guard above prevents an existing local secret file from being overwritten. Then start the stack:

```powershell
docker compose --env-file docker/.env up -d --build
docker compose --env-file docker/.env ps
```

The API is available at `http://127.0.0.1:8082/api/v1`. Run Flutter Web against it with:

```powershell
flutter run -d edge --web-port=5000 --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8082/api/v1
```

The Docker MySQL port is `127.0.0.1:3307` for a local database client. Configure a separate phpMyAdmin server connection if needed; the existing AMPPS MySQL on port 3306 is not changed. The local API server on port 8081 can keep running alongside this stack.

Useful non-destructive commands:

```powershell
docker compose --env-file docker/.env logs --tail=100 api db redis
docker compose --env-file docker/.env exec api php -m
docker compose --env-file docker/.env down
```

The PHP module list should include `pdo_mysql`, `mbstring`, and `redis`. `down` stops/removes the containers and network but keeps the named database volume. Do not use `down -v` for ordinary shutdown: it deletes the Docker database. No command here imports migration `002` or modifies the AMPPS database, so the catalog is empty until products are added to this Docker database. The existing administrator helper targets the AMPPS `.env`; a container-aware secure admin provisioning flow is not included yet.

This container-only setup does not make the app production-ready. Use HTTPS, production secrets, backups, and a deployment-specific network before hosting publicly.
