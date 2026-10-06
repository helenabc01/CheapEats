import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/price_quote.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/catalog_repository.dart';
import '../app_services.dart';
import 'session_controller.dart';

/// Um pedido feito pelo CheapEats (o usuário foi redirecionado para o app).
class OrderRecord {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String platformId;
  final String itemsSummary;
  final double total;
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

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    return OrderRecord(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      platformId: json['platform_id'] as String,
      itemsSummary: json['items_summary'] as String,
      total: (json['total'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'platform_id': platformId,
      'items_summary': itemsSummary,
      'total': total,
      'savings': savings,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Histórico de pedidos.
class OrdersController extends ChangeNotifier {
  final SessionController session;
  final List<OrderRecord> _orders = [];
  String? _deviceId;

  OrdersController(this.session);

  List<OrderRecord> get orders => List.unmodifiable(_orders);

  double get totalSavings => _orders.fold(0, (sum, o) => sum + o.savings);

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    if (_deviceId == null) {
      _deviceId = DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString('device_id', _deviceId!);
    }
    return _deviceId!;
  }

  Future<void> load() async {
    final deviceId = await _getDeviceId();
    _orders.clear();

    if (AppServices.dataSource == DataSource.supabase) {
      try {
        final data = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('device_id', deviceId)
            .order('created_at', ascending: false);
        
        _orders.addAll((data as List).map((json) => OrderRecord.fromJson(json)));
      } catch (e) {
        debugPrint('[CheapEats] Falha ao carregar pedidos do Supabase: $e');
        _loadMockOrders();
      }
    } else {
      _loadMockOrders();
    }
    notifyListeners();
  }

  void _loadMockOrders() {
    _orders.addAll([
      OrderRecord(
        id: 'mock-1',
        restaurantId: 'bella-napoli',
        restaurantName: 'Bella Napoli',
        platformId: 'ifood',
        itemsSummary: '1× Pizza Margherita',
        total: 55.90,
        savings: 12.00,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      OrderRecord(
        id: 'mock-2',
        restaurantId: 'sushi-kenzo',
        restaurantName: 'Sushi Kenzo',
        platformId: 'keeta',
        itemsSummary: '1× Combinado 40 peças',
        total: 105.00,
        savings: 25.50,
        createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      ),
      OrderRecord(
        id: 'mock-3',
        restaurantId: 'tia-lu',
        restaurantName: 'Tia Lu Comida Caseira',
        platformId: 'aiqfome',
        itemsSummary: '2× PF Bife Acebolado',
        total: 42.00,
        savings: 8.90,
        createdAt: DateTime.now().subtract(const Duration(days: 10, hours: 2)),
      ),
    ]);
  }

  Future<void> register({
    required Restaurant restaurant,
    required List<OrderItem> items,
    required PriceQuote chosen,
    required Comparison comparison,
  }) async {
    final savings = comparison.isBest(chosen) ? comparison.savings : 0.0;
    
    final order = OrderRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      platformId: chosen.platform.id,
      itemsSummary: items.map((i) => '${i.quantity}× ${i.dish.name}').join(', '),
      total: chosen.total,
      savings: savings,
      createdAt: DateTime.now(),
    );
    
    _orders.insert(0, order);
    session.markOrderedOn(chosen.platform.id);
    notifyListeners();

    if (AppServices.dataSource == DataSource.supabase) {
      try {
        final deviceId = await _getDeviceId();
        await Supabase.instance.client.from('orders').insert({
          'device_id': deviceId,
          'restaurant_id': order.restaurantId,
          'restaurant_name': order.restaurantName,
          'platform_id': order.platformId,
          'items_summary': order.itemsSummary,
          'total': order.total,
          'savings': order.savings,
        });
      } catch (e) {
        debugPrint('Falha ao salvar pedido no Supabase: $e');
      }
    }
  }
}
