import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/utils/formatters.dart';
import '../data/models/food_category.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import 'food_image.dart';
import 'platform_badge.dart';
import 'savings_badge.dart';

/// Card de restaurante (Home, Busca e Favoritos).
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final catalog = AppServices.catalog;
    final calculator = AppServices.calculator;
    final category = FoodCategory.byId(restaurant.category);
    final (minTime, maxTime) = restaurant.deliveryRange;
    final bestPlatform = calculator.bestPlatformFor(restaurant);
    final maxSavings = calculator.maxSavingsRatio(restaurant);
    final onlyOne = restaurant.platforms.length == 1;
    final cheapestDelivery = restaurant.cheapestDelivery;
    final deliveryText = cheapestDelivery == null
        ? ''
        : cheapestDelivery.deliveryFee == 0
            ? 'frete grátis no ${catalog.platform(cheapestDelivery.platformId).name}'
            : 'frete desde ${Fmt.brl(cheapestDelivery.deliveryFee)}';

    return Opacity(
      opacity: restaurant.isOpen ? 1 : 0.55,
      child: Material(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.strokeLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FoodImage(
                  url: restaurant.imageUrl,
                  categoryId: restaurant.category,
                  width: 84,
                  height: 84,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h6.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(
                            Fmt.rating(restaurant.rating),
                            style: AppText.label.copyWith(color: const Color(0xFFB37A00)),
                          ),
                          Flexible(
                            child: Text(
                              '  ·  ${category.label}  ·  ${Fmt.distance(restaurant.distanceKm)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.isOpen
                            ? '${Fmt.deliveryTime(minTime, maxTime)}  ·  $deliveryText'
                            : 'Fechado  ·  abre às ${restaurant.opensAt ?? '--:--'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: restaurant.isOpen ? AppColors.textDarkGrey : AppColors.error,
                          fontWeight: restaurant.isOpen ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final info in restaurant.platforms) ...[
                            PlatformDot(platform: catalog.platform(info.platformId), size: 12),
                            const SizedBox(width: 2),
                          ],
                          const SizedBox(width: 6),
                          Expanded(
                            child: onlyOne
                                ? Text(
                                    'Só no ${catalog.platform(restaurant.platforms.first.platformId).name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.caption.copyWith(fontSize: 11),
                                  )
                                : bestPlatform == null
                                    ? const SizedBox.shrink()
                                    : Text.rich(
                                        TextSpan(
                                          text: 'Melhor: ',
                                          style: AppText.caption.copyWith(fontSize: 11),
                                          children: [
                                            TextSpan(
                                              text: bestPlatform.name,
                                              style: AppText.label.copyWith(
                                                fontSize: 11,
                                                color: AppColors.teal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                          ),
                          if (maxSavings >= 0.05) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Economia máxima neste restaurante',
                              child: SavingsBadge(ratio: maxSavings),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
