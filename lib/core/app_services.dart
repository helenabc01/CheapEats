import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/catalog.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/services/price_calculator.dart';
import 'config/supabase_config.dart';
import 'services/address_controller.dart';
import 'services/favorites_controller.dart';
import 'services/orders_controller.dart';
import 'services/session_controller.dart';

/// Ponto único de acesso aos serviços do app (sem pacote de gerência de
/// estado: cada controller é um `ChangeNotifier` e as telas usam
/// `ListenableBuilder` para redesenhar quando algo muda).
///
/// Exemplo numa tela:
///   final catalog = AppServices.catalog;
///   ListenableBuilder(listenable: AppServices.favorites, builder: ...)
class AppServices {
  AppServices._();

  static Catalog? _catalog;
  static DataSource _dataSource = DataSource.local;
  static String? _fallbackReason;

  static final session = SessionController();
  static final address = AddressController();
  static final favorites = FavoritesController();
  static final orders = OrdersController(session);

  /// Texto enviado da Home para a aba Busca (ex.: tocar numa categoria).
  static final searchRequest = ValueNotifier<String?>(null);

  static bool get isReady => _catalog != null;
  static Catalog get catalog => _catalog!;
  static DataSource get dataSource => _dataSource;
  static String? get fallbackReason => _fallbackReason;

  /// Calculadora já configurada com a situação do usuário logado.
  static PriceCalculator get calculator =>
      PriceCalculator(catalog: catalog, firstOrderPlatforms: session.firstOrderPlatforms);

  /// Inicializa o Supabase (se houver URL e chave). Nunca lança erro:
  /// se falhar, o app segue com os dados locais.
  static Future<void> initSupabase() async {
    if (!SupabaseConfig.isConfigured || Supabase.instance.isInitialized) return;
    try {
      await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
    } catch (error) {
      debugPrint('[CheapEats] Falha ao iniciar o Supabase: $error');
    }
  }

  /// Carrega o catálogo (Supabase com fallback para o JSON local).
  static Future<void> loadCatalog({CatalogLoader? loader}) async {
    final result = await (loader ?? CatalogLoader()).load();
    _catalog = result.catalog;
    _dataSource = result.source;
    _fallbackReason = result.fallbackReason;
  }

  @visibleForTesting
  static void setCatalogForTest(Catalog catalog, {DataSource source = DataSource.local}) {
    _catalog = catalog;
    _dataSource = source;
  }
}
