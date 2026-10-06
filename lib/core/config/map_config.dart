import 'package:flutter/widgets.dart';

/// Configuração do mapa (OpenStreetMap: gratuito e sem chave de API).
class MapConfig {
  MapConfig._();

  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackageName = 'br.com.fiap.cheapeats';

  /// Crédito exigido pela licença do OpenStreetMap.
  static const attribution = '© colaboradores do OpenStreetMap';

  /// Os testes automatizados desligam os blocos do mapa (eles não têm internet).
  static bool tilesEnabled = true;

  /// Tira ~65% da saturação e clareia um pouco o mapa (estilo "light"),
  /// para os pinos dos restaurantes se destacarem.
  static const softFilter = ColorFilter.matrix(<double>[
    0.4882, 0.4649, 0.0469, 0, 12, //
    0.1382, 0.8149, 0.0469, 0, 12, //
    0.1382, 0.4649, 0.3969, 0, 12, //
    0, 0, 0, 1, 0, //
  ]);
}
