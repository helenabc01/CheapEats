// Gera supabase/seed.sql a partir de assets/data/cheapeats_mock.json.
//
// Uso (na raiz do projeto):
//   dart run tool/gerar_seed_sql.dart
//
// Assim o banco e o modo offline do app têm exatamente os mesmos dados.
// Edite o JSON, rode este script e cole o seed.sql de novo no Supabase.
import 'dart:convert';
import 'dart:io';

const _inputPath = 'assets/data/cheapeats_mock.json';
const _outputPath = 'supabase/seed.sql';

/// Ordem respeita as chaves estrangeiras.
const _tables = [
  'platforms',
  'restaurants',
  'restaurant_platforms',
  'dishes',
  'dish_prices',
  'coupons',
];

String _sqlValue(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return value.toString();
  return "'${value.toString().replaceAll("'", "''")}'";
}

void main() {
  final data = jsonDecode(File(_inputPath).readAsStringSync()) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln('-- =============================================================')
    ..writeln('-- CheapEats — dados SIMULADOS (gerado por tool/gerar_seed_sql.dart)')
    ..writeln('-- Não edite à mão: altere $_inputPath e gere de novo.')
    ..writeln('-- Rode DEPOIS do schema.sql. Pode rodar várias vezes (limpa antes).')
    ..writeln('-- =============================================================')
    ..writeln()
    ..writeln('begin;')
    ..writeln()
    ..writeln('truncate ${_tables.reversed.map((t) => 'public.$t').join(', ')} cascade;')
    ..writeln();

  var total = 0;
  for (final table in _tables) {
    final rows = (data[table] as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) continue;
    final columns = rows.first.keys.toList();
    out.writeln('-- $table (${rows.length})');
    out.writeln('insert into public.$table (${columns.join(', ')}) values');
    for (var i = 0; i < rows.length; i++) {
      final values = columns.map((c) => _sqlValue(rows[i][c])).join(', ');
      out.writeln('  ($values)${i == rows.length - 1 ? ';' : ','}');
    }
    out.writeln();
    total += rows.length;
  }
  out.writeln('commit;');

  File(_outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(out.toString());
  stdout.writeln('OK: $total linhas em ${_tables.length} tabelas -> $_outputPath');
}
