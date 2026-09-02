# Worker Gig BD — Android App (Flutter WebView wrapper)

This app is a **full-screen WebView wrapper** around the live website
<https://www.workergigbd.site>. It was a deliberate product decision: the
website is the single source of truth, so the app renders it directly.
Every feature (login, dashboard, jobs, proofs, deposits, withdrawals, admin
panel) works identically in the app with **zero duplicated code** — when the
website updates, the app updates instantly with no new release.

- Package ID: `com.workergigbd.app`
- Entry point: `lib/main.dart`
- Plugin: `webview_flutter` (official), `url_launcher`

## How it behaves

- The site and its Supabase backend (`*.supabase.co`) load **inside** the app.
- Everything else (WhatsApp, tel:, mailto:, Facebook, Google sign-in, ...)
  opens in the device's **external browser/app**.
- Android back button goes back in web history before closing the app.
- A thin progress bar shows page loads; a Bengali offline screen with a
  retry button appears if the connection drops.

## Known limitation: Google sign-in

Google **blocks OAuth inside embedded WebViews by policy**
(`disallowed_useragent`). The app therefore opens the Google sign-in flow in
the system browser. After signing in there, the user is logged in on the
browser; returning to the app, they can use email/password login, or you can
later add a deep link (`workergigbd://auth/callback`) plus a matching
redirect URL in Supabase to hand the session back to the app.

If most of your users sign up with Google only, consider enabling
email/password or phone OTP as a fallback in Supabase Auth settings.

## Build

```bash
flutter pub get
flutter analyze          # must print "No issues found!"
flutter build apk --release          # debug-signed if no keystore
flutter build appbundle --release    # .aab for Play Store
```

Before uploading to Play Store:

1. **Create a signing keystore** (one-time, keep the file and passwords SAFE —
   losing it means you can never update the app):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   (or let Play Console "Play App Signing" manage it — recommended)
2. Add `android/key.properties` (keep it gitignored — it holds passwords):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/upload-keystore.jks
   ```
   and wire it into the `signingConfigs` in `android/app/build.gradle.kts`.
3. **Replace the app icon**: easiest via the `flutter_launcher_icons` package.
4. Bump `version:` in `pubspec.yaml` for every release.

## iOS / other stores

The project was created with `--platforms android,ios`. For iOS you need a
Mac with Xcode (`flutter build ipa`). The same wrapper approach also works
as a PWA or with one codebase for desktop via Flutter, but Play Store +
App Store only need the Android `.aab` and the iOS build.
