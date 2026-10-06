import 'package:cheapeats_app/data/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late Catalog catalog;

  setUpAll(() => catalog = loadMockCatalog());

  test('dados simulados carregam completos e consistentes', () {
    expect(catalog.platforms.map((p) => p.id), ['ifood', '99food', 'keeta', 'rappi', 'aiqfome']);
    expect(catalog.restaurants.length, greaterThanOrEqualTo(12));
    expect(catalog.dishCount, greaterThanOrEqualTo(60));
    expect(catalog.coupons.length, greaterThanOrEqualTo(8));
    for (final r in catalog.restaurants) {
      expect(r.platforms, isNotEmpty, reason: r.id);
      expect(r.latitude, inInclusiveRange(-23.7, -23.4), reason: '${r.id} fora de SP');
      expect(r.longitude, inInclusiveRange(-46.8, -46.5), reason: '${r.id} fora de SP');
      expect(r.dishes, isNotEmpty, reason: r.id);
      for (final d in r.dishes) {
        // Todo preço aponta para um app em que o restaurante está.
        for (final p in d.prices) {
          expect(r.isOn(p.platformId), isTrue, reason: '${d.id} em ${p.platformId}');
        }
      }
    }
  });

  test('cobre os casos de borda pedidos para a demonstração', () {
    expect(catalog.restaurants.any((r) => !r.isOpen), isTrue, reason: 'restaurante fechado');
    expect(catalog.restaurants.any((r) => r.platforms.length == 1), isTrue, reason: 'só em 1 app');
    expect(catalog.restaurants.any((r) => r.platforms.length == 2), isTrue, reason: 'em 2 apps');
    final prices = [for (final r in catalog.restaurants) for (final d in r.dishes) ...d.prices];
    expect(prices.any((p) => !p.available), isTrue, reason: 'item esgotado');
    expect(prices.any((p) => p.isPromo), isTrue, reason: 'preço promocional riscado');
    expect(catalog.coupons.any((c) => c.isExpired(testNow)), isTrue, reason: 'cupom expirado');
    expect(catalog.coupons.any((c) => c.firstOrderOnly), isTrue, reason: 'cupom de 1º pedido');
  });

  group('busca', () {
    test('ignora acentos e maiúsculas', () {
      expect(catalog.searchDishes('ACAI').map((e) => e.$2.name), contains('Açaí 500ml'));
      expect(catalog.searchRestaurants('pao').map((r) => r.id), contains('brasa-pao'));
    });

    test('entende sinônimos simples', () {
      final dishes = catalog.searchDishes('hambúrguer');
      expect(dishes, isNotEmpty);
      expect(dishes.every((e) => e.$1.id == 'brasa-pao'), isTrue);
    });

    test('nome do restaurante também encontra os pratos dele', () {
      final found = catalog.searchDishes('sushi').map((e) => e.$2.id).toSet();
      final kenzo = catalog.restaurantById('sushi-kenzo')!.dishes.map((d) => d.id);
      // Todos os pratos do Sushi Kenzo + pokes com "arroz de sushi" na descrição.
      expect(found, containsAll(kenzo));
    });

    test('busca por categoria', () {
      expect(catalog.searchRestaurants('saudável').length, 2);
    });

    test('busca sem resultado e busca vazia', () {
      expect(catalog.searchDishes('feijão tropeiro xyz'), isEmpty);
      expect(catalog.searchRestaurants('   '), isEmpty);
    });
  });
}
