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

/// Filtros da tela de Busca.
///
/// O modelo já existe e a Busca já guarda/aplica um [SearchFilters], mas os
/// métodos `apply...` ainda devolvem a lista sem filtrar.
/// TODO(PARTE-2): implementar os filtros e a ordenação abaixo e o bottom sheet
/// em `lib/widgets/search_filters_sheet.dart`.
class SearchFilters {
  /// Ids de categoria (ver `FoodCategory.all`).
  final Set<String> categories;

  /// Ids de app (ifood, 99food, keeta): mostrar só o que existe nesses apps.
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

  // TODO(PARTE-2): filtrar por categoria, app, frete grátis e ordenar por [sort].
  List<Restaurant> applyToRestaurants(List<Restaurant> restaurants) => restaurants;

  // TODO(PARTE-2): filtrar por categoria, app, preço máximo e ordenar por [sort].
  List<(Restaurant, Dish)> applyToDishes(List<(Restaurant, Dish)> dishes) => dishes;
}
