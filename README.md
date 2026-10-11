# Sakk (صك)

A Flutter app for tracking purchases, warranties, returns and receipts. Available in English and Arabic, on Android and iOS.

## Features

- **Products** — record purchases with their receipts, warranty and return windows; export to CSV.
- **Receipt scanning** — extract purchase details from a photo or PDF of a receipt.
- **AI chat** — ask questions about your purchases.
- **Households** — share products with other people.
- **Reminders** — local notifications and calendar events before warranties and return windows end.
- **Home screen widget** — upcoming warranty expiries at a glance.
- **Analytics** — spending and warranty overview.
- **Sign-in** — email/password or Google, with optional biometric lock.

## Tech stack

| Area | Library |
|---|---|
| State | `flutter_bloc` (Cubits) |
| Navigation | `go_router` |
| Dependency injection | `get_it` |
| Errors | `dartz` `Either` with `Failure` types |
| Backend | Supabase (auth, database, storage, edge functions) |
| Crash reporting | Firebase Crashlytics |
| Localization | `flutter_localizations` + ARB files in `lib/l10n` |

## Project structure

```
lib/
  core/        shared services, DI, routing, theme, widgets, errors, logging
  features/    one folder per feature, split into data / domain / presentation
  l10n/        ARB translation files and generated localizations
supabase/
  migrations/  database schema
  functions/   edge functions: ai-chat, extract-receipt, delete-account
```

## Getting started

### Requirements

- Flutter with Dart `^3.11.5`
- Java 17 or 21 for Android builds. Gradle 8.14 does not run on Java 25; if that is your default, use Android Studio's bundled JDK:
  ```
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  ```
- Xcode and CocoaPods for iOS

### Environment

Create a `.env` file in the project root (it is git-ignored and bundled as an asset):

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GOOGLE_WEB_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=
SENTRY_DSN=
```

### Run

```
flutter pub get
flutter run
```

Translations are generated from `lib/l10n/*.arb` automatically on build.

## Google sign-in

The app signs in with Google's ID token and passes it to Supabase.

- `GOOGLE_WEB_CLIENT_ID` is the **Web** OAuth client. It is used as `serverClientId` on both platforms and must be added to Supabase's Google provider.
- `GOOGLE_IOS_CLIENT_ID` is the iOS OAuth client for bundle ID `com.sakk.app`.
- **Android** needs an Android OAuth client for package `com.sakk.app` in the same Google Cloud project — one per signing key (debug, upload, and Play App Signing). Without it, choosing an account does nothing: Credential Manager reports the error as a cancellation, which the app logs as `Google sign-in cancelled`.

To print the debug and upload key SHA-1s:

```
cd android && ./gradlew signingReport
```

The Play App Signing SHA-1 is in Play Console → Setup → App integrity.

## Release builds (Android)

Release signing reads `android/key.properties` (git-ignored):

```
storePassword=
keyPassword=
keyAlias=upload
storeFile=/path/to/sakk-upload.jks
```

Without it, release builds fall back to the debug key.

## Supabase

Apply the schema from `supabase/migrations` and deploy the edge functions with the Supabase CLI:

```
supabase db push
supabase functions deploy ai-chat
supabase functions deploy extract-receipt
supabase functions deploy delete-account
```

The AI functions need a `GROQ_API_KEY` secret:

```
supabase secrets set GROQ_API_KEY=...
```
