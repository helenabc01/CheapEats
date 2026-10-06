import 'package:cheapeats_app/core/app_services.dart';
import 'package:cheapeats_app/core/config/map_config.dart';
import 'package:cheapeats_app/core/config/supabase_config.dart';
import 'package:cheapeats_app/core/routes/app_routes.dart';
import 'package:cheapeats_app/main.dart';
import 'package:cheapeats_app/screens/map_screen.dart';
import 'package:cheapeats_app/ui/theme.dart';
import 'package:cheapeats_app/widgets/dish_tile.dart';
import 'package:cheapeats_app/widgets/platform_tile.dart';
import 'package:cheapeats_app/widgets/quantity_stepper.dart';
import 'package:cheapeats_app/widgets/restaurant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Avança o relógio até [finder] aparecer (o splash tem animação infinita,
/// então `pumpAndSettle` não serve).
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {int maxTries = 60}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Não encontrei $finder');
}

/// Rola a tela visível até as listas "preguiçosas" construírem [finder].
Future<void> scrollUntilBuilt(WidgetTester tester, Finder finder, {int maxTries = 20}) async {
  for (var i = 0; i < maxTries && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  setUp(() {
    // Testes não têm internet: as fontes caem no fallback do sistema
    // e os mapas aparecem sem os blocos de fundo.
    GoogleFonts.config.allowRuntimeFetching = false;
    MapConfig.tilesEnabled = false;
    SupabaseConfig.forceOffline = true; // usa os dados locais, sem rede
    // Onboarding já visto: o fluxo principal vai direto ao login
    // (a primeira abertura é testada em parte1_test.dart).
    SharedPreferences.setMockInitialValues({'onboarding_visto': true});
  });

  testWidgets('fluxo principal: splash → login → home → restaurante → comparar', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CheapEatsApp());

    // Splash carrega os dados locais e vai para o login.
    await pumpUntilFound(tester, find.text('Explorar sem conta'));

    // Login: validação do formulário.
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe seu e-mail'), findsOneWidget);

    // Entra sem conta e chega na Home.
    await tester.tap(find.text('Explorar sem conta'));
    await pumpUntilFound(tester, find.text('Economia do dia'));
    expect(find.text('Início'), findsOneWidget);

    // Abre o primeiro restaurante da lista.
    await scrollUntilBuilt(tester, find.byType(RestaurantCard));
    await tester.ensureVisible(find.byType(RestaurantCard).first);
    await tester.pump();
    await tester.tap(find.byType(RestaurantCard).first);
    await pumpUntilFound(tester, find.text('Condições em cada app'));

    // Abre a comparação do primeiro prato do cardápio.
    await scrollUntilBuilt(tester, find.byType(DishTile));
    await tester.ensureVisible(find.byType(DishTile).first);
    await tester.pump();
    await tester.tap(find.byType(DishTile).first);
    await pumpUntilFound(tester, find.text('Detalhamento por app'));
    expect(find.byType(PlatformTile), findsWidgets);
    expect(find.byType(QuantityStepper), findsOneWidget);
  });

  testWidgets('mapa: mostra os restaurantes e abre o escolhido', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    AppServices.setCatalogForTest(loadMockCatalog());

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const MapScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Restaurantes perto de você'), findsOneWidget);
    // O mais perto do endereço aparece primeiro no carrossel.
    final nearest = [...AppServices.catalog.restaurants]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    expect(find.text(nearest.first.name), findsOneWidget);

    // Filtrar por categoria mostra só os restaurantes dela.
    await tester.tap(find.text('Pizza'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Pizzaria Bella Napoli'), findsOneWidget);

    // Tocar no card abre a página do restaurante.
    await tester.tap(find.text('Pizzaria Bella Napoli'));
    await pumpUntilFound(tester, find.text('Condições em cada app'));
  });
}
