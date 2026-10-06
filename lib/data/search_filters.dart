import '../core/app_services.dart';
import 'models/dish.dart';
import 'models/restaurant.dart';

enum SearchSort {
  relevance('Relevância'),
  lowestPrice('Menor preço'),
  fastest('Entrega mais rápida'),
  bestRated('Melhor avaliação');

  final String label;
  const SearchSort(this.label);
}

/// Filtros da tela de Busca: categoria, app, frete grátis, preço máximo e
/// ordenação. A Busca guarda um [SearchFilters] e reaplica a cada mudança.
class SearchFilters {
  /// Limites do slider de preço máximo (no limite de cima = sem limite).
  static const double minPriceLimit = 10;
  static const double maxPriceLimit = 200;

  /// Ids de categoria (ver `FoodCategory.all`).
  final Set<String> categories;

  /// Ids de app (ifood, 99food, keeta, rappi, aiqfome): mostrar só o que existe nesses apps.
  final Set<String> platforms;
  final bool freeDeliveryOnly;

  /// Preço máximo do prato (menor preço entre os apps).
  final double? maxPrice;
  final SearchSort sort;

  const SearchFilters({
    this.categories = const {},
    this.platforms = const {},
    this.freeDeliveryOnly = false,
    this.maxPrice,
    this.sort = SearchSort.relevance,
  });

  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (platforms.isNotEmpty ? 1 : 0) +
      (freeDeliveryOnly ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (sort != SearchSort.relevance ? 1 : 0);

  bool get isActive => activeCount > 0;

  SearchFilters copyWith({
    Set<String>? categories,
    Set<String>? platforms,
    bool? freeDeliveryOnly,
    double? maxPrice,
    bool clearMaxPrice = false,
    SearchSort? sort,
  }) =>
      SearchFilters(
        categories: categories ?? this.categories,
        platforms: platforms ?? this.platforms,
        freeDeliveryOnly: freeDeliveryOnly ?? this.freeDeliveryOnly,
        maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
        sort: sort ?? this.sort,
      );

  List<Restaurant> applyToRestaurants(List<Restaurant> restaurants) {
    final result = restaurants.where(_keepRestaurant).toList();
    return switch (sort) {
      SearchSort.relevance => result,
      SearchSort.bestRated => _sortedBy(result, (r) => -r.rating),
      SearchSort.fastest => _sortedBy(result, (r) => r.deliveryRange.$1),
      SearchSort.lowestPrice => _sortedBy(result, (r) => r.lowestDeliveryFee),
    };
  }

  List<(Restaurant, Dish)> applyToDishes(List<(Restaurant, Dish)> dishes) {
    final result = dishes.where((entry) {
      final (restaurant, dish) = entry;
      if (!_keepRestaurant(restaurant)) return false;
      if (platforms.isNotEmpty && !platforms.any((id) => dish.priceOn(id) != null)) return false;
      if (maxPrice != null) {
        final lowest = dish.lowestPrice;
        if (lowest == null || lowest > maxPrice!) return false;
      }
      return true;
    }).toList();

    return switch (sort) {
      SearchSort.relevance => result,
      SearchSort.bestRated => _sortedBy(result, (e) => -e.$1.rating),
      SearchSort.fastest => _sortedBy(result, (e) => e.$1.deliveryRange.$1),
      SearchSort.lowestPrice => _sortedBy(result, (e) {
          final best = AppServices.calculator.compareDish(e.$1, e.$2).best;
          // Sem preço em nenhum app: vai para o fim da lista.
          return best?.total ?? double.infinity;
        }),
    };
  }

  /// Regras que valem para o restaurante (e, por tabela, para os pratos dele).
  bool _keepRestaurant(Restaurant r) {
    if (categories.isNotEmpty && !categories.contains(r.category)) return false;
    if (platforms.isNotEmpty && !platforms.any(r.isOn)) return false;
    if (freeDeliveryOnly) {
      // Com apps escolhidos, o frete grátis precisa ser em um deles.
      final infos = platforms.isEmpty
          ? r.platforms
          : r.platforms.where((p) => platforms.contains(p.platformId));
      if (!infos.any((p) => p.deliveryFee == 0)) return false;
    }
    return true;
  }

  /// Ordena sem embaralhar os empates (mantém a ordem de relevância da busca).
  static List<T> _sortedBy<T>(List<T> items, num Function(T) key) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, key(items[i]), items[i])];
    indexed.sort((a, b) {
      final byKey = a.$2.compareTo(b.$2);
      return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$3];
  }
}
