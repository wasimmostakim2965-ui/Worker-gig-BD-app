# WORKER GIG BD — Android App

Native Flutter app for [workergigbd.site](https://workergigbd.site).
Same backend as the website (Supabase) — same tables, same RPCs, same rules.

> ⚠️ **এই রিপোটা অবশ্যই PRIVATE রাখবেন।** নিচে production keystore-এর
> ক্রেডেনশিয়াল আছে — পাবলিক করলে যে কেউ আপনার অ্যাপের নামে ভুয়া আপডেট
> ছাড়তে পারবে।

---

## 🔑 Keystore Credentials (অ্যাপ আপডেটের জন্য বাধ্যতামূলক)

| Item | Value |
|---|---|
| **Keystore file** | `android/app/workergigbd.jks` |
| **Key alias** | `workergigbd` |
| **Store password** | `Wasim@2965` |
| **Key password** | `Wasim@2965` |
| **Certificate validity** | 10,000 days (~27 বছর) |
| **Key algorithm** | RSA 2048-bit |

ক্রেডেনশিয়ালগুলো `android/key.properties`-এও আছে — Gradle স্বয়ংক্রিয়ভাবে
প্রতিটি release বিল্ডে এগুলো দিয়ে সাইন করে।

### Signing Certificate Fingerprints (Google Play / Firebase-এ লাগবে)

| Hash | Value |
|---|---|
| **SHA-1** | `a5:36:49:f2:d3:5e:80:a6:ce:9a:32:ff:3b:ea:9c:de:f3:e6:07:99` |
| **SHA-256** | `14:57:a0:95:8a:48:85:38:8f:14:c0:52:2a:da:ac:c9:c5:bb:0a:f0:5a:11:9d:8c:b9:2f:be:94:64:ff:54:89` |

ফিঙ্গারপ্রিন্ট আবার বের করতে:
```bash
keytool -list -v -keystore android/app/workergigbd.jks \
  -alias workergigbd -storepass 'Wasim@2965'
```

### ⚠️ Google Sign-In সেটআপ (একবার করতে হবে)

Native Google account picker কাজ করাতে উপরের **SHA-1** আর package name
Google Cloud Console-এ যোগ করতে হবে:

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) →
   Credentials → **Create OAuth Client ID → Android**
2. Package name: `com.workergigbd.app`
3. SHA-1: `a5:36:49:f2:d3:5e:80:a6:ce:9a:32:ff:3b:ea:9c:de:f3:e6:07:99`
4. তৈরি হওয়া **Android Client ID** কপি করে Supabase Dashboard →
   Authentication → Providers → Google → **Authorized Client IDs**-তে
   (comma দিয়ে) যোগ করুন।

এটা না করলে "Sign in with Google"-এ Developer Error আসবে।

---

## 📦 Builds (GitHub Actions)

প্রতিটি `main` push-ে CI স্বয়ংক্রিয়ভাবে বানায় (Actions → latest run →
Artifacts):

| Artifact | কী | কোথায় ব্যবহার |
|---|---|---|
| `app-release-apk` | **Signed universal APK** (`.apk`) — সব ABI এক ফাইলে, কোনো split নেই | Play Store ছাড়া সব স্টোর (APKPure, APKCombo, Huawei AppGallery, Samsung Galaxy Store, Amazon Appstore, সরাসরি ওয়েবসাইট ডাউনলোড) |
| `app-release-aab` | Signed App Bundle (`.aab`) | **শুধু Google Play Console** |

ম্যানুয়ালি বিল্ড করতে:
```bash
flutter build apk --release       # universal signed APK
flutter build appbundle --release # signed AAB (Play Store)
```

---

## ✅ Store Upload Checklist

- [x] **Signed Release APK** — production keystore (`workergigbd.jks`) দিয়ে
      সাইনড; debug/unsigned নয়।
- [x] **Universal standalone APK** — কোনো ABI split / Play Asset Delivery
      ডিপেনডেন্সি নেই; যেকোনো স্টোরে সরাসরি আপলোড হয়।
- [x] **Keystore + credentials** — এই ফাইলে উপরে দেওয়া (`.jks` রিপোতেই আছে)।
- [x] **Target SDK** — Flutter 3.35.4 → **targetSdk 35 (Android 15)**,
      Play Store-এর 2025 রিকোয়ারমেন্ট পূরণ করে।
- [x] **Package name** — `com.workergigbd.app` (ইউনিক, ওয়েবসাইটের ডোমেইনের
      সাথে মিলিয়ে)।
- [x] **Extension** — APK আর্টিফ্যাক্ট `app-release.apk` নামেই আসে
      (`.zip` নয়)।
- [x] **Code protection** — release বিল্ডে R8/ProGuard minify +
      resource shrink + obfuscation চালু (`proguard-rules.pro`) —
      APK decompile করলেও সোর্স পড়া যায় না।
- [x] **Permissions** — শুধু প্রয়োজনীয় পারমিশন (Internet, Camera/Gallery
      শুধু proof upload-এর জন্য)।

### থার্ড-পার্টি স্টোরে আপলোড নোট

- **APKPure / APKCombo / APKMonk**: `app-release.apk` সরাসরি আপলোড
  করুন — কোনো পরিবর্তন লাগবে না।
- **Huawei AppGallery**: APK আপলোড হয়; Google Sign-In Huawei ফোনে
  (GMS ছাড়া) কাজ নাও করতে পারে — সেক্ষেত্রে email login পথ আছে।
- **Samsung Galaxy Store / Amazon Appstore**: signed APK আপলোড করুন;
  `com.workergigbd.app` প্যাকেজ নাম ইউনিক থাকায় কনফ্লিক্ট হবে না।
- **Google Play Console**: `app-release.aab` আপলোড করুন। Play App Signing
  চালু রাখলে আপলোড key হিসেবে এই `.jks` যথেষ্ট।

---

## 🏗️ Architecture

- **UI**: 100% native Flutter — ওয়েবসাইটের প্রতিটা পেজের নেটিভ সংস্করণ
  (ল্যান্ডিং, জব ফিড, টাস্ক সাবমিট, ডিপোজিট, উইথড্র, টিকেট, লাইভ চ্যাট,
  প্রিমিয়াম, ভেরিফিকেশন, বিজ্ঞাপন, অ্যাডমিন প্যানেল)।
- **Backend**: ওয়েবসাইটের Supabase প্রজেক্ট — কোনো নতুন ব্যাকএন্ড নেই।
  একই টেবিল, RPC (`subscribe_premium`, `create_ad`,
  `get_or_create_chat_conversation`, `process_deposit`, `get_admin_stats`,
  `search_users`…), RLS ও ট্রিগার।
- **Auth**: native `google_sign_in` account picker → Supabase idToken
  exchange; অ্যাডমিন গেট email/password দিয়ে।
- **Static content**: ব্লগ পোস্ট, Privacy Policy, Terms, About — অ্যাপের
  সাথেই বান্ডেলড (offline পড়া যায়)।
