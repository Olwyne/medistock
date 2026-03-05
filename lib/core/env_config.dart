import 'package:flutter/foundation.dart';

/// Configuration Supabase : URL et clé anon.
/// Sur web : lues via --dart-define (build Netlify).
/// Sur mobile : lues depuis .env (flutter_dotenv).
class EnvConfig {
  static String get supabaseUrl {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
    }
    return _dotenvSupabaseUrl ?? '';
  }

  static String get supabaseAnonKey {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      );
    }
    return _dotenvSupabaseAnonKey ?? '';
  }

  static String? _dotenvSupabaseUrl;
  static String? _dotenvSupabaseAnonKey;

  static void setFromDotenv(String url, String anonKey) {
    _dotenvSupabaseUrl = url;
    _dotenvSupabaseAnonKey = anonKey;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
