import 'package:flutter/foundation.dart';

import '../../core/config/supabase_config.dart';
import '../catalog.dart';
import 'mock_catalog_repository.dart';
import 'supabase_catalog_repository.dart';

/// De onde vieram os dados exibidos no app.
enum DataSource {
  supabase('Supabase', 'Dados carregados do banco Supabase'),
  local('Dados locais', 'Usando os dados simulados do app (modo offline)');

  final String label;
  final String description;
  const DataSource(this.label, this.description);
}

/// Contrato de qualquer fonte de catálogo (mock local ou Supabase).
abstract class CatalogRepository {
  DataSource get source;
  Future<Catalog> load();
}

/// Resultado do carregamento: o catálogo e a fonte usada.
class CatalogLoadResult {
  final Catalog catalog;
  final DataSource source;

  /// Motivo de ter caído no modo local (quando o Supabase falhou).
  final String? fallbackReason;

  const CatalogLoadResult(this.catalog, this.source, [this.fallbackReason]);
}

/// Tenta o Supabase (se configurado) e, se der erro ou demorar, usa o mock local.
/// Assim a apresentação nunca quebra por falta de internet.
class CatalogLoader {
  final CatalogRepository remote;
  final CatalogRepository local;

  CatalogLoader({CatalogRepository? remote, CatalogRepository? local})
      : remote = remote ?? SupabaseCatalogRepository(),
        local = local ?? MockCatalogRepository();

  Future<CatalogLoadResult> load({bool useRemote = true}) async {
    if (useRemote && SupabaseConfig.isConfigured) {
      try {
        final catalog = await remote.load().timeout(SupabaseConfig.timeout);
        if (catalog.restaurants.isEmpty) {
          throw StateError('o banco respondeu, mas não há restaurantes (rodou o seed.sql?)');
        }
        return CatalogLoadResult(catalog, DataSource.supabase);
      } catch (error) {
        debugPrint('[CheapEats] Supabase indisponível, usando dados locais: $error');
        final catalog = await local.load();
        return CatalogLoadResult(catalog, DataSource.local, error.toString());
      }
    }
    final catalog = await local.load();
    return CatalogLoadResult(
      catalog,
      DataSource.local,
      SupabaseConfig.isConfigured ? null : 'Supabase não configurado',
    );
  }
}
