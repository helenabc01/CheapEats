import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../ui/theme.dart';

/// Selo verde-água de economia: "Economize R$ 6,50" ou "−18%".
class SavingsBadge extends StatelessWidget {
  final double? amount;
  final double? ratio;
  final bool solid;

  const SavingsBadge({super.key, this.amount, this.ratio, this.solid = false})
      : assert(amount != null || ratio != null);

  @override
  Widget build(BuildContext context) {
    final text = amount != null ? 'Economize ${Fmt.brl(amount!)}' : '−${Fmt.percent(ratio!)}';
    final foreground = solid ? Colors.white : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? AppColors.teal : AppColors.tealSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(text, style: AppText.label.copyWith(color: foreground, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Selo rosa para promoções/cupons.
class PromoTag extends StatelessWidget {
  final String text;
  final IconData icon;

  const PromoTag(this.text, {super.key, this.icon = Icons.local_offer_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.tertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(color: AppColors.tertiary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
