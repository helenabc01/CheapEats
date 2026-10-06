import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Restaurantes favoritos do usuário (o coração na tela do restaurante).
///
/// Salva e carrega com `shared_preferences`.
class FavoritesController extends ChangeNotifier {
  static const _key = 'favoritos';
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String restaurantId) => _ids.contains(restaurantId);

  Future<void> toggle(String restaurantId) async {
    if (!_ids.remove(restaurantId)) _ids.add(restaurantId);
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? []);
    notifyListeners();
  }
}
