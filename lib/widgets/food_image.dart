import 'package:flutter/material.dart';

import '../data/models/food_category.dart';
import '../ui/theme.dart';

/// Foto de prato/restaurante vinda da internet, com fallback elegante
/// (gradiente + ícone da categoria) se não houver URL ou se estiver offline.
class FoodImage extends StatelessWidget {
  final String? url;
  final String categoryId;
  final double? width;
  final double? height;
  final double radius;
  final BorderRadius? borderRadius;

  const FoodImage({
    super.key,
    required this.url,
    required this.categoryId,
    this.width,
    this.height,
    this.radius = AppTheme.radiusSmall,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final category = FoodCategory.byId(categoryId);
    final fallback = _Fallback(category: category);
    final shape = borderRadius ?? BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: shape,
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? fallback
            : Image.network(
                url!,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (_, _, _) => fallback,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Stack(fit: StackFit.expand, children: [fallback, child]),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final FoodCategory category;

  const _Fallback({required this.category});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final iconSize = side.isFinite ? (side * 0.42).clamp(18.0, 56.0) : 32.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [category.tint, Color.lerp(category.tint, AppColors.peach, 0.55)!],
            ),
          ),
          child: Center(
            child: Icon(category.icon, size: iconSize, color: AppColors.bgBlack.withValues(alpha: 0.55)),
          ),
        );
      },
    );
  }
}
