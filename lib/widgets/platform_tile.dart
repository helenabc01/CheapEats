import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/models/price_quote.dart';
import '../ui/theme.dart';
import 'platform_badge.dart';

/// Card de um app na tela de comparação, com o detalhamento do total.
class PlatformTile extends StatelessWidget {
  final PriceQuote quote;
  final bool isBest;
  final bool isTie;
  final int quantity;
  final VoidCallback? onOrder;

  const PlatformTile({
    super.key,
    required this.quote,
    required this.isBest,
    this.isTie = false,
    this.quantity = 1,
    this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (!quote.isAvailable) return _UnavailableTile(quote: quote);

    final borderColor = isBest ? AppColors.teal : AppColors.strokeLight;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: borderColor, width: isBest ? 1.8 : 1),
        boxShadow: isBest ? AppTheme.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius - 2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    isTie ? 'EMPATE NO MELHOR PREÇO' : 'MELHOR PREÇO',
                    style: AppText.label.copyWith(color: Colors.white, letterSpacing: 0.8, fontSize: 11),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    PlatformBadge(platform: quote.platform),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textGrey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        Fmt.deliveryTime(quote.deliveryTimeMin, quote.deliveryTimeMax),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ),
                    Text(
                      Fmt.brl(quote.total),
                      style: AppText.price(size: 22, color: isBest ? AppColors.teal : AppColors.textBlack),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Line(
                  label: quantity > 1 ? 'Itens ($quantity×)' : 'Item',
                  value: Fmt.brl(quote.subtotal),
                  strike: quote.hasPromo ? Fmt.brl(quote.originalSubtotal) : null,
                ),
                _Line(
                  label: 'Entrega',
                  value: Fmt.fee(quote.deliveryFee),
                  valueColor: quote.deliveryFee == 0 ? AppColors.teal : null,
                ),
                if (quote.serviceFee > 0) _Line(label: 'Taxa de serviço', value: Fmt.brl(quote.serviceFee)),
                if (quote.coupon != null)
                  _Line(
                    label: 'Cupom ${quote.coupon!.code}',
                    value: '− ${Fmt.brl(quote.discount)}',
                    valueColor: AppColors.teal,
                    icon: Icons.local_offer_rounded,
                  ),
                if (!quote.meetsMinOrder)
                  _Notice(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.error,
                    text: 'Pedido mínimo de ${Fmt.brl(quote.minOrder)} neste app — '
                        'faltam ${Fmt.brl(quote.missingForMinOrder)}.',
                  ),
                if (quote.nearMissCoupon != null)
                  _Notice(
                    icon: Icons.lightbulb_outline_rounded,
                    color: AppColors.tertiary,
                    text: 'Faltam ${Fmt.brl(quote.missingForCoupon)} para usar o cupom '
                        '${quote.nearMissCoupon!.code} (${quote.nearMissCoupon!.title}).',
                  ),
                if (onOrder != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onOrder,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text('Pedir no ${quote.platform.name}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final String? strike;
  final Color? valueColor;
  final IconData? icon;

  const _Line({required this.label, required this.value, this.strike, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: valueColor ?? AppColors.textDarkGrey),
            const SizedBox(width: 4),
          ],
          Expanded(child: Text(label, style: AppText.caption.copyWith(fontSize: 13))),
          if (strike != null) ...[
            Text(
              strike!,
              style: AppText.price(size: 12, weight: FontWeight.w500, color: AppColors.textGrey)
                  .copyWith(decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: AppText.price(size: 13.5, weight: FontWeight.w600, color: valueColor ?? AppColors.textBlack),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.caption.copyWith(color: AppColors.textBlack, fontSize: 12))),
        ],
      ),
    );
  }
}

class _UnavailableTile extends StatelessWidget {
  final PriceQuote quote;

  const _UnavailableTile({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgLightGray,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.strokeLight),
      ),
      child: Row(
        children: [
          Opacity(opacity: 0.5, child: PlatformBadge(platform: quote.platform)),
          const SizedBox(width: 10),
          const Icon(Icons.block_rounded, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              quote.unavailableReason!.label,
              style: AppText.caption.copyWith(color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}
