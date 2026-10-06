import 'package:flutter/material.dart';

import '../widgets/coming_soon.dart';

/// TODO(PARTE-3): Tela de Favoritos (aberta pelo Perfil).
///
/// O que fazer (detalhes em docs/cp5/TAREFAS.md):
///   1. Listar os restaurantes de `AppServices.favorites.ids` usando o
///      `RestaurantCard` (já pronto em `lib/widgets/restaurant_card.dart`).
///   2. Tocar no card abre o restaurante (`AppRoutes.restaurant`).
///   3. Estado vazio bonito ("Toque no coração de um restaurante para salvar").
///   4. Persistir os favoritos com `shared_preferences` dentro do
///      `FavoritesController` (carregar ao abrir o app, salvar ao tocar no coração).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: const ComingSoon(
        icon: Icons.favorite_border_rounded,
        title: 'Seus restaurantes favoritos',
        description: 'Salve restaurantes no coração para comparar os preços deles rapidinho.',
      ),
    );
  }
}
