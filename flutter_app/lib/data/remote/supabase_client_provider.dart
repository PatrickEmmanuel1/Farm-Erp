import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseClientProvider {
  static AppConfig? _config;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize(AppConfig config) async {
    _config = config;
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        persistSession: true,
      ),
    );
  }

  static SupabaseClient createIsolatedAuthClient() {
    final config = _config;
    if (config == null) {
      throw StateError(
        'SupabaseClientProvider must be initialized before creating an '
        'isolated auth client.',
      );
    }

    return SupabaseClient(
      config.supabaseUrl,
      config.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }
}
