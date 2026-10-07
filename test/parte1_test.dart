import 'package:cheapeats_app/core/app_services.dart';
import 'package:cheapeats_app/core/config/map_config.dart';
import 'package:cheapeats_app/core/config/supabase_config.dart';
import 'package:cheapeats_app/core/routes/app_routes.dart';
import 'package:cheapeats_app/core/services/address_controller.dart';
import 'package:cheapeats_app/core/services/location_service.dart';
import 'package:cheapeats_app/core/services/session_controller.dart';
import 'package:cheapeats_app/core/utils/formatters.dart';
import 'package:cheapeats_app/data/models/price_quote.dart';
import 'package:cheapeats_app/data/repositories/auth_repository.dart';
import 'package:cheapeats_app/main.dart';
import 'package:cheapeats_app/screens/onboarding_screen.dart';
import 'package:cheapeats_app/screens/profile_screen.dart';
import 'package:cheapeats_app/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Avança o relógio até [finder] aparecer (o splash tem animação infinita).
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {int maxTries = 60}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Não encontrei $finder');
}

/// Localização simulada: devolve [address] ou lança [error] depois de um instante.
class _FakeLocation implements LocationService {
  final DeliveryAddress? address;
  final LocationException? error;

  _FakeLocation({this.address, this.error});

  @override
  Future<DeliveryAddress> currentAddress() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (error != null) throw error!;
    return address!;
  }
}

/// App com um botão que abre [route] (para testar o "voltar").
Widget _appOpening(String route) => MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => Navigator.of(context).pushNamed(route), child: const Text('abrir')),
        ),
      ),
    );

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    MapConfig.tilesEnabled = false;
    SupabaseConfig.forceOffline = true;
    SharedPreferences.setMockInitialValues({});
    AppServices.setCatalogForTest(loadMockCatalog());
    AppServices.address.select(AddressController.defaultAddress);
    await AppServices.session.logout();
  });

  group('onboarding', () {
    testWidgets('aparece na primeira abertura e leva ao login', (tester) async {
      await tester.pumpWidget(const CheapEatsApp());
      await pumpUntilFound(tester, find.text('Compare antes de pedir'));

      await tester.tap(find.text('Próximo'));
      await pumpUntilFound(tester, find.text('O preço real aparece'));
      await tester.tap(find.text('Próximo'));
      await pumpUntilFound(tester, find.text('Começar')); // última página

      await tester.tap(find.text('Começar'));
      await pumpUntilFound(tester, find.text('Explorar sem conta'));
      expect(await OnboardingFlag.isSeen(), isTrue);
    });

    testWidgets('não aparece depois de visto', (tester) async {
      SharedPreferences.setMockInitialValues({OnboardingFlag.key: true});
      await tester.pumpWidget(const CheapEatsApp());
      await pumpUntilFound(tester, find.text('Explorar sem conta'));
      expect(find.text('Compare antes de pedir'), findsNothing);
    });

    testWidgets('"Pular" salva e vai ao login', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const OnboardingScreen(),
      ));
      await tester.tap(find.text('Pular'));
      await pumpUntilFound(tester, find.text('Explorar sem conta'));
      expect(await OnboardingFlag.isSeen(), isTrue);
    });
  });

  group('endereço', () {
    testWidgets('busca, seleciona e marca o escolhido ao reabrir', (tester) async {
      await tester.pumpWidget(_appOpening(AppRoutes.address));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'vergueiro');
      await tester.pump();
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Trabalho'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Nenhum endereço encontrado'), findsOneWidget);
      await tester.tap(find.text('Limpar busca'));
      await tester.pump();

      await tester.tap(find.text('Trabalho'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget); // voltou
      expect(AppServices.address.current.label, 'Trabalho');

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Trabalho'),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('localização atual: usa o endereço do GPS', (tester) async {
      const gps = DeliveryAddress(
        label: LocationService.currentLabel,
        street: 'Rua Teste, 10',
        district: 'Centro, São Paulo',
        latitude: -23.55,
        longitude: -46.63,
      );
      AppServices.location = _FakeLocation(address: gps);
      await tester.pumpWidget(_appOpening(AppRoutes.address));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar minha localização atual'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Procurando sua localização…'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('abrir'), findsOneWidget);
      expect(AppServices.address.current.street, 'Rua Teste, 10');
    });

    testWidgets('localização negada: avisa e mantém o endereço', (tester) async {
      AppServices.location = _FakeLocation(error: const LocationException('Permita o acesso à localização.'));
      await tester.pumpWidget(_appOpening(AppRoutes.address));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar minha localização atual'));
      await tester.pumpAndSettle();
      expect(find.text('Permita o acesso à localização.'), findsOneWidget);
      expect(AppServices.address.current.label, AddressController.defaultAddress.label);
    });
  });

  group('perfil', () {
    // A splash dos testes anteriores carrega os pedidos de exemplo; aqui o perfil começa sem pedidos.
    setUp(AppServices.orders.clearForTest);

    Future<void> pumpProfile(WidgetTester tester) {
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const ProfileScreen(),
      ));
    }

    testWidgets('visitante: sem conta e economia zerada', (tester) async {
      AppServices.session.loginAsGuest();
      await pumpProfile(tester);

      expect(find.text('Visitante'), findsOneWidget);
      expect(find.text('Entrou sem conta'), findsOneWidget);
      expect(find.text(Fmt.brl(0)), findsOneWidget);
      expect(find.text('Sua economia começa no próximo pedido.'), findsOneWidget);
    });

    testWidgets('conta: nome, economia dos pedidos e sair limpa a pilha', (tester) async {
      final signIn = AppServices.session.signIn(
        email: SessionController.demoEmail,
        password: SessionController.demoPassword,
      );
      await tester.pump(const Duration(seconds: 1));
      await signIn;
      await pumpProfile(tester);
      expect(find.text('Ana Demo'), findsOneWidget);
      expect(find.text(SessionController.demoEmail), findsOneWidget);

      // Um pedido novo aparece na hora no card de economia.
      final restaurant = AppServices.catalog.restaurants.first;
      final items = [OrderItem(restaurant.dishes.first, 1)];
      final comparison = AppServices.calculator.compare(restaurant, items);
      await AppServices.orders.register(
        restaurant: restaurant,
        items: items,
        chosen: comparison.best!,
        comparison: comparison,
      );
      await tester.pump();
      expect(find.text(Fmt.brl(AppServices.orders.totalSavings)), findsOneWidget);
      expect(find.text('Em 1 pedido feito pelo CheapEats'), findsOneWidget);

      await tester.tap(find.text('Sair da conta'));
      await pumpUntilFound(tester, find.text('Explorar sem conta'));
      expect(AppServices.session.isLoggedIn, isFalse);
      expect(Navigator.of(tester.element(find.text('Explorar sem conta'))).canPop(), isFalse);
    });
  });

  group('autenticação local', () {
    test('senha curta é recusada com mensagem', () async {
      final auth = LocalAuthRepository(delay: Duration.zero);
      expect(
        () => auth.signIn(email: 'a@b.com', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('conta criada guarda o nome e não pode ser duplicada', () async {
      final auth = LocalAuthRepository(delay: Duration.zero);
      await auth.signUp(name: 'Maria Souza', email: 'Maria@Email.com', password: '123456');
      await auth.signOut();
      expect(auth.currentUser, isNull);

      final user = await auth.signIn(email: 'maria@email.com', password: '123456');
      expect(user.name, 'Maria Souza');
      expect(
        () => auth.signUp(name: 'Outra', email: 'maria@email.com', password: '123456'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
