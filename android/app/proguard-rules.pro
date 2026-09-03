# Keep Flutter embedding (needed for the Flutter engine layer)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / gotrue needs names preserved for auth-callback handling
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }

# google_sign_in
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Support network-call reflection
-keep class io.ktor.** { *; }
-keepnames class io.sentry.** { *; }

-dontwarn io.flutter.**
-dontwarn io.supabase.**
-dontwarn com.google.**
-dontwarn io.ktor.**
