import 'package:flutter/material.dart';

import '../data/models/delivery_platform.dart';
import '../ui/theme.dart';

/// Etiqueta com o nome e a cor do app (iFood, 99Food, Keeta).
class PlatformBadge extends StatelessWidget {
  final DeliveryPlatform platform;
  final bool small;

  const PlatformBadge({super.key, required this.platform, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: platform.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        platform.name,
        style: AppText.label.copyWith(
          color: platform.onColor,
          fontSize: small ? 10.5 : 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Bolinha colorida do app (usada em listas compactas).
class PlatformDot extends StatelessWidget {
  final DeliveryPlatform platform;
  final double size;

  const PlatformDot({super.key, required this.platform, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: platform.name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: platform.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.bgBlack.withValues(alpha: 0.12), blurRadius: 2)],
        ),
      ),
    );
  }
}
