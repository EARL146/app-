# Setup Guide

[[PROJECT_HOME]] · [[TESTING]] · [[KNOWN_ISSUES]] · [[NEXT_SESSION]]

## Contents

- [Windows / Flutter Web](#windows--flutter-web)
- [Android emulator or device](#android-emulator-or-device)
- [AMPPS / PHP / MySQL](#ampps--php--mysql)
- [Obsidian](#obsidian)

## Windows / Flutter Web

Open PowerShell in:

```powershell
Set-Location 'C:\Users\shizu\OneDrive\Documents\Ampps\www\Burger_bites'
```

Check the tools and available disk space:

```powershell
flutter --version
dart --version
Get-PSDrive C | Select-Object Name,@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
```

Then fetch dependencies and run in Edge:

```powershell
flutter pub get
flutter run -d edge
```

Recent user output showed `flutter pub get` succeeded, but Edge compilation ran out of C: disk space while writing a Dart artifact. Free several GB before retrying. Do not delete application source or the Pub cache as the first response to a disk-space error. See [[KNOWN_ISSUES]].

## Android emulator or device

Install Flutter/Android Studio and configure an Android SDK, then use:

```powershell
flutter doctor
flutter emulators
flutter devices
flutter run -d <device-id>
```

No Android device/emulator run was verified for this documentation update. A debug APK build previously failed during generated asset cleanup; see [[TESTING]].

## AMPPS / PHP / MySQL

The `Burger_bites` tree contains no PHP API, SQL schema, migration, or database configuration. Therefore this Flutter project alone cannot start or configure the AMPPS backend. If the backend is a separate folder under AMPPS, keep it in place and record its exact path and safe schema export before documenting endpoints/database setup. Do not put DB passwords in the vault or Flutter app. See [[API_SPEC]] and [[DATABASE_SCHEMA]].

## Obsidian

1. Select the `Burger_bites` vault from Obsidian's vault list; it has been registered there.
2. Open `docs/PROJECT_HOME.md` from the file explorer and pin it if desired.
3. If the vault is not listed, select **Open folder as vault** and choose the project root.
4. New notes default to `docs/` via `.obsidian/app.json`.

The existing unrelated Obsidian vaults were left unchanged. [[PROJECT_HOME]] is the BurgerBites vault entry point.
