# Worker Gig BD — Android App (native Flutter)

A **real native Flutter app** that talks directly to the same Supabase
backend as https://www.workergigbd.site. No WebView — every screen is a
native Flutter screen calling the exact same tables, RPCs and RLS rules
as the website, so web and app always behave identically.

- Package ID: `com.workergigbd.app`
- Entry point: `lib/main.dart`
- State: `provider` (`AuthService` mirrors the web `AuthContext`)

## Screens (mirrors of the website pages)

| Website | App |
|---|---|
| LandingPage | `screens/landing_screen.dart` |
| LoginPage / SignupPage | `screens/auth/login_screen.dart`, `signup_screen.dart` |
| AdminGatePage | `screens/auth/admin_login_screen.dart` |
| DashboardLayout | `screens/dashboard/dashboard_shell.dart` (bottom nav) |
| DashboardHome (Find Jobs) | `screens/dashboard/home_screen.dart` |
| Job detail + proof submit | `screens/dashboard/job_detail_screen.dart` |
| MyTasksPage | `screens/dashboard/my_tasks_screen.dart` |
| MyJobsPage + buyer review | `screens/dashboard/my_jobs_screen.dart` |
| PostJobPage | `screens/dashboard/post_job_screen.dart` |
| DepositPage | `screens/dashboard/deposit_screen.dart` |
| WithdrawPage | `screens/dashboard/withdraw_screen.dart` |
| NotificationsPage | `screens/dashboard/notifications_screen.dart` |
| ProfilePage | `screens/dashboard/profile_screen.dart` |
| ShareEarnPage | `screens/dashboard/share_earn_screen.dart` |
| Admin* (stats, users, deposits, withdrawals, jobs, tasks) | `screens/admin/*` |

## Server-side features the app reuses (no new backend work)

- All money moves go through the same SECURITY DEFINER RPCs
  (`post_job`, `request_withdrawal`, `process_task`, `process_deposit`,
  `process_withdrawal_request`, `adjust_user_balance`, ...).
- Proof screenshots are uploaded to the `job-assets` Supabase bucket and
  pass through the **same SHA-256 fraud registry** as the website
  (`services/proof_upload.dart`) — a screenshot already used by anyone is
  rejected with HTTP 409.
- The `require_task_proof` DB trigger, balance guard trigger and RLS
  policies apply to the app exactly as they do to the web.

## REQUIRED one-time setup: Google sign-in redirect URL

Google OAuth in the app returns via a deep link. Add this to
**Supabase Dashboard → Authentication → Sign In / Up → Redirect URLs**:

```
com.workergigbd.app://login-callback/
```

(It is already declared as an intent-filter in
`android/app/src/main/AndroidManifest.xml`.)

## Build (GitHub Actions — no local setup needed)

Every push to `main` runs `.github/workflows/build.yml` which produces:

- `app-release-apk` — installable test APK
- `app-release-aab` — Play Store upload format

Download from: repo → Actions → latest successful run → Artifacts.

## Before Play Store upload

1. Create an upload keystore (one-time; keep it SAFE) or enable
   "Play App Signing" in Play Console (recommended):
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Add `android/key.properties` (gitignored) and wire it into
   `android/app/build.gradle.kts` signing configs.
3. Replace the default launcher icon (use `flutter_launcher_icons`).
4. Bump `version:` in `pubspec.yaml` for every release.

## iOS

The project includes the `ios/` platform. Building an `.ipa` requires a
Mac with Xcode: `flutter build ipa`.
