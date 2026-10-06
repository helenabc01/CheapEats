import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../core/app_services.dart';
import '../core/routes/app_routes.dart';
import '../ui/theme.dart';
import 'restaurant_logo.dart';
import 'soft_tile_layer.dart';

/// Prévia do mapa de restaurantes (Início e Busca).
/// É só uma "janela" do mapa: tocar em qualquer lugar abre o mapa completo.
class MapPreviewCard extends StatelessWidget {
  /// Versão menor, usada na Busca.
  final bool compact;

  const MapPreviewCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final address = AppServices.address.current;
    final user = LatLng(address.latitude, address.longitude);
    final openCount = catalog.restaurants.where((r) => r.isOpen).length;
    final height = compact ? 144.0 : 184.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // O mapa em si não recebe toques: a página continua rolando normalmente.
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: user,
                  initialZoom: compact ? 13.0 : 13.5,
                  backgroundColor: const Color(0xFFEDEAE6),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  const SoftTileLayer(),
                  MarkerLayer(
                    markers: [
                      for (final r in catalog.restaurants)
                        Marker(
                          point: LatLng(r.latitude, r.longitude),
                          width: compact ? 22 : 28,
                          height: compact ? 22 : 28,
                          child: Opacity(
                            opacity: r.isOpen ? 1 : 0.6,
                            child: RestaurantLogo(restaurant: r, size: compact ? 22 : 28),
                          ),
                        ),
                      Marker(point: user, width: 30, height: 30, child: const UserLocationDot(size: 14)),
                    ],
                  ),
                ],
              ),
            ),
            if (!compact)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NOVO',
                    style: AppText.label.copyWith(color: Colors.white, fontSize: 10.5, letterSpacing: 0.8),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _InfoPanel(compact: compact, openCount: openCount),
            ),
            // Toque em qualquer lugar do card abre o mapa completo.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.map),
                  child: Semantics(button: true, label: 'Abrir mapa de restaurantes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final bool compact;
  final int openCount;

  const _InfoPanel({required this.compact, required this.openCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 38,
            height: compact ? 30 : 38,
            decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
            child: Icon(Icons.map_rounded, color: AppColors.orange, size: compact ? 17 : 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  compact ? 'Explorar no mapa' : 'Mapa de restaurantes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h6.copyWith(fontSize: compact ? 13 : 14),
                ),
                if (!compact)
                  Text(
                    '$openCount abertos perto de você · veja onde sai mais barato',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            const Icon(Icons.chevron_right_rounded, color: AppColors.orange)
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Abrir', style: AppText.label.copyWith(color: Colors.white)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
