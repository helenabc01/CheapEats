import 'coupon.dart';
import 'delivery_platform.dart';
import 'dish.dart';

/// Um item do pedido (prato + quantidade).
class OrderItem {
  final Dish dish;
  final int quantity;

  const OrderItem(this.dish, [this.quantity = 1]);

  OrderItem copyWith({int? quantity}) => OrderItem(dish, quantity ?? this.quantity);
}

/// Por que um app não pode atender o pedido.
enum UnavailableReason {
  restaurantNotOnPlatform('Restaurante não está neste app'),
  itemNotSold('Item não vendido neste app'),
  itemSoldOut('Esgotado neste app');

  final String label;
  const UnavailableReason(this.label);
}

/// Quanto o pedido custa em UM app (itens + entrega + taxa − cupom).
/// Os valores ficam em centavos para evitar erro de arredondamento.
class PriceQuote {
  final DeliveryPlatform platform;
  final UnavailableReason? unavailableReason;
  final int subtotalCents;

  /// Soma dos preços "de" (sem promoção) — para mostrar riscado.
  final int originalSubtotalCents;
  final int deliveryFeeCents;
  final int serviceFeeCents;
  final int discountCents;
  final Coupon? coupon;

  /// Cupom que quase vale: falta pouco para o pedido mínimo dele.
  final Coupon? nearMissCoupon;
  final int missingForCouponCents;
  final int minOrderCents;
  final int deliveryTimeMin;
  final int deliveryTimeMax;

  const PriceQuote({
    required this.platform,
    this.unavailableReason,
    this.subtotalCents = 0,
    this.originalSubtotalCents = 0,
    this.deliveryFeeCents = 0,
    this.serviceFeeCents = 0,
    this.discountCents = 0,
    this.coupon,
    this.nearMissCoupon,
    this.missingForCouponCents = 0,
    this.minOrderCents = 0,
    this.deliveryTimeMin = 0,
    this.deliveryTimeMax = 0,
  });

  bool get isAvailable => unavailableReason == null;
  bool get meetsMinOrder => subtotalCents >= minOrderCents;
  bool get hasPromo => originalSubtotalCents > subtotalCents;

  int get totalCents {
    final total = subtotalCents + deliveryFeeCents + serviceFeeCents - discountCents;
    return total < 0 ? 0 : total;
  }

  double get subtotal => subtotalCents / 100;
  double get originalSubtotal => originalSubtotalCents / 100;
  double get deliveryFee => deliveryFeeCents / 100;
  double get serviceFee => serviceFeeCents / 100;
  double get discount => discountCents / 100;
  double get total => totalCents / 100;
  double get minOrder => minOrderCents / 100;
  double get missingForMinOrder => meetsMinOrder ? 0 : (minOrderCents - subtotalCents) / 100;
  double get missingForCoupon => missingForCouponCents / 100;
}

/// Resultado da comparação entre os apps, já ordenado do mais barato ao mais caro.
class Comparison {
  /// Apps disponíveis que atingem o pedido mínimo, depois os que não atingem,
  /// e por último os indisponíveis.
  final List<PriceQuote> ranked;

  const Comparison(this.ranked);

  List<PriceQuote> get available => ranked.where((q) => q.isAvailable).toList();
  List<PriceQuote> get unavailable => ranked.where((q) => !q.isAvailable).toList();

  /// Grupo usado para eleger o melhor: quem atinge o pedido mínimo
  /// (ou, se ninguém atinge, todos os disponíveis).
  List<PriceQuote> get _contenders {
    final ok = available.where((q) => q.meetsMinOrder).toList();
    return ok.isNotEmpty ? ok : available;
  }

  PriceQuote? get best => _contenders.isEmpty ? null : _contenders.first;
  PriceQuote? get worst => _contenders.isEmpty ? null : _contenders.last;

  /// Só existe comparação de verdade com 2 ou mais apps disponíveis.
  bool get hasComparison => _contenders.length >= 2;

  bool get isTie =>
      _contenders.length >= 2 && _contenders[0].totalCents == _contenders[1].totalCents;

  int get savingsCents => hasComparison ? worst!.totalCents - best!.totalCents : 0;
  double get savings => savingsCents / 100;
  double get savingsRatio =>
      hasComparison && worst!.totalCents > 0 ? savingsCents / worst!.totalCents : 0;

  bool isBest(PriceQuote quote) =>
      best != null && quote.isAvailable && quote.totalCents == best!.totalCents && _contenders.contains(quote);
}
