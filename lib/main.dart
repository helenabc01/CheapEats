import 'package:cheapeats_app/ui/theme.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const CheapEatsApp());
}

class CheapEatsApp extends StatelessWidget {
  const CheapEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheapEats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
