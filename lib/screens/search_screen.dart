import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../data/models/dish.dart';
import '../data/models/food_category.dart';
import '../data/models/restaurant.dart';
import '../data/search_filters.dart';
import '../ui/theme.dart';
import '../widgets/category_tile.dart';
import '../widgets/dish_tile.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/search_filters_sheet.dart';
import '../widgets/section_header.dart';

/// Busca unificada: a pessoa digita o que quer comer e vê os pratos
/// (com o preço em cada app) e os restaurantes.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _popular = [
    'burger',
    'pizza',
    'sushi',
    'açaí',
    'poke',
    'esfiha',
    'lasanha',
    'tacos',
    'brownie',
    'pão de queijo',
  ];

  /// Buscas recentes da sessão (somem ao fechar o app).
  static final List<String> _recent = [];

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  SearchFilters _filters = const SearchFilters();

  @override
  void initState() {
    super.initState();
    AppServices.searchRequest.addListener(_onExternalRequest);
    _onExternalRequest();
  }

  @override
  void dispose() {
    AppServices.searchRequest.removeListener(_onExternalRequest);
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Pedido vindo da Home: texto vazio = só focar o campo; com texto = buscar.
  void _onExternalRequest() {
    final request = AppServices.searchRequest.value;
    if (request == null) return;
    AppServices.searchRequest.value = null;
    if (request.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
      return;
    }
    _search(request);
  }

  void _search(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _commit(text);
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = text.trim()));
  }

  void _commit(String text) {
    final query = text.trim();
    setState(() => _query = query);
    if (query.isEmpty) return;
    _recent
      ..remove(query)
      ..insert(0, query);
    if (_recent.length > 6) _recent.removeLast();
  }

  Future<void> _openFilters() async {
    final result = await showSearchFiltersSheet(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: _commit,
                      decoration: InputDecoration(
                        hintText: 'Prato, restaurante ou categoria',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.orange),
                        fillColor: AppColors.bgGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
                        ),
                        suffixIcon: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) => _controller.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: 'Limpar',
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    _commit('');
                                    _focus.requestFocus();
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Filtros',
                    onPressed: _openFilters,
                    icon: Badge(
                      isLabelVisible: _filters.isActive,
                      label: Text('${_filters.activeCount}'),
                      backgroundColor: AppColors.orange,
                      child: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _Suggestions(
                      popular: _popular,
                      recent: _recent,
                      onPick: _search,
                      onClearRecent: () => setState(_recent.clear),
                    )
                  : _Results(query: _query, filters: _filters, onPick: _search),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> popular;
  final List<String> recent;
  final ValueChanged<String> onPick;
  final VoidCallback onClearRecent;

  const _Suggestions({
    required this.popular,
    required this.recent,
    required this.onPick,
    required this.onClearRecent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (recent.isNotEmpty) ...[
          SectionHeader(
            title: 'Buscas recentes',
            actionLabel: 'Limpar',
            onAction: onClearRecent,
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          ),
          for (final term in recent)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.history_rounded, color: AppColors.textGrey),
              title: Text(term, style: AppText.body2.copyWith(color: AppColors.textBlack)),
              trailing: const Icon(Icons.north_west_rounded, size: 18, color: AppColors.textGrey),
              onTap: () => onPick(term),
            ),
        ],
        const SectionHeader(title: 'Buscas populares', padding: EdgeInsets.fromLTRB(20, 16, 12, 10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in popular)
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.orange),
                  label: Text(term),
                  onPressed: () => onPick(term),
                ),
            ],
          ),
        ),
        const SectionHeader(title: 'Categorias', padding: EdgeInsets.fromLTRB(20, 24, 12, 10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              for (final category in FoodCategory.all)
                CategoryCard(category: category, onTap: () => onPick(category.label)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  final String query;
  final SearchFilters filters;
  final ValueChanged<String> onPick;

  const _Results({required this.query, required this.filters, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final List<(Restaurant, Dish)> dishes = filters.applyToDishes(catalog.searchDishes(query));
    final List<Restaurant> restaurants = filters.applyToRestaurants(catalog.searchRestaurants(query));

    if (dishes.isEmpty && restaurants.isEmpty) {
      return _EmptyResults(query: query, onPick: onPick);
    }

    return DefaultTabController(
      key: ValueKey(query),
      length: 2,
      initialIndex: dishes.isEmpty ? 1 : 0,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Pratos (${dishes.length})'),
              Tab(text: 'Restaurantes (${restaurants.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                dishes.isEmpty
                    ? const _NoneInTab(text: 'Nenhum prato com esse nome — veja a aba Restaurantes.')
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: dishes.length,
                        separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
                        itemBuilder: (context, i) {
                          final (restaurant, dish) = dishes[i];
                          return DishTile(
                            restaurant: restaurant,
                            dish: dish,
                            showRestaurant: true,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.compare,
                              arguments: CompareArgs(restaurantId: restaurant.id, dishId: dish.id),
                            ),
                          );
                        },
                      ),
                restaurants.isEmpty
                    ? const _NoneInTab(text: 'Nenhum restaurante com esse nome — veja a aba Pratos.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        itemCount: restaurants.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => RestaurantCard(
                          restaurant: restaurants[i],
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.restaurant,
                            arguments: restaurants[i].id,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoneInTab extends StatelessWidget {
  final String text;

  const _NoneInTab({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: AppText.body2),
        ),
      );
}

class _EmptyResults extends StatelessWidget {
  final String query;
  final ValueChanged<String> onPick;

  const _EmptyResults({required this.query, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 38, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            Text('Nada encontrado para "$query"', textAlign: TextAlign.center, style: AppText.h5),
            const SizedBox(height: 6),
            Text(
              'Confira a ortografia ou tente um termo mais geral.',
              textAlign: TextAlign.center,
              style: AppText.body2,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final term in const ['pizza', 'burger', 'açaí'])
                  ActionChip(label: Text('Buscar "$term"'), onPressed: () => onPick(term)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
