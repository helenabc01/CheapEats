import 'dart:convert';

import 'package:flutter/services.dart';

import '../catalog.dart';
import 'catalog_repository.dart';

/// Lê os dados simulados de `assets/data/cheapeats_mock.json`.
/// O mesmo arquivo gera o `supabase/seed.sql` (tool/gerar_seed_sql.dart).
class MockCatalogRepository implements CatalogRepository {
  static const assetPath = 'assets/data/cheapeats_mock.json';

  final AssetBundle bundle;

  MockCatalogRepository({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  @override
  DataSource get source => DataSource.local;

  @override
  Future<Catalog> load() async {
    // `load` + `utf8.decode` em vez de `loadString`: arquivos > 50 KB fariam o
    // `loadString` abrir um isolate só para decodificar ~80 KB (e isso trava
    // nos testes de widget).
    final bytes = await bundle.load(assetPath);
    final raw = utf8.decode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return Catalog.fromTables(jsonDecode(raw) as Map<String, dynamic>);
  }
}
