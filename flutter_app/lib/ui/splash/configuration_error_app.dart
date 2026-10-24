import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: FarmTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase is not configured. Run the app with '
              '--dart-define=SUPABASE_URL=... and '
              '--dart-define=SUPABASE_ANON_KEY=... . In VS Code, use the '
              'Flutter Android (local Supabase config) launch profile. '
              'Android reads both values from the repository-root .env file.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
