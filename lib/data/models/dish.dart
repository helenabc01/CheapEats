import 'json_utils.dart';

/// Preço de um prato em um app específico.
class DishPrice {
  final String dishId;
  final String platformId;
  final double price;

  /// Preço "de" (riscado) quando o app está com promoção no item.
  final double? originalPrice;

  /// `false` = o app vende o item, mas ele está esgotado agora.
  final bool available;

  const DishPrice({
    required this.dishId,
    required this.platformId,
    required this.price,
    this.originalPrice,
    this.available = true,
  });

  bool get isPromo => originalPrice != null && originalPrice! > price;

  factory DishPrice.fromJson(Map<String, dynamic> json) => DishPrice(
        dishId: json['dish_id'] as String,
        platformId: json['platform_id'] as String,
        price: toDouble(json['price']),
        originalPrice: toDoubleOrNull(json['original_price']),
        available: toBool(json['available'], true),
      );
}

class Dish {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String section;
  final int serves;
  final String? imageUrl;
  final bool isPopular;
  final int sortOrder;
  final List<DishPrice> prices;

  const Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.section,
    required this.serves,
    required this.imageUrl,
    required this.isPopular,
    required this.sortOrder,
    required this.prices,
  });

  factory Dish.fromJson(Map<String, dynamic> json, {List<DishPrice> prices = const []}) => Dish(
        id: json['id'] as String,
        restaurantId: json['restaurant_id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        section: (json['section'] as String?) ?? 'Cardápio',
        serves: toInt(json['serves'], 1),
        imageUrl: json['image_url'] as String?,
        isPopular: toBool(json['is_popular']),
        sortOrder: toInt(json['sort_order']),
        prices: prices,
      );

  /// Preço no app (ou `null` se o app não vende este item).
  DishPrice? priceOn(String platformId) {
    for (final p in prices) {
      if (p.platformId == platformId) return p;
    }
    return null;
  }

  /// Menor preço de cardápio entre os apps onde o item está disponível.
  double? get lowestPrice {
    final available = prices.where((p) => p.available).map((p) => p.price);
    if (available.isEmpty) return null;
    return available.reduce((a, b) => a < b ? a : b);
  }
}
