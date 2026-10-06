import 'json_utils.dart';

enum CouponType {
  /// Desconto percentual sobre os itens (com teto em `maxDiscount`).
  percent,

  /// Valor fixo em reais.
  fixed,

  /// Zera a taxa de entrega.
  freeDelivery;

  static CouponType parse(String value) => switch (value) {
        'percent' => CouponType.percent,
        'free_delivery' => CouponType.freeDelivery,
        _ => CouponType.fixed,
      };
}

class Coupon {
  final String id;
  final String platformId;

  /// `null` = vale para todos os restaurantes do app.
  final String? restaurantId;
  final String code;
  final String title;
  final String description;
  final CouponType type;
  final double value;
  final double? maxDiscount;
  final double minOrder;

  /// Só vale para quem nunca pediu nesse app.
  final bool firstOrderOnly;
  final DateTime expiresAt;

  const Coupon({
    required this.id,
    required this.platformId,
    required this.restaurantId,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.maxDiscount,
    required this.minOrder,
    required this.firstOrderOnly,
    required this.expiresAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: json['id'] as String,
        platformId: json['platform_id'] as String,
        restaurantId: json['restaurant_id'] as String?,
        code: json['code'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        type: CouponType.parse(json['type'] as String),
        value: toDouble(json['value']),
        maxDiscount: toDoubleOrNull(json['max_discount']),
        minOrder: toDouble(json['min_order']),
        firstOrderOnly: toBool(json['first_order_only']),
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );

  /// O cupom vale até o fim do dia de `expiresAt`.
  bool isExpired([DateTime? now]) {
    final today = now ?? DateTime.now();
    final lastDay = DateTime(expiresAt.year, expiresAt.month, expiresAt.day, 23, 59, 59);
    return today.isAfter(lastDay);
  }

  bool appliesToRestaurant(String id) => restaurantId == null || restaurantId == id;

  /// Desconto em centavos para um pedido que já cumpre as regras do cupom.
  int discountCents({required int subtotalCents, required int deliveryFeeCents}) {
    switch (type) {
      case CouponType.percent:
        var discount = (subtotalCents * value / 100).round();
        if (maxDiscount != null) {
          final cap = (maxDiscount! * 100).round();
          if (discount > cap) discount = cap;
        }
        return discount;
      case CouponType.fixed:
        final fixed = (value * 100).round();
        return fixed > subtotalCents ? subtotalCents : fixed;
      case CouponType.freeDelivery:
        return deliveryFeeCents;
    }
  }
}
