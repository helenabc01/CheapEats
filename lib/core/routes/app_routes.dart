import 'package:flutter/material.dart';

import '../../screens/address_screen.dart';
import '../../screens/comparison_screen.dart';
import '../../screens/coupons_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/map_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/restaurant_screen.dart';
import '../../screens/splash_screen.dart';
import '../app_services.dart';

/// Argumentos da tela de comparação.
class CompareArgs {
  final String restaurantId;
  final String dishId;
  final int quantity;

  const CompareArgs({required this.restaurantId, required this.dishId, this.quantity = 1});
}

/// Todas as rotas do app em um lugar só.
///
/// Fluxo principal: Splash → Login → Home (abas) → Restaurante → Comparar → app de delivery.
/// Também dá para escolher o restaurante pelo Mapa (Home → ícone de mapa).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding'; // Parte 1
  static const login = '/login';
  static const home = '/home';
  static const restaurant = '/restaurante'; // argumento: id do restaurante (String)
  static const compare = '/comparar'; // argumento: CompareArgs
  static const map = '/mapa';
  static const address = '/endereco'; // Parte 1
  static const coupons = '/cupons'; // Parte 2
  static const favorites = '/favoritos'; // Parte 3

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Se o app foi aberto direto numa URL (web) antes de carregar os dados,
    // volta para o splash, que carrega tudo e segue o fluxo normal.
    if (!AppServices.isReady && settings.name != splash) {
      return _page(const SplashScreen(), const RouteSettings(name: splash));
    }

    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      splash => const SplashScreen(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      home => const MainShell(),
      restaurant when args is String => RestaurantScreen(restaurantId: args),
      compare when args is CompareArgs => ComparisonScreen(args: args),
      map => const MapScreen(),
      address => const AddressScreen(),
      coupons => const CouponsScreen(),
      favorites => const FavoritesScreen(),
      _ => const MainShell(),
    };
    return _page(page, settings);
  }

  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) => [
        _page(const SplashScreen(), const RouteSettings(name: splash)),
      ];

  static MaterialPageRoute<dynamic> _page(Widget page, RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => page, settings: settings);
}
