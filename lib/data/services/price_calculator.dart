import '../catalog.dart';
import '../models/coupon.dart';
import '../models/delivery_platform.dart';
import '../models/dish.dart';
import '../models/price_quote.dart';
import '../models/restaurant.dart';

/// Regra central do CheapEats:
///
///   total = itens + entrega + taxa de serviço − melhor cupom
///
/// O cupom só vale se o pedido atingir o mínimo dele, se não estiver expirado
/// e, nos cupons de 1º pedido, se o usuário ainda não pediu naquele app.
/// Funciona para 1 prato com quantidade ou para vários itens (sacola).
class PriceCalculator {
  final Catalog catalog;

  /// Apps em que o usuário ainda NÃO fez pedido (liberam cupom de 1º pedido).
  final Set<String> firstOrderPlatforms;
  final DateTime? now;

  const PriceCalculator({
    required this.catalog,
    this.firstOrderPlatforms = const {},
    this.now,
  });

  /// Até quanto pode faltar para sugerirmos "adicione mais R$ X e use o cupom".
  static const maxNearMissCents = 1500;

  static int _cents(double value) => (value * 100).round();

  PriceQuote quote(Restaurant restaurant, List<OrderItem> items, DeliveryPlatform platform) {
    final info = restaurant.infoFor(platform.id);
    if (info == null) {
      return PriceQuote(platform: platform, unavailableReason: UnavailableReason.restaurantNotOnPlatform);
    }

    var subtotal = 0;
    var originalSubtotal = 0;
    for (final item in items) {
      final price = item.dish.priceOn(platform.id);
      if (price == null) {
        return PriceQuote(platform: platform, unavailableReason: UnavailableReason.itemNotSold);
      }
      if (!price.available) {
        return PriceQuote(platform: platform, unavailableReason: UnavailableReason.itemSoldOut);
      }
      subtotal += _cents(price.price) * item.quantity;
      originalSubtotal += _cents(price.originalPrice ?? price.price) * item.quantity;
    }

    final deliveryFee = _cents(info.deliveryFee);
    final serviceFee = _cents(platform.serviceFee);

    Coupon? bestCoupon;
    var bestDiscount = 0;
    Coupon? nearMiss;
    var nearMissMissing = 0;

    for (final coupon in catalog.coupons) {
      if (coupon.platformId != platform.id) continue;
      if (!coupon.appliesToRestaurant(restaurant.id)) continue;
      if (coupon.isExpired(now)) continue;
      if (coupon.firstOrderOnly && !firstOrderPlatforms.contains(platform.id)) continue;

      final minOrder = _cents(coupon.minOrder);
      final potential = coupon.discountCents(
        subtotalCents: subtotal < minOrder ? minOrder : subtotal,
        deliveryFeeCents: deliveryFee,
      );
      if (subtotal >= minOrder) {
        if (potential > bestDiscount) {
          bestDiscount = potential;
          bestCoupon = coupon;
        }
      } else if (potential > 0) {
        final missing = minOrder - subtotal;
        if (nearMiss == null || missing < nearMissMissing) {
          nearMiss = coupon;
          nearMissMissing = missing;
        }
      }
    }

    // Só mostra o "quase cupom" se faltar pouco e se ele der mais desconto que o atual.
    if (nearMiss != null && nearMissMissing > maxNearMissCents) nearMiss = null;
    if (nearMiss != null) {
      final nearMissDiscount = nearMiss.discountCents(
        subtotalCents: _cents(nearMiss.minOrder),
        deliveryFeeCents: deliveryFee,
      );
      if (nearMissDiscount <= bestDiscount) nearMiss = null;
    }

    return PriceQuote(
      platform: platform,
      subtotalCents: subtotal,
      originalSubtotalCents: originalSubtotal,
      deliveryFeeCents: deliveryFee,
      serviceFeeCents: serviceFee,
      discountCents: bestDiscount,
      coupon: bestCoupon,
      nearMissCoupon: nearMiss,
      missingForCouponCents: nearMiss == null ? 0 : nearMissMissing,
      minOrderCents: _cents(info.minOrder),
      deliveryTimeMin: info.deliveryTimeMin,
      deliveryTimeMax: info.deliveryTimeMax,
    );
  }

  /// Compara o pedido em todos os apps e devolve do mais barato ao mais caro.
  Comparison compare(Restaurant restaurant, List<OrderItem> items) {
    final quotes = catalog.platforms.map((p) => quote(restaurant, items, p)).toList();

    int group(PriceQuote q) {
      if (!q.isAvailable) return 2;
      return q.meetsMinOrder ? 0 : 1;
    }

    quotes.sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      if (byGroup != 0) return byGroup;
      final byTotal = a.totalCents.compareTo(b.totalCents);
      if (byTotal != 0) return byTotal;
      // Empate no preço: quem entrega mais rápido aparece primeiro.
      return a.deliveryTimeMax.compareTo(b.deliveryTimeMax);
    });
    return Comparison(quotes);
  }

  Comparison compareDish(Restaurant restaurant, Dish dish, {int quantity = 1}) =>
      compare(restaurant, [OrderItem(dish, quantity)]);

  /// App que é o mais barato em mais pratos do restaurante (para os cards).
  DeliveryPlatform? bestPlatformFor(Restaurant restaurant) {
    final wins = <String, int>{};
    for (final dish in restaurant.dishes) {
      final best = compareDish(restaurant, dish).best;
      if (best != null) wins[best.platform.id] = (wins[best.platform.id] ?? 0) + 1;
    }
    if (wins.isEmpty) return null;
    final top = wins.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return catalog.platform(top.key);
  }

  /// Maior economia (em %) entre os pratos do restaurante.
  double maxSavingsRatio(Restaurant restaurant) {
    var max = 0.0;
    for (final dish in restaurant.dishes) {
      final comparison = compareDish(restaurant, dish);
      if (comparison.best?.meetsMinOrder == true && comparison.savingsRatio > max) {
        max = comparison.savingsRatio;
      }
    }
    return max;
  }

  /// Pratos com maior economia (R$) — "Economia do dia" da Home.
  List<(Restaurant, Dish, Comparison)> topDeals({int limit = 8}) {
    final deals = <(Restaurant, Dish, Comparison)>[];
    for (final r in catalog.restaurants.where((r) => r.isOpen)) {
      for (final d in r.dishes) {
        final c = compareDish(r, d);
        if (c.hasComparison && c.best!.meetsMinOrder && c.savingsCents > 0) deals.add((r, d, c));
      }
    }
    deals.sort((a, b) => b.$3.savingsCents.compareTo(a.$3.savingsCents));
    // No máximo 2 pratos por restaurante para a vitrine ficar variada.
    final perRestaurant = <String, int>{};
    final result = <(Restaurant, Dish, Comparison)>[];
    for (final deal in deals) {
      final count = perRestaurant[deal.$1.id] ?? 0;
      if (count >= 2) continue;
      perRestaurant[deal.$1.id] = count + 1;
      result.add(deal);
      if (result.length == limit) break;
    }
    return result;
  }
}
