import 'package:supabase_flutter/supabase_flutter.dart';

import '../catalog.dart';
import 'catalog_repository.dart';

/// Lê o catálogo das tabelas do Supabase (ver `supabase/schema.sql`).
/// As 6 consultas rodam em paralelo e o resultado é montado pelo mesmo
/// `Catalog.fromTables` usado para o JSON local.
class SupabaseCatalogRepository implements CatalogRepository {
  static const tables = [
    'platforms',
    'restaurants',
    'restaurant_platforms',
    'dishes',
    'dish_prices',
    'coupons',
  ];

  @override
  DataSource get source => DataSource.supabase;

  @override
  Future<Catalog> load() async {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase não foi inicializado');
    }
    final client = Supabase.instance.client;
    final results = await Future.wait(tables.map((t) => client.from(t).select()));
    return Catalog.fromTables({
      for (var i = 0; i < tables.length; i++) tables[i]: results[i],
    });
  }
}
