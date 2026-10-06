import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/utils/formatters.dart';
import '../data/models/food_category.dart';
import '../data/search_filters.dart';
import '../ui/theme.dart';
import 'platform_badge.dart';

/// Abre o bottom sheet de filtros e devolve os filtros escolhidos
/// (ou `null` se o usuário fechar sem aplicar).
Future<SearchFilters?> showSearchFiltersSheet(BuildContext context, SearchFilters current) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SearchFiltersSheet(initial: current),
  );
}

class _SearchFiltersSheet extends StatefulWidget {
  final SearchFilters initial;

  const _SearchFiltersSheet({required this.initial});

  @override
  State<_SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<_SearchFiltersSheet> {
  late SearchFilters _filters = widget.initial;

  Set<String> _toggle(Set<String> set, String id, bool selected) =>
      selected ? {...set, id} : ({...set}..remove(id));

  @override
  Widget build(BuildContext context) {
    final platforms = AppServices.catalog.platforms;
    final maxPrice = _filters.maxPrice;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Filtros e ordenação', style: AppText.h4),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                const _Title('Ordenar por'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sort in SearchSort.values)
                      ChoiceChip(
                        label: Text(sort.label),
                        selected: _filters.sort == sort,
                        checkmarkColor: AppColors.orange,
                        onSelected: (_) => setState(() => _filters = _filters.copyWith(sort: sort)),
                      ),
                  ],
                ),
                const _Title('Categorias'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in FoodCategory.all)
                      FilterChip(
                        avatar: Icon(category.icon),
                        label: Text(category.label),
                        selected: _filters.categories.contains(category.id),
                        checkmarkColor: AppColors.orange,
                        onSelected: (selected) => setState(() => _filters = _filters.copyWith(
                              categories: _toggle(_filters.categories, category.id, selected),
                            )),
                      ),
                  ],
                ),
                const _Title('Apps', subtitle: 'Mostra só o que é vendido nos apps escolhidos'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final platform in platforms)
                      FilterChip(
                        label: PlatformBadge(platform: platform, small: true),
                        selected: _filters.platforms.contains(platform.id),
                        checkmarkColor: AppColors.orange,
                        onSelected: (selected) => setState(() => _filters = _filters.copyWith(
                              platforms: _toggle(_filters.platforms, platform.id, selected),
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Só entrega grátis', style: AppText.h6),
                  subtitle: Text('Restaurantes com frete grátis em algum app', style: AppText.caption),
                  value: _filters.freeDeliveryOnly,
                  onChanged: (value) => setState(() => _filters = _filters.copyWith(freeDeliveryOnly: value)),
                ),
                _Title(
                  'Preço máximo do prato',
                  trailing: Text(
                    maxPrice == null ? 'Qualquer preço' : 'Até ${Fmt.brl(maxPrice)}',
                    style: AppText.price(size: 14, color: AppColors.orange),
                  ),
                ),
                Slider(
                  min: SearchFilters.minPriceLimit,
                  max: SearchFilters.maxPriceLimit,
                  divisions: 38,
                  value: maxPrice ?? SearchFilters.maxPriceLimit,
                  label: maxPrice == null ? 'Sem limite' : Fmt.brl(maxPrice),
                  onChanged: (value) => setState(() {
                    // No limite de cima, o filtro de preço fica desligado.
                    _filters = value >= SearchFilters.maxPriceLimit
                        ? _filters.copyWith(clearMaxPrice: true)
                        : _filters.copyWith(maxPrice: value);
                  }),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Fmt.brl(SearchFilters.minPriceLimit), style: AppText.caption),
                    Text('${Fmt.brl(SearchFilters.maxPriceLimit)}+', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const SearchFilters()),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _filters),
                    child: Text(_filters.isActive ? 'Aplicar (${_filters.activeCount})' : 'Aplicar'),
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

class _Title extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? trailing;

  const _Title(this.text, {this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppText.h6),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.caption),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
