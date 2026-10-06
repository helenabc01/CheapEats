import 'package:flutter/material.dart';

import '../data/search_filters.dart';
import 'coming_soon.dart';

/// Abre o bottom sheet de filtros e devolve os filtros escolhidos
/// (ou `null` se o usuário fechar sem aplicar).
///
/// TODO(PARTE-2): trocar o conteúdo provisório por um bottom sheet com:
///   - chips de categoria (`FoodCategory.all`)
///   - chips de app (iFood, 99Food, Keeta)
///   - switch "Só entrega grátis"
///   - slider de preço máximo
///   - ordenação (`SearchSort.values`)
///   - botões "Limpar" e "Aplicar" (este último faz `Navigator.pop(context, novosFiltros)`)
Future<SearchFilters?> showSearchFiltersSheet(BuildContext context, SearchFilters current) async {
  await showComingSoonSheet(
    context,
    icon: Icons.tune_rounded,
    title: 'Filtros e ordenação',
    description: 'Filtre por categoria, app, frete grátis e preço máximo, '
        'e ordene por menor preço, entrega mais rápida ou melhor avaliação.',
  );
  return null;
}
