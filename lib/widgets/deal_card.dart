import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/models/dish.dart';
import '../data/models/price_quote.dart';
import '../data/models/restaurant.dart';
import '../ui/theme.dart';
import 'food_image.dart';
import 'platform_badge.dart';
import 'savings_badge.dart';

/// Card da vitrine "Economia do dia" na Home.
class DealCard extends StatelessWidget {
  final Restaurant restaurant;
  final Dish dish;
  final Comparison comparison;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.restaurant,
    required this.dish,
    required this.comparison,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final best = comparison.best!;
    final worst = comparison.worst!;
    return SizedBox(
      width: 196,
      child: Material(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.strokeLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    FoodImage(
                      url: dish.imageUrl ?? restaurant.imageUrl,
                      categoryId: restaurant.category,
                      height: 116,
                      width: double.infinity,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: SavingsBadge(ratio: comparison.savingsRatio, solid: true),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dish.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h6),
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 6,
                        children: [
                          Text(Fmt.brl(best.total), style: AppText.price(size: 17, color: AppColors.teal)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              Fmt.brl(worst.total),
                              style: AppText.price(size: 11.5, weight: FontWeight.w500, color: AppColors.textGrey)
                                  .copyWith(decoration: TextDecoration.lineThrough),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('no ', style: AppText.caption.copyWith(fontSize: 11)),
                          PlatformBadge(platform: best.platform, small: true),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'vs ${worst.platform.name}',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.textGrey),
                            ),
                          ),
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
