# QMarket Mobile Client

Flutter mobile shopping app for QMarket. The app talks to the production API at `https://api.levanquang.com`, supports email verification during registration, authenticated shopping flows, cart/checkout, orders, reviews, push notifications, Stripe payments, and Sentry crash reporting.

## Requirements

- Flutter SDK installed and available in `PATH`
- Android Studio or Android SDK command-line tools
- Java/Gradle toolchain compatible with the current Flutter Android setup
- A configured production API

Check the Flutter environment:

```powershell
flutter doctor
```

Install dependencies:

```powershell
flutter pub get
```

## Configuration

Production builds read Dart defines from:

```text
config/dart_defines/prod.local.json
```

Create it from the example file:

```powershell
Copy-Item config/dart_defines/prod.example.json config/dart_defines/prod.local.json
```

Example:

```json
{
  "SENTRY_ENV": "production",
  "SENTRY_DSN": "https://your-public-key@o0000000000000000.ingest.us.sentry.io/0000000000000000",
  "MAIN_URL": "https://api.levanquang.com"
}
```

`prod.local.json` is local/private and should not be committed.

## API Notes

The mobile app uses:

- `POST /users/register` to start signup and request a verification code.
- `POST /users/verify-email` to verify the 6-digit code.
- `POST /users/login` for verified accounts.
- `POST /users/resend-verification-code` to send another code.

Email delivery is handled by the backend, not the Flutter client. In production, the backend should prefer Brevo Transactional API with:

```env
BREVO_API_KEY=xkeysib-...
EMAIL_FROM=QMarket <no-reply@levanquang.com>
```

You can confirm the live API is healthy at:

```text
https://api.levanquang.com/health
```

Expected production health response:

```json
{
  "success": true,
  "service": "store_api",
  "status": "ok",
  "environment": "production"
}
```

## Run Locally

Run against the API configured in your local defines file:

```powershell
flutter run --dart-define-from-file=config/dart_defines/prod.local.json
```

For a specific device:

```powershell
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/dart_defines/prod.local.json
```

## Build Android Production

Use the helper script:

```powershell
.\scripts\build_android_prod.ps1
```

Default output:

```text
build\app\outputs\bundle\release\app-release.aab
```

Build an APK instead:

```powershell
.\scripts\build_android_prod.ps1 -Target apk
```

The script:

- Requires `config/dart_defines/prod.local.json`.
- Builds with `--release`.
- Passes `--dart-define-from-file`.
- Writes split debug info to `build/sentry-debug-info`.
- Uploads Sentry debug files when Sentry upload env vars are configured.

## Sentry Debug Upload

Optional Sentry upload configuration is read from:

```text
config/sentry/prod.local.properties
```

Create it from:

```powershell
Copy-Item config/sentry/prod.example.properties config/sentry/prod.local.properties
```

The upload step needs:

```properties
SENTRY_AUTH_TOKEN=...
SENTRY_ORG=...
SENTRY_PROJECT=...
```

If those values are missing, the app still builds; the script only skips the Sentry debug file upload.

## Useful Checks

Analyze code:

```powershell
flutter analyze
```

Run tests:

```powershell
flutter test
```

Check outdated packages:

```powershell
flutter pub outdated
```

Dependency update warnings during build are informational unless the build fails.

## Release Checklist

1. Confirm `MAIN_URL` in `prod.local.json` points to `https://api.levanquang.com`.
2. Confirm API health returns `success: true` and `status: "ok"`.
3. Run `flutter test` or at least the focused checks you need.
4. Run `.\scripts\build_android_prod.ps1`.
5. Upload `build\app\outputs\bundle\release\app-release.aab` to Google Play Console.
