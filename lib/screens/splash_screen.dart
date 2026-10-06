import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../ui/theme.dart';
import 'onboarding_screen.dart';

/// Abre o app: anima o logo enquanto inicia o Supabase e carrega o catálogo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final minimumTime = Future<void>.delayed(const Duration(milliseconds: 1800));
    final onboardingSeen = OnboardingFlag.isSeen();
    await AppServices.initSupabase();
    await AppServices.loadCatalog();
    await AppServices.favorites.load();
    await AppServices.orders.load();
    await minimumTime;
    // Na primeira abertura, apresenta o app antes do login.
    final next = await onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(next, (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset('assets/imgs/icon.png', width: 148, height: 148),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text('CheapEats', style: AppText.h2),
                      const SizedBox(height: 4),
                      Text(
                        'O faro fino do delivery.',
                        style: AppText.body1.copyWith(color: AppColors.textDarkGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.orange),
                  ),
                  const SizedBox(height: 12),
                  Text('Comparando iFood, 99Food e Keeta…', style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
