import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/utils/formatters.dart';
import '../data/models/dish.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import 'food_image.dart';

/// Linha de prato do cardápio com a mini-comparação de preço nos apps.
class DishTile extends StatelessWidget {
  final Restaurant restaurant;
  final Dish dish;
  final VoidCallback? onTap;

  /// Mostra o nome do restaurante (usado na Busca).
  final bool showRestaurant;

  const DishTile({
    super.key,
    required this.restaurant,
    required this.dish,
    this.onTap,
    this.showRestaurant = false,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final comparison = AppServices.calculator.compareDish(restaurant, dish);
    final best = comparison.best;
    final lowest = dish.lowestPrice;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dish.isPopular)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'MAIS PEDIDO',
                        style: AppText.label.copyWith(
                          fontSize: 10,
                          color: AppColors.orange,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(dish.name, style: AppText.h6.copyWith(fontSize: 15)),
                  if (showRestaurant) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.name,
                      style: AppText.caption.copyWith(color: AppColors.textGrey),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 10),
                  // Preço do item em cada app; o mais barato em verde-água.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final platform in catalog.platforms)
                        if (restaurant.isOn(platform.id))
                          _PriceChip(
                            name: platform.name,
                            price: dish.priceOn(platform.id),
                            highlight: lowest != null &&
                                dish.priceOn(platform.id)?.available == true &&
                                dish.priceOn(platform.id)!.price == lowest,
                          ),
                    ],
                  ),
                  if (best != null && comparison.hasComparison && best.meetsMinOrder) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              text: comparison.isTie ? 'Empate: ' : 'Melhor total: ',
                              style: AppText.caption.copyWith(fontSize: 11.5),
                              children: [
                                TextSpan(
                                  text: '${Fmt.brl(best.total)} no ${best.platform.name}',
                                  style: AppText.label.copyWith(color: AppColors.teal, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (best != null && !best.meetsMinOrder) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.shopping_basket_outlined, size: 15, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pedido mínimo ${Fmt.brl(best.minOrder)} · compare com mais unidades',
                            style: AppText.caption.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            FoodImage(url: dish.imageUrl, categoryId: restaurant.category, width: 92, height: 92),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String name;
  final DishPrice? price;
  final bool highlight;

  const _PriceChip({required this.name, required this.price, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final unavailable = price == null || !price!.available;
    final label = price == null ? '—' : (!price!.available ? 'esgotado' : Fmt.brl(price!.price));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.tealSoft : AppColors.bgGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? AppColors.teal.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Text.rich(
        TextSpan(
          text: '$name ',
          style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textDarkGrey),
          children: [
            TextSpan(
              text: label,
              style: AppText.price(
                size: 11.5,
                weight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: unavailable
                    ? AppColors.textGrey
                    : (highlight ? AppColors.teal : AppColors.textBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
