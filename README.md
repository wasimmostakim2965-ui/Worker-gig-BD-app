# WORKER GIG BD — Android App

Native Flutter app for [workergigbd.site](https://workergigbd.site).
Same backend as the website (Supabase) — same tables, same RPCs, same rules.

> 🔐 **Signing keystore এখন আর রিপোতে নেই** — GitHub Secrets-এ নিরাপদে আছে
> (Settings → Secrets and variables → Actions)। CI সেখান থেকে নিয়ে প্রতিটি
> বিল্ড সাইন করে। keystore ফাইল আর পাসওয়ার্ড অফলাইনে (নিজের কাছে) ব্যাকআপ
> রাখুন — হারালে অ্যাপ আপডেট দেওয়া যাবে না।

---

## 🔑 Signing Setup (সেপ্টেম্বর ২০২৬-এ keystore রোটেট করা হয়েছে)

আগের keystore (`Wasim@2965`) রিপো পাবলিক থাকায় লিক হয়ে গিয়েছিল, তাই
**নতুন keystore** বানানো হয়েছে (RSA 4096-bit, ~৩০ বছর validity)। পুরনো
সার্টিফিকেট দিয়ে সাইনড অ্যাপ আর আপডেট পাবে না — পুরনো ইনস্টল থাকলে
আগে uninstall করে নতুন APK ইনস্টল করতে হবে।

- Keystore: শুধু **GitHub Secrets**-এ (`ANDROID_KEYSTORE_BASE64`,
  `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`) — রিপোতে কোনো
  ক্রেডেনশিয়াল নেই।
- লোকালে সাইনড বিল্ড চাইলে নিজের কাছে থাকা `.jks` রেখে
  `android/key.properties` বানান (`.gitignore`-এ আছে, commit হবে না)।
- `key.properties` না থাকলে release বিল্ড debug key দিয়ে সাইন হয় —
  সেটা শুধু টেস্টের জন্য, স্টোরে দেবেন না।

### Signing Certificate Fingerprints — নতুন keystore (Google Play / Firebase-এ লাগবে)

| Hash | Value |
|---|---|
| **SHA-1** | `A0:D1:AA:C2:9E:64:83:8F:6E:F5:75:18:1A:E6:09:09:A0:C0:BE:5B` |
| **SHA-256** | `D9:85:15:B7:BF:54:C8:EB:D9:84:3E:BD:22:66:66:2B:6B:D4:BB:56:89:B0:E2:79:93:FE:45:39:56:20:57:84` |

### ⚠️ Google Sign-In সেটআপ (একবার করতে হবে)

Native Google account picker কাজ করাতে উপরের **SHA-1** আর package name
Google Cloud Console-এ যোগ করতে হবে:

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) →
   Credentials → **Create OAuth Client ID → Android**
2. Package name: `com.workergigbd.app`
3. SHA-1: `A0:D1:AA:C2:9E:64:83:8F:6E:F5:75:18:1A:E6:09:09:A0:C0:BE:5B`
4. তৈরি হওয়া **Android Client ID** কপি করে Supabase Dashboard →
   Authentication → Providers → Google → **Authorized Client IDs**-তে
   (comma দিয়ে) যোগ করুন।

এটা না করলে "Sign in with Google"-এ Developer Error আসবে।

---

## 📦 Builds (GitHub Actions)

প্রতিটি `main` push-ে CI স্বয়ংক্রিয়ভাবে বিল্ড করে **GitHub Release**-এ
সরাসরি APK/AAB দিয়ে দেয়:

➡️ **ডাউনলোড:** [Releases পেজ](https://github.com/wasimmostakim2965-ui/Worker-gig-BD-app/releases)
— `Worker-Gig-BD.apk` ফাইলে ক্লিক করলেই **সরাসরি APK ডাউনলোড**
হয় (কোনো ZIP/extract লাগে না)।

🔗 **স্থায়ী ডাইরেক্ট লিংক** (ভার্সন বদলালেও বদলায় না — Telegram/WhatsApp/
ওয়েবসাইটে এই লিংকটাই শেয়ার করুন):
```
https://github.com/wasimmostakim2965-ui/Worker-gig-BD-app/releases/latest/download/Worker-Gig-BD.apk
```

| ফাইল | কী | কোথায় ব্যবহার |
|---|---|---|
| `Worker-Gig-BD.apk` | **Signed universal APK** — সব ABI এক ফাইলে, কোনো split নেই | ফোনে সরাসরি ইনস্টল + Play Store ছাড়া সব স্টোর (APKPure, APKCombo, Huawei AppGallery, Samsung Galaxy Store, Amazon Appstore, ওয়েবসাইট ডাউনলোড) |
| `Worker-Gig-BD.aab` | Signed App Bundle | **শুধু Google Play Console** |

Actions → Artifacts-এও ফাইল থাকে, তবে GitHub-এর নিয়মে সেটা সবসময়
ZIP আকারে আসে — সরাসরি APK চাইলে **Releases** ব্যবহার করুন।

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
- [x] **Keystore নিরাপদ** — রিপোতে কোনো keystore/পাসওয়ার্ড নেই; শুধু
      GitHub Secrets-এ (CI সেখান থেকে সাইন করে)।
- [x] **Target SDK** — Flutter 3.35.4 → **targetSdk 35 (Android 15)**,
      Play Store-এর 2025 রিকোয়ারমেন্ট পূরণ করে।
- [x] **Package name** — `com.workergigbd.app` (ইউনিক, ওয়েবসাইটের ডোমেইনের
      সাথে মিলিয়ে)।
- [x] **সরাসরি APK ডাউনলোড** — Releases-এ `.apk` হিসেবেই আসে
      (`.zip` নয়)।
- [x] **Code protection** — release বিল্ডে R8/ProGuard minify +
      resource shrink + obfuscation চালু (`proguard-rules.pro`) —
      APK decompile করলেও সোর্স পড়া যায় না।
- [x] **Permissions** — শুধু প্রয়োজনীয় পারমিশন (Internet, Camera/Gallery
      শুধু proof upload-এর জন্য)।
- [x] **Android version support** — **minSdk 21 (Android 5.0 Lollipop)**
      থেকে **targetSdk 35 (Android 15)** পর্যন্ত: Android 5/6/7/8/9/10/11/
      12/13/14/15 সব ভার্সনে ইনস্টল ও চলবে। Flutter এই রেঞ্জের সব ভার্সন
      সাপোর্ট করে, আলাদা কিছু করতে হয় না।

---

## 📲 Android Version সাপোর্ট

| Android Version | API Level | সাপোর্ট |
|---|---|---|
| Android 5.0 – 6.x (Lollipop/Marshmallow) | 21–23 | ✅ |
| Android 7 – 8.x (Nougat/Oreo) | 24–27 | ✅ |
| Android 9 – 10 (Pie/Q) | 28–29 | ✅ |
| Android 11 – 12 | 30–32 | ✅ |
| Android 13 – 14 | 33–34 | ✅ |
| Android 15 | 35 | ✅ (targetSdk) |

একটাই universal APK সব ভার্সনে চলে — ভার্সন অনুযায়ী আলাদা ফাইল লাগে না।

---

## ⚠️ Telegram/WhatsApp-এ APK শেয়ার করলে হাইড হয় — সমাধান

**কেন হয়:** WhatsApp/Telegram/Gmail-এ পাঠানো `.apk` ফাইলগুলো এই প্ল্যাটফর্মগুলো
নিজেদের সেকিউরিটি পলিসির কারণে (malware ছড়ানো রোধে) ব্লক বা ওয়ার্নিং দিয়ে
হাইড করে দেয় — এটা আমাদের APK-র সমস্যা **না**, যেকোনো APK-র ক্ষেত্রেই হয়।

**সঠিক উপায়গুলো:**

1. **ওয়েবসাইট থেকে ডাউনলোড (সবচেয়ে ভালো):** APK-টা আপনার
   workergigbd.site সাইটে হোস্ট করুন (Vercel/Supabase Storage-এ) এবং সবাইকে
   শুধু লিংক দিন, যেমন:
   `https://workergigbd.site/download/workergigbd.apk`
   ব্রাউজার থেকে ডাউনলোড করলে কোনো হাইড/ব্লক হয় না।
2. **GitHub Releases (অটোমেটিক):** প্রতিটি বিল্ডে APK নিজে থেকেই
   [Releases](https://github.com/wasimmostakim2965-ui/Worker-gig-BD-app/releases)-এ
   চলে আসে — সেই পেজের লিংক বা APK ফাইলের ডাইরেক্ট লিংক শেয়ার করুন।
3. **Google Drive/Dropbox লিংক:** APK আপলোড করে "Anyone with the link"
   শেয়ার দিন — ফাইল ডাইরেক্ট শেয়ার না করে লিংক শেয়ার করলে হাইড হয় না।

**মূল নিয়ম:** APK ফাইল সরাসরি না পাঠিয়ে **ডাউনলোড লিংক** পাঠান।
ইউজার ব্রাউজার থেকে ডাউনলোড করে Install unknown apps পারমিশন দিয়ে
ইনস্টল করবে — এটাই স্ট্যান্ডার্ড।

## 🛡️ ইনস্টলের সময় Play Protect ওয়ার্নিং ("Install anyway")

Play Store-এর বাইরে থেকে (sideload) ইনস্টল করা **যেকোনো** অ্যাপে Google
Play Protect "Unsafe app blocked" / "App might be harmful" টাইপ ওয়ার্নিং
দেখায় — কারণ অ্যাপটা Google-এর কাছে অপরিচিত (নতুন, ইনস্টল কম)। এটা
আমাদের APK-র ত্রুটি নয়; "More details → **Install anyway**" চাপলেই
ইনস্টল হয়। সময়ের সাথে সাথে কমে যায়:

- APK সবসময় **একই keystore** দিয়ে সাইনড রাখুন (CI এখন secrets থেকে
  একই key দিয়ে সাইন করে)।
- অ্যাপ **Google Play**-এ ছাড়ুন (internal/closed track হলেও) — Play
  Protect তখন সার্টিফিকেটটা চিনে ফেলে।
- ইউজারদের ব্রাউজার থেকে ডাউনলোড করাতে বলুন, থার্ড-পার্টি ফাইল
  ম্যানেজার থেকে নয়।

### থার্ড-পার্টি স্টোরে আপলোড নোট

- **APKPure / APKCombo / APKMonk**: Releases থেকে নেওয়া
  `Worker-Gig-BD.apk` সরাসরি আপলোড করুন — কোনো পরিবর্তন লাগবে না।
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
