import 'package:flutter/foundation.dart';

/// Restaurantes favoritos do usuário (o coração na tela do restaurante).
///
/// Hoje os favoritos ficam só em memória (somem ao recarregar o app).
/// TODO(PARTE-3): salvar e carregar com `shared_preferences` e criar a tela
/// de Favoritos (`lib/screens/favorites_screen.dart`).
class FavoritesController extends ChangeNotifier {
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String restaurantId) => _ids.contains(restaurantId);

  void toggle(String restaurantId) {
    if (!_ids.remove(restaurantId)) _ids.add(restaurantId);
    notifyListeners();
  }
}
