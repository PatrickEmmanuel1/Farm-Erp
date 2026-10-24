import 'package:flutter/material.dart';
import 'app/farm_app.dart';
import 'data/remote/app_config.dart';
import 'data/remote/supabase_client_provider.dart';
import 'ui/splash/configuration_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();
  if (!config.isConfigured) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  await SupabaseClientProvider.initialize(config);

  runApp(const FarmApp());
}
