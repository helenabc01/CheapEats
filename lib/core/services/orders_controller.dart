import 'package:flutter/foundation.dart';

import '../../data/models/price_quote.dart';
import '../../data/models/restaurant.dart';
import 'session_controller.dart';

/// Um pedido feito pelo CheapEats (o usuário foi redirecionado para o app).
class OrderRecord {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String platformId;
  final String itemsSummary;
  final double total;

  /// Quanto o usuário economizou em relação ao app mais caro.
  final double savings;
  final DateTime createdAt;

  const OrderRecord({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.platformId,
    required this.itemsSummary,
    required this.total,
    required this.savings,
    required this.createdAt,
  });
}

/// Histórico de pedidos.
///
/// Hoje guarda só em memória.
/// TODO(PARTE-3): salvar cada pedido na tabela `orders` do Supabase (com
/// fallback local), carregar um histórico simulado e criar a aba Pedidos
/// (`lib/screens/orders_screen.dart`).
class OrdersController extends ChangeNotifier {
  final SessionController session;
  final List<OrderRecord> _orders = [];

  OrdersController(this.session);

  List<OrderRecord> get orders => List.unmodifiable(_orders);

  double get totalSavings => _orders.fold(0, (sum, o) => sum + o.savings);

  Future<void> register({
    required Restaurant restaurant,
    required List<OrderItem> items,
    required PriceQuote chosen,
    required Comparison comparison,
  }) async {
    final order = OrderRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      platformId: chosen.platform.id,
      itemsSummary: items.map((i) => '${i.quantity}× ${i.dish.name}').join(', '),
      total: chosen.total,
      savings: comparison.isBest(chosen) ? comparison.savings : 0,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    session.markOrderedOn(chosen.platform.id);
    notifyListeners();
  }
}
