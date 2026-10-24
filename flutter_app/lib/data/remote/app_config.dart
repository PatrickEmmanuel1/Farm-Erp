import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  static const _nativeConfigChannel =
      MethodChannel('com.example.farm_flutter/supabase_config');

  static Future<AppConfig> load() async {
    final environmentConfig = AppConfig.fromEnvironment();
    if (environmentConfig.supabaseUrl.isNotEmpty ||
        environmentConfig.supabaseAnonKey.isNotEmpty ||
        defaultTargetPlatform != TargetPlatform.android) {
      return environmentConfig;
    }

    final nativeConfig =
        await _nativeConfigChannel.invokeMapMethod<String, String>(
      'getSupabaseConfig',
    );
    return AppConfig(
      supabaseUrl: nativeConfig?['url'] ?? '',
      supabaseAnonKey: nativeConfig?['anonKey'] ?? '',
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured =>
      Uri.tryParse(supabaseUrl)?.hasAuthority == true &&
      supabaseAnonKey.isNotEmpty;
}
