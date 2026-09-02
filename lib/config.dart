/// App-wide configuration. Mirrors the website's environment variables.
/// The anon key is a public "publishable" Supabase key — safe to ship in the
/// app; all data access is enforced by Row Level Security on the server.
class AppConfig {
  static const String appName = 'WORKER GIG BD';
  static const String siteUrl = 'https://www.workergigbd.site';

  static const String supabaseUrl = 'https://tsokfguhydwausvuaaiw.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_hfgUFRLu1UrBd10ulCUgsA_po8qwPjw';

  /// Deep link registered in AndroidManifest for the OAuth callback.
  /// Must also be added to Supabase Dashboard → Authentication → URL
  /// Configuration → Redirect URLs.
  static const String oauthRedirect = 'com.workergigbd.app://login-callback/';

  /// The single shared admin account email (same as the web admin gate).
  static const String adminEmail = 'adminworkergig@gmail.com';
}
