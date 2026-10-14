# BurgerBites PHP API — local development

This PHP 8.2 API implements the Flutter client's auth, profile, products, favorites, and COD order contract. It is configured for the AMPPS MySQL database `burger_bites` (shown as `Burger_Bites` in the user's phpMyAdmin view). The user confirmed it was empty; the initial schema was then applied without inserting application data. The unrelated `streetfood_db` database was not touched.

The API uses PDO prepared statements, Argon2id password hashes, opaque random access/refresh tokens stored only as HMAC hashes, 15-minute access/30-day refresh expiry with rotation, rate-limit counters, server-derived user roles, and a transaction for order/stock changes. The admin product/order/customer API is not implemented.

## 1. Database status and schema

Start MySQL from AMPPS. Select the existing `Burger_Bites` database in phpMyAdmin. It was confirmed empty before the schema was applied. The MySQL server normalizes its name to `burger_bites` on this Windows setup.

Import these files in order from phpMyAdmin's **Import** tab:

1. `backend/database/migrations/001_initial_schema.sql` creates the seven core tables. This was applied to the empty database during setup.
2. Optional local sample catalog only: `backend/database/migrations/002_development_catalog.sql`. It has not been imported.

For production, use verified product names, prices, images, and stock rather than the sample rows.

The local `burger_bites_app` account has only `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on `burger_bites.*`. The PHP API reads `backend/.env`, which is ignored by Git. Do not use the MySQL root account in the app configuration.

## 2. Configure secrets

The local `backend/.env` has already been configured with generated secrets. Do not paste its contents into chat or documentation. For a fresh setup, copy the template and set a new database password and token pepper:

```powershell
Copy-Item .env.example .env
notepad .env
```

Set `DB_USERNAME` and `DB_PASSWORD` to the dedicated database user. Keep `.env` out of Git and do not paste its secrets into chat or Obsidian.

Generate a token pepper in PowerShell:

```powershell
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Copy the output into `APP_TOKEN_PEPPER` in `backend/.env`. Set the local CORS origin to the Flutter Web origin you use, such as `http://localhost:5000`. For Android, CORS is not used.

## 3. Create an administrator

There is no default admin account or password. After the database and API config are ready, run this from the project root; it prompts twice for a hidden password and refuses to overwrite an existing email:

```powershell
.\backend\tools\create_admin.ps1 -Email 'admin@example.com' -FullName 'BurgerBites Admin'
```

Sign into the app with that email and the password entered at the secure prompt. The script stores only an Argon2id hash. Do not create admin accounts through public registration.

## 4. Start the API

From the `backend` directory:

```powershell
php -S 127.0.0.1:8081 -t public public/index.php
```

The API root is `http://127.0.0.1:8081/api/v1`. Port `8080` is occupied by Tomcat on this computer. For a physical Android device on the same trusted Wi-Fi, bind to `0.0.0.0` and use the computer's LAN IP; limit the firewall rule to the private network and remove it after development.

## 5. Run Flutter against it

For Edge, set the Web port so the CORS origin is stable. Add `http://localhost:5000` to `APP_ALLOWED_ORIGINS` in `backend/.env`:

```powershell
flutter run -d edge --web-port=5000 --dart-define=BURGER_BITES_API_BASE_URL=http://127.0.0.1:8081/api/v1
```

For Android Emulator, use the host loopback alias:

```powershell
flutter run -d <device-id> --dart-define=BURGER_BITES_API_BASE_URL=http://10.0.2.2:8081/api/v1
```

The Android manifest permits cleartext HTTP only for debug builds. Release builds reject non-HTTPS API URLs. Never expose the local development API to the public internet.

## Limitations

The PHP API can connect to the local MySQL database through its restricted app account. The initial schema is installed; sample products have not been inserted. Admin management endpoints, order-history endpoint, and production deployment are not implemented. Several Flutter menu/search/order-history/admin features still use preview data. See `../docs/API_SPEC.md`, `../docs/SECURITY.md`, and `../docs/TESTING.md`.
