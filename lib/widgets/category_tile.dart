import 'package:flutter/material.dart';

import '../data/models/food_category.dart';
import '../ui/theme.dart';

/// Foto da categoria com fallback para o ícone (sem internet).
class _CategoryPhoto extends StatelessWidget {
  final FoodCategory category;
  final double iconSize;

  const _CategoryPhoto({required this.category, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: category.tint,
      child: Center(
        child: Icon(category.icon, size: iconSize, color: AppColors.bgBlack.withValues(alpha: 0.7)),
      ),
    );
    return Image.network(
      category.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Stack(fit: StackFit.expand, children: [fallback, child]),
    );
  }
}

/// Atalho de categoria da Home: foto redonda + nome (estilo iFood).
class CategoryTile extends StatelessWidget {
  final FoodCategory category;
  final VoidCallback onTap;

  const CategoryTile({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Categoria ${category.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgWhite, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bgBlack.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(child: _CategoryPhoto(category: category, iconSize: 28)),
              ),
              const SizedBox(height: 7),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de categoria da Busca: foto de fundo com o nome por cima.
class CategoryCard extends StatelessWidget {
  final FoodCategory category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CategoryPhoto(category: category, iconSize: 32),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h6.copyWith(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
