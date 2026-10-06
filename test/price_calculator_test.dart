import 'package:cheapeats_app/data/catalog.dart';
import 'package:cheapeats_app/data/models/price_quote.dart';
import 'package:cheapeats_app/data/services/price_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late Catalog catalog;
  late PriceCalculator newOnKeeta; // usuário que nunca pediu no Keeta
  late PriceCalculator veteran; // já pediu em todos os apps

  setUpAll(() {
    catalog = loadMockCatalog();
    newOnKeeta = PriceCalculator(catalog: catalog, firstOrderPlatforms: {'keeta'}, now: testNow);
    veteran = PriceCalculator(catalog: catalog, now: testNow);
  });

  Comparison compare(PriceCalculator calc, String restaurantId, String dishSlug, {int quantity = 1}) {
    final restaurant = catalog.restaurantById(restaurantId)!;
    final dish = catalog.dishById('$restaurantId-$dishSlug')!;
    return calc.compareDish(restaurant, dish, quantity: quantity);
  }

  PriceQuote quoteOf(Comparison c, String platformId) => c.ranked.firstWhere((q) => q.platform.id == platformId);

  group('total = itens + entrega + taxa − cupom', () {
    test('cupom fixo do restaurante faz o iFood vencer na pizzaria', () {
      final c = compare(veteran, 'bella-napoli', 'margherita');
      final ifood = quoteOf(c, 'ifood');
      expect(ifood.subtotal, 69.90);
      expect(ifood.deliveryFee, 0);
      expect(ifood.serviceFee, 0.99);
      expect(ifood.coupon?.code, 'NAPOLI15');
      expect(ifood.total, closeTo(55.89, 0.001));
      expect(c.best!.platform.id, 'ifood');
    });

    test('cupom de entrega grátis zera o frete', () {
      final c = compare(veteran, 'poke-haus', 'poke-salmao');
      final food99 = quoteOf(c, '99food');
      expect(food99.coupon?.code, '99FRETE');
      expect(food99.discount, food99.deliveryFee);
      expect(food99.total, closeTo(49.90, 0.001));
    });

    test('cupom percentual respeita o teto (máx. R\$ 8)', () {
      final c = compare(veteran, 'sushi-kenzo', 'combo-40');
      final keeta = quoteOf(c, 'keeta');
      expect(keeta.coupon?.code, 'KEETA10');
      expect(keeta.discount, 8.0); // 10% de 149,90 seria 14,99
      expect(keeta.hasPromo, isTrue); // preço "de" 164,90
    });

    test('cupom de 1º pedido só vale para quem nunca pediu no app', () {
      final novo = quoteOf(compare(newOnKeeta, 'sushi-kenzo', 'combo-40'), 'keeta');
      final antigo = quoteOf(compare(veteran, 'sushi-kenzo', 'combo-40'), 'keeta');
      expect(novo.coupon?.code, 'BEMVINDO15');
      expect(novo.total, closeTo(142.38, 0.001));
      expect(antigo.coupon?.code, 'KEETA10');
      expect(antigo.total, closeTo(149.38, 0.001));
    });

    test('cupom expirado nunca é aplicado', () {
      for (final r in catalog.restaurants) {
        for (final d in r.dishes) {
          for (final q in newOnKeeta.compareDish(r, d).ranked) {
            expect(q.coupon?.code, isNot('VOLTA20'));
          }
        }
      }
    });

    test('avisa quando falta pouco para um cupom valer', () {
      final keeta = quoteOf(compare(veteran, 'brasa-pao', 'smash-duplo'), 'keeta');
      expect(keeta.coupon, isNull);
      expect(keeta.nearMissCoupon?.code, 'KEETA10');
      expect(keeta.missingForCoupon, closeTo(6.10, 0.001)); // 40,00 − 33,90
    });

    test('quantidade multiplica sem erro de arredondamento', () {
      final c = compare(veteran, 'padaria-estrela', 'cappuccino', quantity: 3);
      expect(quoteOf(c, '99food').subtotal, 38.70);
    });
  });

  group('disponibilidade', () {
    test('restaurante fora do app, item não vendido e item esgotado', () {
      expect(
        quoteOf(compare(veteran, 'taco-loco', 'tacos-pastor'), 'ifood').unavailableReason,
        UnavailableReason.restaurantNotOnPlatform,
      );
      expect(
        quoteOf(compare(veteran, 'bella-napoli', 'rucula'), 'keeta').unavailableReason,
        UnavailableReason.itemNotSold,
      );
      expect(
        quoteOf(compare(veteran, 'brasa-pao', 'milkshake-ovomaltine'), 'keeta').unavailableReason,
        UnavailableReason.itemSoldOut,
      );
    });

    test('indisponíveis ficam no fim do ranking', () {
      final c = compare(veteran, 'brasa-pao', 'milkshake-ovomaltine');
      expect(c.ranked.last.isAvailable, isFalse);
      expect(c.available.length, 3); // iFood, 99Food e Rappi
    });

    test('restaurante em um app só não tem comparação', () {
      final c = compare(veteran, 'doce-brigadeiro', 'caixa-12');
      expect(c.hasComparison, isFalse);
      expect(c.best!.platform.id, 'ifood');
      expect(c.savings, 0);
    });
  });

  group('pedido mínimo, empate e economia', () {
    test('pedido mínimo: 1 esfiha não atinge, 3 atingem', () {
      expect(compare(veteran, 'habibi', 'esfiha-carne').best!.meetsMinOrder, isFalse);
      expect(compare(veteran, 'habibi', 'esfiha-carne', quantity: 3).best!.meetsMinOrder, isTrue);
    });

    test('empate é detectado e desempata pelo tempo de entrega', () {
      final c = compare(veteran, 'padaria-estrela', 'pao-chapa-cafe');
      expect(c.isTie, isTrue);
      expect(c.ranked[0].platform.id, 'ifood'); // 15–25 min
      expect(c.ranked[1].platform.id, '99food'); // 20–30 min
      expect(c.savings, greaterThan(0)); // ainda economiza em relação ao Keeta
    });

    test('economia = mais caro − mais barato', () {
      final c = compare(veteran, 'brasa-pao', 'smash-duplo');
      expect(c.best!.platform.id, 'keeta');
      expect(c.worst!.platform.id, 'rappi');
      expect(c.savings, closeTo(c.worst!.total - c.best!.total, 0.001));
      expect(c.savingsRatio, closeTo(c.savings / c.worst!.total, 0.0001));
    });

    test('vitrine "Economia do dia" só traz pedidos válidos e variados', () {
      final deals = newOnKeeta.topDeals();
      expect(deals, isNotEmpty);
      for (final (restaurant, _, comparison) in deals) {
        expect(restaurant.isOpen, isTrue);
        expect(comparison.best!.meetsMinOrder, isTrue);
        expect(comparison.savingsCents, greaterThan(0));
      }
      final perRestaurant = <String, int>{};
      for (final (r, _, _) in deals) {
        perRestaurant[r.id] = (perRestaurant[r.id] ?? 0) + 1;
      }
      expect(perRestaurant.values.every((n) => n <= 2), isTrue);
    });

    test('nenhum app domina: cada um é o mais barato em alguns pratos', () {
      final wins = <String, int>{};
      var total = 0;
      for (final r in catalog.restaurants) {
        for (final d in r.dishes) {
          final c = newOnKeeta.compareDish(r, d);
          if (!c.hasComparison) continue;
          total++;
          wins[c.best!.platform.id] = (wins[c.best!.platform.id] ?? 0) + 1;
        }
      }
      expect(wins.keys, containsAll(['ifood', '99food', 'keeta', 'rappi', 'aiqfome']));
      expect(wins.values.every((n) => n >= 5), isTrue, reason: '$wins');
      expect(wins.values.every((n) => n <= total * 0.4), isTrue, reason: '$wins');
    });

    test('Rappi vence com cupom do restaurante e Aiqfome vence na comida caseira', () {
      final lasanha = compare(veteran, 'cantina-nonna', 'lasanha');
      expect(lasanha.best!.platform.id, 'rappi');
      expect(lasanha.best!.coupon?.code, 'NONNA10');
      final pf = compare(veteran, 'tia-lu', 'pf-bife');
      expect(pf.best!.platform.id, 'aiqfome');
      expect(quoteOf(pf, 'aiqfome').serviceFee, 0); // Aiqfome não cobra taxa de serviço
    });
  });
}
