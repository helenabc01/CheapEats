import 'package:flutter/material.dart';

import 'dish.dart';
import 'json_utils.dart';

/// Condições do restaurante em um app: frete, tempo e pedido mínimo.
class RestaurantPlatformInfo {
  final String restaurantId;
  final String platformId;
  final double deliveryFee;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double minOrder;

  const RestaurantPlatformInfo({
    required this.restaurantId,
    required this.platformId,
    required this.deliveryFee,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.minOrder,
  });

  factory RestaurantPlatformInfo.fromJson(Map<String, dynamic> json) => RestaurantPlatformInfo(
        restaurantId: json['restaurant_id'] as String,
        platformId: json['platform_id'] as String,
        deliveryFee: toDouble(json['delivery_fee']),
        deliveryTimeMin: toInt(json['delivery_time_min']),
        deliveryTimeMax: toInt(json['delivery_time_max']),
        minOrder: toDouble(json['min_order']),
      );
}

class Restaurant {
  final String id;
  final String name;
  final String category;
  final String description;
  final String neighborhood;
  final double distanceKm;
  final double rating;
  final int reviewCount;

  /// 1 = $, 2 = $$, 3 = $$$
  final int priceLevel;
  final bool isOpen;

  /// Horário de abertura quando está fechado (ex.: "18:00").
  final String? opensAt;
  final String? imageUrl;
  final Color brandColor;

  /// Posição no mapa.
  final double latitude;
  final double longitude;

  /// Apps em que o restaurante está, na ordem dos apps.
  final List<RestaurantPlatformInfo> platforms;
  final List<Dish> dishes;

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.neighborhood,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.isOpen,
    required this.opensAt,
    required this.imageUrl,
    required this.brandColor,
    required this.latitude,
    required this.longitude,
    required this.platforms,
    required this.dishes,
  });

  factory Restaurant.fromJson(
    Map<String, dynamic> json, {
    List<RestaurantPlatformInfo> platforms = const [],
    List<Dish> dishes = const [],
  }) =>
      Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        description: (json['description'] as String?) ?? '',
        neighborhood: (json['neighborhood'] as String?) ?? '',
        distanceKm: toDouble(json['distance_km']),
        rating: toDouble(json['rating']),
        reviewCount: toInt(json['review_count']),
        priceLevel: toInt(json['price_level'], 2),
        isOpen: toBool(json['is_open'], true),
        opensAt: json['opens_at'] as String?,
        imageUrl: json['image_url'] as String?,
        brandColor: colorFromHex(json['brand_color'] as String?),
        latitude: toDouble(json['latitude']),
        longitude: toDouble(json['longitude']),
        platforms: platforms,
        dishes: dishes,
      );

  RestaurantPlatformInfo? infoFor(String platformId) {
    for (final info in platforms) {
      if (info.platformId == platformId) return info;
    }
    return null;
  }

  bool isOn(String platformId) => infoFor(platformId) != null;

  /// Seções do cardápio na ordem em que aparecem.
  List<String> get sections {
    final result = <String>[];
    for (final dish in dishes) {
      if (!result.contains(dish.section)) result.add(dish.section);
    }
    return result;
  }

  /// Faixa de tempo de entrega considerando todos os apps.
  (int, int) get deliveryRange {
    if (platforms.isEmpty) return (0, 0);
    final min = platforms.map((p) => p.deliveryTimeMin).reduce((a, b) => a < b ? a : b);
    final max = platforms.map((p) => p.deliveryTimeMax).reduce((a, b) => a > b ? a : b);
    return (min, max);
  }

  /// Menor taxa de entrega entre os apps.
  double get lowestDeliveryFee => cheapestDelivery?.deliveryFee ?? 0;

  /// App com a menor taxa de entrega.
  RestaurantPlatformInfo? get cheapestDelivery =>
      platforms.isEmpty ? null : platforms.reduce((a, b) => b.deliveryFee < a.deliveryFee ? b : a);

  String get initials {
    final words = name.split(RegExp(r'\s+')).where((w) => w.length > 2 || w == '&').toList();
    final letters = words.where((w) => w != '&').take(2).map((w) => w[0].toUpperCase()).join();
    return letters.isEmpty ? name[0].toUpperCase() : letters;
  }
}
