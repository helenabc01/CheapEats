import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/config/map_config.dart';

/// Camada de fundo dos mapas do app (OpenStreetMap com filtro suave).
class SoftTileLayer extends StatelessWidget {
  const SoftTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    if (!MapConfig.tilesEnabled) return const SizedBox.shrink();
    return TileLayer(
      urlTemplate: MapConfig.tileUrl,
      userAgentPackageName: MapConfig.userAgentPackageName,
      maxNativeZoom: 19,
      tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: MapConfig.softFilter, child: tile),
    );
  }
}

/// "Você está aqui": ponto azul com halo.
class UserLocationDot extends StatelessWidget {
  final double size;

  const UserLocationDot({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Seu endereço',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E88E5).withValues(alpha: 0.18),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E88E5),
            border: Border.all(color: Colors.white, width: size * 0.19),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
