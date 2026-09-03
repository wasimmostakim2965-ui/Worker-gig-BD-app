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

Every push to `main` runs `.github/workflows/build.yml` which:

1. Rebuilds the signing keystore from GitHub Secrets
   (`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`,
   `KEY_ALIAS`) — no keystore or password lives in the repo.
2. Builds a signed universal APK + signed AAB.
3. Publishes both to the rolling **`latest` GitHub Release** as
   `Worker-Gig-BD-vX.Y.Z.apk` / `.aab` — direct download, no ZIP.

Download from: repo → **Releases** (Actions artifacts also exist, but
GitHub always zips those).

## Play Store upload

Release builds are signed with the production keystore held in GitHub
Secrets (rotated Sep 2026 after the old key leaked in the public repo —
old installs must be uninstalled before installing the new APK). The
SHA-1/SHA-256 fingerprints of the new key are documented in README.md.
The launcher icon is the real WORKER GIG BD logo (generated with
flutter_launcher_icons).

- Upload `app-release.aab` to Play Console; keep Play App Signing enabled.
- Bump `version:` in `pubspec.yaml` for every release.

## iOS

The project includes the `ios/` platform. Building an `.ipa` requires a
Mac with Xcode: `flutter build ipa`.
