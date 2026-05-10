# QMarket Mobile Client

Flutter mobile shopping app for QMarket customers. The app connects to the
QMarket API for registration, login, product browsing, cart, checkout, order
tracking, address management, reviews, and push notifications.

## Role in the System

QMarket is split into three main projects:

| Project | Role |
| --- | --- |
| `ecommerce_api` | Node.js/Express + MongoDB backend. Handles auth, catalog, cart, orders, coupons, payments, reviews, Cloudinary, OneSignal, and monitoring. |
| `ecommerce_admin` | Flutter web dashboard for admins and superadmins. Manages products, stock, coupons, posters, orders, and notifications. |
| `ecommerce_client` | Flutter mobile shopping app for customers. Displays API data and provides the customer purchase flow. |

Main flow:

```txt
Client App ---> QMarket API ---> MongoDB / Stripe / Cloudinary / OneSignal
Admin Web  ---> QMarket API ---> MongoDB / Stripe / Cloudinary / OneSignal
```

The admin app creates and maintains operational data; the mobile client uses
that data for the customer shopping experience. The API is the source of truth
for auth, pricing, stock, coupons, orders, payments, and reviews.

## Live Services

- API: https://api.levanquang.com/
- Storefront/admin domain: https://shop.levanquang.com/
- Privacy policy: https://policy.levanquang.com/
- Mobile app: Flutter Android/iOS, store release in progress

## Features

- Registration, email verification, login, token refresh, and logout.
- Local/secure token storage for authenticated sessions.
- Product, category, sub-category, brand, and poster browsing.
- Product details with variants/SKUs, pricing, offer pricing, stock, and images.
- Favorite products.
- Variant-aware cart with quantity, price snapshots, and API stock validation.
- COD checkout and Stripe prepaid checkout.
- Order history and order tracking.
- Shipping address management.
- Product reviews for eligible purchased products.
- Privacy policy link from the profile area.
- OneSignal push notifications.
- Sentry crash/error reporting for production builds.

## Tech Stack

- Flutter Android/iOS
- GetX
- Provider
- GetStorage and Flutter Secure Storage
- Flutter Stripe
- OneSignal Flutter
- Sentry Flutter
- HTTP client for QMarket API calls

## Environment Configuration

Production builds read Dart defines from:

```txt
config/dart_defines/prod.local.json
```

Create the local file from the example:

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

The default `MAIN_URL` in source points to:

```txt
https://api.levanquang.com
```

The OneSignal App ID is defined in `lib/utility/constants.dart`.

## Installation

Requirements:

- Flutter SDK
- Android Studio or Android SDK command-line tools
- Java/Gradle toolchain compatible with the current Flutter Android setup
- A running local or production API

Check Flutter:

```powershell
flutter doctor
```

Install dependencies:

```powershell
flutter pub get
```

## Run Locally

Run the app with the configured Dart defines file:

```powershell
flutter run --dart-define-from-file=config/dart_defines/prod.local.json
```

Choose a specific device:

```powershell
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/dart_defines/prod.local.json
```

If testing against a local API, set `MAIN_URL` in `prod.local.json` to an address
that the emulator or physical device can reach. For the Android emulator, use
`http://10.0.2.2:3000` instead of `localhost`.

## API Notes

The mobile client primarily uses these endpoint groups:

- `/users/register`, `/users/verify-email`, `/users/login`
- `/users/refresh-token`, `/users/logout`, `/users/me`
- `/categories`, `/subCategories`, `/brands`, `/products`, `/posters`
- `/cart`
- `/couponCodes/check-coupon`
- `/orders`
- `/payment/stripe`
- `/reviews/product/:productId`

Email verification, pricing, coupon calculation, stock validation, Stripe
PaymentIntent creation, and payment status updates are handled by the backend.

Check the production API:

```txt
https://api.levanquang.com/health
```

Expected response:

```json
{
  "success": true,
  "service": "store_api",
  "status": "ok",
  "environment": "production"
}
```

## Build Android Production

Use the helper script:

```powershell
.\scripts\build_android_prod.ps1
```

Default output:

```txt
build\app\outputs\bundle\release\app-release.aab
```

Build an APK instead:

```powershell
.\scripts\build_android_prod.ps1 -Target apk
```

The script:

- Requires `config/dart_defines/prod.local.json`.
- Builds release with `--dart-define-from-file`.
- Targets Android ARM/ARM64 by default for production Play Store bundles.
- Writes split debug info to `build/sentry-debug-info`.
- Uploads Sentry debug files when Sentry upload configuration is available.

## Sentry Debug Upload

Sentry upload configuration is read from:

```txt
config/sentry/prod.local.properties
```

Create it from the example:

```powershell
Copy-Item config/sentry/prod.example.properties config/sentry/prod.local.properties
```

Required values:

```properties
SENTRY_AUTH_TOKEN=...
SENTRY_ORG=...
SENTRY_PROJECT=...
```

If these values are missing, the app still builds; the script only skips the
debug-file upload step.

## Checks

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

## Release Checklist

1. Confirm `MAIN_URL` points to `https://api.levanquang.com`.
2. Confirm API `/health` returns `success: true` and `status: "ok"`.
3. Run `flutter test` or the focused checks required for the release.
4. Run `.\scripts\build_android_prod.ps1`.
5. Upload `build\app\outputs\bundle\release\app-release.aab` to Google Play Console.
6. Confirm Sentry release/debug symbols if debug upload is enabled.

## Security Notes

- Do not commit local files containing DSNs, tokens, or secrets.
- Do not calculate pricing, coupons, or stock on the client; trust the API response.
- Stripe secret keys must stay on the backend. The client only uses the publishable key and PaymentIntent data returned by the API.

## Author

Le Van Quang

- Email: levanquang27122005@gmail.com
- API: https://api.levanquang.com/
- Storefront/Admin: https://shop.levanquang.com/
- Privacy Policy: https://policy.levanquang.com/
