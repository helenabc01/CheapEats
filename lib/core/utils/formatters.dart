import 'package:intl/intl.dart';

/// Formatação padrão do app (pt-BR).
class Fmt {
  Fmt._();

  static final NumberFormat _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final NumberFormat _decimal1 = NumberFormat('0.0', 'pt_BR');

  /// 12.9 -> "R$ 12,90"
  static String brl(num value) => _brl.format(value);

  /// Taxa de entrega: 0 vira "Grátis".
  static String fee(num value) => value <= 0 ? 'Grátis' : brl(value);

  /// 0.183 -> "18%"
  static String percent(double ratio) => '${(ratio * 100).round()}%';

  /// 4.8 -> "4,8"
  static String rating(double value) => _decimal1.format(value);

  /// 1.2 -> "1,2 km"
  static String distance(double km) => '${_decimal1.format(km)} km';

  /// (30, 45) -> "30–45 min"
  static String deliveryTime(int min, int max) => '$min–$max min';

  /// 2140 -> "2,1 mil"
  static String compact(int value) =>
      value >= 1000 ? '${_decimal1.format(value / 1000)} mil' : '$value';
}
