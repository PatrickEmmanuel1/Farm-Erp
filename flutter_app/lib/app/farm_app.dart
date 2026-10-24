import 'package:flutter/material.dart';

import '../ui/navigation/app_navigation.dart';

import '../ui/theme/app_theme.dart';

class FarmApp extends StatelessWidget {
  const FarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFarm',
      theme: FarmTheme.light,
      home: const AppNavigation(),
    );
  }
}
