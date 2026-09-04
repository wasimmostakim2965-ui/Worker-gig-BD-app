import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
// key.properties রিপোতে থাকে না — CI GitHub Secrets থেকে লিখে দেয়;
// লোকালে কাজ করলে নিজে android/key.properties বানাতে হবে।
// ফাইল না থাকলে release বিল্ড debug key দিয়ে সাইন হয় (শুধু টেস্টের জন্য)।
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.workergigbd.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.workergigbd.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 5.0 (API 21) তে সাপোর্ট — ~99% ডিভাইস কভারেজ;
        // পুরনো ফোনের ইউজাররাও ইনস্টল করতে পারবেন।
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
                // v1 (JAR) signing বাধ্যতামূলক — minSdk 21 হওয়ায় Android 5/6
                // ডিভাইস v2-only APK ইনস্টল করতে পারে না।
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            // R8 minify/resource-shrinking stays OFF: Dart code is already
            // AOT-compiled, so R8 only touched the (open-source) plugin glue
            // while causing release-only startup crashes on some devices.
            isMinifyEnabled = false
            isShrinkResources = false

            // CI signs with the production keystore (secrets → key.properties);
            // a local release build without key.properties falls back to the
            // debug key — test-only, never distribute that APK.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    lint {
        disable.add("MissingTranslation")
        disable.add("ExtraTranslation")
    }
}

flutter {
    source = "../.."
}
