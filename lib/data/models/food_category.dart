import 'package:flutter/material.dart';

/// Categorias exibidas na Home e na Busca (o `id` é o mesmo do banco).
class FoodCategory {
  final String id;
  final String label;

  /// Ícone de reserva (sem internet a foto não carrega).
  final IconData icon;
  final Color tint;

  /// Foto da categoria (Unsplash, licença livre).
  final String imageUrl;

  const FoodCategory(this.id, this.label, this.icon, this.tint, this.imageUrl);

  static String _photo(String id) =>
      'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=240&h=240&q=70';

  static final all = <FoodCategory>[
    FoodCategory('lanches', 'Lanches', Icons.lunch_dining_rounded, const Color(0xFFFFE3D6),
        _photo('1568901346375-23c9450c58cd')),
    FoodCategory('pizza', 'Pizza', Icons.local_pizza_rounded, const Color(0xFFFFE6E1),
        _photo('1513104890138-7c749659a591')),
    FoodCategory('japonesa', 'Japonesa', Icons.set_meal_rounded, const Color(0xFFE3F1FF),
        _photo('1579584425555-c3ce17fd4351')),
    FoodCategory('brasileira', 'Brasileira', Icons.rice_bowl_rounded, const Color(0xFFFFF1D6),
        _photo('1786052599586-344b949de861')),
    FoodCategory('saudavel', 'Saudável', Icons.eco_rounded, const Color(0xFFDDF3E4),
        _photo('1546069901-ba9599a7e63c')),
    FoodCategory('acai', 'Açaí', Icons.icecream_rounded, const Color(0xFFEDE3FA),
        _photo('1627308594190-a057cd4bfac8')),
    FoodCategory('arabe', 'Árabe', Icons.kebab_dining_rounded, const Color(0xFFF6E9DC),
        _photo('1768812910769-d037b90aee77')),
    FoodCategory('mexicana', 'Mexicana', Icons.local_fire_department_rounded, const Color(0xFFFFE9D1),
        _photo('1599974579688-8dbdd335c77f')),
    FoodCategory('italiana', 'Italiana', Icons.dinner_dining_rounded, const Color(0xFFE5F4EA),
        _photo('1709429790175-b02bb1b19207')),
    FoodCategory('doces', 'Doces', Icons.cake_rounded, const Color(0xFFFDE4EE),
        _photo('1636743715220-d8f8dd900b87')),
    FoodCategory('padaria', 'Padaria', Icons.bakery_dining_rounded, const Color(0xFFF3EBDD),
        _photo('1721277000438-488066df7ac8')),
  ];

  static FoodCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}
