import 'package:cheapeats_app/ui/theme.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Image.asset(
          'assets/imgs/icon.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
