import 'models/coupon.dart';
import 'models/delivery_platform.dart';
import 'models/dish.dart';
import 'models/restaurant.dart';

/// Todo o catálogo do app em memória (apps, restaurantes, pratos e cupons).
///
/// É montado a partir das "tabelas" no mesmo formato do banco, então serve
/// tanto para o JSON local quanto para o Supabase.
class Catalog {
  final List<DeliveryPlatform> platforms;
  final List<Restaurant> restaurants;
  final List<Coupon> coupons;

  Catalog({required this.platforms, required this.restaurants, required this.coupons});

  /// [tables] tem as chaves: platforms, restaurants, restaurant_platforms,
  /// dishes, dish_prices e coupons (listas de linhas).
  factory Catalog.fromTables(Map<String, dynamic> tables) {
    List<Map<String, dynamic>> rows(String key) =>
        ((tables[key] as List?) ?? const []).map((r) => Map<String, dynamic>.from(r as Map)).toList();

    final platforms = rows('platforms').map(DeliveryPlatform.fromJson).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final platformOrder = {for (final p in platforms) p.id: p.sortOrder};

    final pricesByDish = <String, List<DishPrice>>{};
    for (final row in rows('dish_prices')) {
      final price = DishPrice.fromJson(row);
      pricesByDish.putIfAbsent(price.dishId, () => []).add(price);
    }

    final dishesByRestaurant = <String, List<Dish>>{};
    for (final row in rows('dishes')) {
      final prices = (pricesByDish[row['id']] ?? [])
        ..sort((a, b) => (platformOrder[a.platformId] ?? 0).compareTo(platformOrder[b.platformId] ?? 0));
      final dish = Dish.fromJson(row, prices: prices);
      dishesByRestaurant.putIfAbsent(dish.restaurantId, () => []).add(dish);
    }

    final infosByRestaurant = <String, List<RestaurantPlatformInfo>>{};
    for (final row in rows('restaurant_platforms')) {
      final info = RestaurantPlatformInfo.fromJson(row);
      infosByRestaurant.putIfAbsent(info.restaurantId, () => []).add(info);
    }

    final restaurants = rows('restaurants').map((row) {
      final id = row['id'] as String;
      final infos = (infosByRestaurant[id] ?? [])
        ..sort((a, b) => (platformOrder[a.platformId] ?? 0).compareTo(platformOrder[b.platformId] ?? 0));
      final dishes = (dishesByRestaurant[id] ?? [])..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Restaurant.fromJson(row, platforms: infos, dishes: dishes);
    }).toList();

    final coupons = rows('coupons').map(Coupon.fromJson).toList();

    return Catalog(platforms: platforms, restaurants: restaurants, coupons: coupons);
  }

  late final Map<String, DeliveryPlatform> _platformById = {for (final p in platforms) p.id: p};
  late final Map<String, Restaurant> _restaurantById = {for (final r in restaurants) r.id: r};
  late final Map<String, Dish> _dishById = {
    for (final r in restaurants)
      for (final d in r.dishes) d.id: d,
  };

  DeliveryPlatform platform(String id) => _platformById[id]!;
  DeliveryPlatform? platformOrNull(String id) => _platformById[id];
  Restaurant? restaurantById(String id) => _restaurantById[id];
  Dish? dishById(String id) => _dishById[id];

  int get dishCount => _dishById.length;

  /// Cupons válidos hoje (para a tela de cupons e para a Home).
  List<Coupon> activeCoupons([DateTime? now]) => coupons.where((c) => !c.isExpired(now)).toList();

  /// Cupons que podem valer no restaurante (dele ou gerais dos apps em que ele está).
  List<Coupon> couponsForRestaurant(Restaurant restaurant, [DateTime? now]) => coupons
      .where((c) => !c.isExpired(now) && restaurant.isOn(c.platformId) && c.appliesToRestaurant(restaurant.id))
      .toList();

  // ---------------------------------------------------------------- busca

  /// Remove acentos e caixa: "Açaí" -> "acai".
  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = text.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  static bool _matches(String haystack, List<String> terms) {
    final text = normalize(haystack);
    return terms.every(text.contains);
  }

  /// Sinônimos simples para a busca encontrar o que a pessoa quis dizer.
  /// (Termos que já são parte de outra palavra, como "massa" em "massas",
  /// não precisam estar aqui: a busca procura por trechos.)
  static const _synonyms = {
    'hamburguer': 'burger',
    'hamburger': 'burger',
    'hamburgueres': 'burger',
    'japa': 'japonesa',
    'saudaveis': 'saudavel',
  };

  static List<String> _terms(String query) => normalize(query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => _synonyms[t] ?? t)
      .toList();

  List<Restaurant> searchRestaurants(String query) {
    final terms = _terms(query);
    if (terms.isEmpty) return const [];
    return restaurants
        .where((r) => _matches('${r.name} ${r.category} ${r.description} ${r.neighborhood}', terms))
        .toList();
  }

  /// Pratos cujo nome/descrição/seção/categoria batem com a busca.
  List<(Restaurant, Dish)> searchDishes(String query) {
    final terms = _terms(query);
    if (terms.isEmpty) return const [];
    final result = <(Restaurant, Dish)>[];
    for (final r in restaurants) {
      for (final d in r.dishes) {
        if (_matches('${d.name} ${d.description} ${d.section} ${r.category} ${r.name}', terms)) {
          result.add((r, d));
        }
      }
    }
    return result;
  }

  List<Restaurant> byCategory(String categoryId) =>
      restaurants.where((r) => r.category == categoryId).toList();
}
