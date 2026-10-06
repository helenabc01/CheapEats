import 'dart:convert';
import 'dart:io';

import 'package:cheapeats_app/data/catalog.dart';

/// Carrega o mesmo JSON de dados simulados que o app usa.
Catalog loadMockCatalog() {
  final raw = File('assets/data/cheapeats_mock.json').readAsStringSync();
  return Catalog.fromTables(jsonDecode(raw) as Map<String, dynamic>);
}

/// Data fixa para os testes não dependerem do dia em que rodam.
final testNow = DateTime(2026, 10, 6, 12);
